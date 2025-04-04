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
    with open(r"queries/rm_tmpTM_PO.sql") as file:
        remove_am = file.read()
    with open(r"queries/rm_tmpCS_PO.sql") as file:
        remove_fce = file.read()
    with open(r"queries/rm_tmpASD_PO.sql") as file:
        remove_rm = file.read()
    with open(r"queries/rm_tmpATM_PO.sql") as file:
        remove_atm = file.read()
    print("Deleting tmpTM_PO...")
    conn.execute(text(remove_am))
    print("Deleting tmpATM_PO...")
    conn.execute(text(remove_atm))
    print("Deleting tmpCS_PO...")
    conn.execute(text(remove_fce))
    print("Deleting tmpASD_PO...")
    conn.execute(text(remove_rm))
    conn.commit()


def create_tmp_tables():
    with open(r"C:\Users\asorensen\OneDrive - CVRx Inc\SQL\Comp Summaries\TM Summary.sql") as file:
        create_tm = file.read()
        create_tm = create_tm.replace("-- INTO tmpTM_PO", "INTO tmpTM_PO")
    with open(r"C:\Users\asorensen\OneDrive - CVRx Inc\SQL\Comp Summaries\CS Summary.sql") as file:
        create_cs = file.read()
        create_cs = create_cs.replace("-- INTO tmpCS_PO", "INTO tmpCS_PO")
    with open(r"C:\Users\asorensen\OneDrive - CVRx Inc\SQL\Comp Summaries\AD Summary.sql") as file:
        create_asd = file.read()
        create_asd = create_asd.replace("-- INTO tmpASD_PO", "INTO tmpASD_PO")
    with open(r"C:\Users\asorensen\OneDrive - CVRx Inc\SQL\Comp Summaries\ATM Summary.sql") as file:
        create_atm = file.read()
        create_atm = create_atm.replace("--INTO tmpATM_PO", "INTO tmpATM_PO")
    print("Creating tmpTM_PO...")
    conn.execute(text(create_tm))
    print("Creating tmpATM_PO...")
    conn.execute(text(create_atm))
    print("Creating tmpCS_PO...")
    conn.execute(text(create_cs))
    print("Creating tmpASD_PO...")
    conn.execute(text(create_asd))
    print("Pushing new tables to database...")
    conn.commit()


def push_to_tblpayout(**kwargs: list):
    """Use kwargs 'emails=' to push data only for specific people. Must be entered as a list. There is an integrity
    check in place to delete data from the table for the same month and email before pushing the new data,
    so there will not be duplicate entries. Note that leaving the kwargs blank will push data for everyone."""
    emails = kwargs.get('emails', None)
    with open(r"queries/integrity_check.sql") as file:
        integrity_check = file.read()
    with open(r"queries/push_TM.sql") as file:
        push_tm = file.read()
    with open(r"queries/push_ATM.sql") as file:
        push_atm = file.read()
    with open(r"queries/push_CS.sql") as file:
        push_cs = file.read()
    with open(r"queries/push_ASD.sql") as file:
        push_asd = file.read()
    with open("queries/add_YTD_PO.sql") as file:
        push_ytd = file.read()
        for old, new in add_YTD_PO_replacements.items():
            push_ytd = push_ytd.replace(old, new)
    with open("queries/add_YTD_regional_PO.sql") as file:
        push_regional_ytd = file.read()
        for old, new in add_YTD_PO_replacements.items():
            push_regional_ytd = push_regional_ytd.replace(old, new)

    if emails is None:
        print(f"Deleting from tblPayout all records where YYYYMM = {last_month} (so there will not be duplicates).")
        answer = input("Proceed? Y/N\n")
        if answer.lower() == 'y':
            conn.execute(text(integrity_check))
            conn.commit()
            print(f"Pushing data for all roles to tblPayout...")
            conn.execute(text(push_tm))
            conn.execute(text(push_atm))
            conn.execute(text(push_cs))
            conn.execute(text(push_asd))
            conn.commit()
            fix_value_errors()
            conn.execute(text(push_ytd.replace("@role", "'CS'")))
            conn.execute(text(push_ytd.replace("@role", "'TM'")))
            conn.execute(text(push_ytd.replace("@role", "'ATM'")))
            conn.execute(text(push_ytd.replace("@role", "'ASD'")))
            conn.execute(text(push_regional_ytd.replace("@role", "'CS'")))
            conn.commit()
            fix_value_errors()
        else:
            print("Code halted. No data has been pushed.")
    else:
        revised_integrity_check = integrity_check + " AND [EID] IN" + f" {py_list_to_sql_list(emails)}"
        push_specific_cs = push_cs + " WHERE [SALES_CREDIT_CS_EMAIL] IN" + F" {py_list_to_sql_list(emails)}"
        push_specific_tm = push_tm + " WHERE [EID] IN" + f" {py_list_to_sql_list(emails)}"
        push_specific_atm = push_atm.replace("FROM ##ATM", F"FROM ##ATM WHERE EID IN"
                                                           F" {py_list_to_sql_list(emails)}")
        push_specific_asd = push_asd + " WHERE [SALES_CREDIT_ASD_EMAIL] IN" + f" {py_list_to_sql_list(emails)}"
        push_specific_ytd_po = push_ytd + " AND [EID] IN" + f" {py_list_to_sql_list(emails)}"
        push_specific_regional_ytd = push_regional_ytd + " AND [EID] IN" + f" {py_list_to_sql_list(emails)}"

        print(f"Deleting {emails} from tblPayout where YYYYMM = {last_month} "
              f"(so there will not be duplicates).")

        conn.execute(text(revised_integrity_check))
        conn.commit()

        print(f"Pushing data to tblPayout for {emails}")
        conn.execute(text(push_specific_cs))
        conn.execute(text(push_specific_tm))
        conn.execute(text(push_specific_asd))
        conn.execute(text(push_specific_atm))
        conn.commit()
        fix_value_errors()
        conn.execute(text(push_specific_ytd_po.replace("@role", "'CS'")))
        conn.execute(text(push_specific_ytd_po.replace("@role", "'TM'")))
        conn.execute(text(push_specific_ytd_po.replace("@role", "'ASD'")))
        conn.execute(text(push_specific_ytd_po.replace("@role", "'ATM'")))
        conn.execute(text(push_specific_regional_ytd.replace("@role", "'CS'")))
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
push_to_tblpayout(emails=['tkirk@cvrx.com'])


conn.close()
