import pandas as pd
import openpyxl
from database import engine
from sqlalchemy import text
from datetime import datetime
from dateutil.relativedelta import relativedelta
import logging

conn = engine.connect()
last_month_full_date = datetime.now() - relativedelta(months=1)
last_month = last_month_full_date.strftime("%Y_%m")
last_month_quarter = f"{last_month_full_date.year}_Q{((last_month_full_date.month - 1) // 3) + 1}"
last_month_year = f"{last_month_full_date.year}"

add_YTD_PO_replacements = {
    "@yyyymm": f"'{last_month}'",
    "@quarter": f"'{last_month_quarter}'",
    "@year": f"'{last_month_year}'"
}


def py_list_to_sql_list(lst):
    return f"({', '.join(f'\'{item}\'' for item in lst)})"


def remove_tmp_tables():
    files = [
        ("queries/rm_tmpTM_PO.sql", "tmpTM_PO"),
        ("queries/rm_tmpATM_PO.sql", "tmpATM_PO"),
        ("queries/rm_tmpCS_PO.sql", "tmpCS_PO"),
        ("queries/rm_tmpASD_PO.sql", "tmpASD_PO")
    ]

    for path, label in files:
        with open(path) as file:
            sql = file.read()
        print(f"Deleting {label}...")
        conn.execute(text(sql))

    conn.commit()


def create_tmp_tables():
    files = [
        (r"C:\Users\asorensen\OneDrive - CVRx Inc\SQL\Comp Summaries\TM Summary.sql", "tmpTM_PO"),
        (r"C:\Users\asorensen\OneDrive - CVRx Inc\SQL\Comp Summaries\ATM Summary.sql", "tmpATM_PO"),
        (r"C:\Users\asorensen\OneDrive - CVRx Inc\SQL\Comp Summaries\CS Summary.sql", "tmpCS_PO"),
        (r"C:\Users\asorensen\OneDrive - CVRx Inc\SQL\Comp Summaries\AD Summary.sql", "tmpASD_PO")
    ]

    for path, label in files:
        with open(path) as file:
            sql = file.read().replace("-- INTO", f"INTO")
        print(f"Creating {label}...")
        conn.execute(text(sql))

    print("Pushing new tables to database...")
    conn.commit()


def push_to_tblpayout(**kwargs: list):
    """Push payout data to tblPayout with optional email filter."""
    emails = kwargs.get('emails', None)

    # Load and prepare SQL queries
    def load_sql(path, replacements=None):
        with open(path) as f:
            sql = f.read()
            if replacements:
                for old, new in replacements.items():
                    sql = sql.replace(old, new)
            return sql

    queries = {
        'integrity_check': load_sql("queries/integrity_check.sql"),
        'push_tm': load_sql("queries/push_TM.sql"),
        'push_atm': load_sql("queries/push_ATM.sql"),
        'push_cs': load_sql("queries/push_CS.sql"),
        'push_asd': load_sql("queries/push_ASD.sql"),
        'push_ytd': load_sql("queries/add_YTD_PO.sql", add_YTD_PO_replacements),
        'push_regional_ytd': load_sql("queries/add_YTD_regional_PO.sql", add_YTD_PO_replacements),
    }

    roles = ['CS', 'TM', 'ATM', 'ASD']

    def push_ytd(sql_template, emails_filter=None):
        for role in roles:
            sql = sql_template.replace("@role", f"'{role}'")
            if emails_filter:
                sql += f" AND [EID] IN {emails_filter}"
            conn.execute(text(sql))

    if emails is None:
        print(f"Deleting from tblPayout all records where YYYYMM = {last_month}.")
        if input("Proceed? Y/N\n").lower() == 'y':
            conn.execute(text(queries['integrity_check']))
            conn.commit()

            print("Pushing data for all roles to tblPayout...")
            for key in ['push_tm', 'push_atm', 'push_cs', 'push_asd']:
                conn.execute(text(queries[key]))
            conn.commit()
            fix_value_errors()

            push_ytd(queries['push_ytd'])
            conn.execute(text(queries['push_regional_ytd'].replace("@role", "'CS'")))
            conn.commit()
            fix_value_errors()
        else:
            print("Code halted. No data has been pushed.")
    else:
        email_list = py_list_to_sql_list(emails)
        print(f"Deleting {emails} from tblPayout where YYYYMM = {last_month}.")

        revised_integrity = queries['integrity_check'] + f" AND [EID] IN {email_list}"
        conn.execute(text(revised_integrity))
        conn.commit()

        print(f"Pushing data to tblPayout for {emails}...")

        filtered_queries = {
            'push_tm': queries['push_tm'] + f" WHERE [EID] IN {email_list}",
            'push_cs': queries['push_cs'] + f" WHERE [SALES_CREDIT_CS_EMAIL] IN {email_list}",
            'push_asd': queries['push_asd'] + f" WHERE [SALES_CREDIT_ASD_EMAIL] IN {email_list}",
            'push_atm': queries['push_atm'].replace("FROM ##ATM", f"FROM ##ATM WHERE EID IN {email_list}")
        }

        for q in filtered_queries.values():
            conn.execute(text(q))
        conn.commit()
        fix_value_errors()

        push_ytd(queries['push_ytd'], email_list)
        regional_ytd = queries['push_regional_ytd'].replace("@role", "'CS'") + f" AND [EID] IN {email_list}"
        conn.execute(text(regional_ytd))
        conn.commit()
        fix_value_errors()


def fix_value_errors():
    """Some values default to scientific notation, causing problems when trying to cast the values from varchar to
    float. This function fixes all those values."""
    try:
        query = """SELECT
                    YYYYMM,
                    EID,
                    YYYYQQ,
                    ROLE,
                    [STATUS],
                    [VALUE],
                    CATEGORY,
                    Notes
                FROM
                    tblPayout
                WHERE
                    TRY_CAST(value AS decimal(15, 2)) IS NULL
                    AND value IS NOT NULL
                    AND LEFT(YYYYMM, 4) >= 2025"""
        query_df = pd.read_sql_query(query, conn)
        query_df[["v", "multiplier"]] = query_df["VALUE"].str.split('e+', expand=True, regex=False).astype(float)
        query_df["multiplier"] = 10 ** query_df["multiplier"]
        query_df["NEW_VALUE"] = (query_df["v"] * query_df["multiplier"]).astype(str)

        logging.exception("fix_value_errors() exception logged")
        for index, row in query_df.iterrows():
            try:
                sql = text("""UPDATE tblPayout
                        SET [VALUE] = :new_value
                        WHERE YYYYMM = :yyyymm
                        AND EID = :eid
                        AND [ROLE] = :role
                        AND [CATEGORY] = :category""")
                conn.execute(sql, {
                    'new_value': row["NEW_VALUE"],
                    'yyyymm': row["YYYYMM"],
                    'eid': row["EID"],
                    'role': row["ROLE"],
                    'category': row["CATEGORY"]
                })
                conn.commit()
            except ValueError:
                pass
    except ValueError:
        pass



remove_tmp_tables()
create_tmp_tables()
push_to_tblpayout(emails=[])


conn.close()
