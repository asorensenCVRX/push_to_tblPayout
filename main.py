from database import engine
from sqlalchemy import text
from datetime import datetime
from dateutil.relativedelta import relativedelta

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


def remove_tmp_tables():
    with open(r"queries/rm_tmpAM_PO.sql") as file:
        remove_am = file.read()
    with open(r"queries/rm_tmpFCE_PO.sql") as file:
        remove_fce = file.read()
    with open(r"queries/rm_tmpRM_PO.sql") as file:
        remove_rm = file.read()
    print("Deleting tmpAM_PO...")
    conn.execute(text(remove_am))
    print("Deleting tmpFCE_PO...")
    conn.execute(text(remove_fce))
    print("Deleting tmpRM_PO...")
    conn.execute(text(remove_rm))
    conn.commit()


def create_tmp_tables():
    with open(r"queries/create_tmpAM_PO.sql") as file:
        create_am = file.read()
    with open(r"queries/create_tmpFCE_PO.sql") as file:
        create_fce = file.read()
    with open(r"queries/create_tmpRM_PO.sql") as file:
        create_rm = file.read()
    print("Creating tmpAM_PO...")
    conn.execute(text(create_am))
    print("Creating tmpFCE_PO...")
    conn.execute(text(create_fce))
    print("Creating tmpRM_PO...")
    conn.execute(text(create_rm))
    print("Pushing new tables to database...")
    conn.commit()


def push_to_tblpayout(**kwargs: list):
    """Use kwargs 'emails=' to push data only for specific people. Must be entered as a list. There is an integrity
    check in place to delete data from the table for the same month and email before pushing the new data,
    so there will not be duplicate entries. Note that leaving the kwargs blank will push data for everyone."""
    emails = kwargs.get('emails', None)
    with open(r"queries/integrity_check.sql") as file:
        integrity_check = file.read()
    with open(r"queries/push_AM.sql") as file:
        push_am = file.read()
    with open(r"queries/push_FCE.sql") as file:
        push_fce = file.read()
    with open(r"queries/push_RM.sql") as file:
        push_rm = file.read()
    with open("queries/add_YTD_PO.sql") as file:
        push_ytd = file.read()
        for old, new in add_YTD_PO_replacements.items():
            push_ytd = push_ytd.replace(old, new)

    if emails is None:
        print(f"Deleting from tblPayout all records where YYYYMM = {last_month} (so there will not be duplicates).")
        answer = input("Proceed? Y/N\n")
        if answer.lower() == 'y':
            conn.execute(text(integrity_check))
            conn.commit()
            print(f"Pushing data for all roles to tblPayout...")
            conn.execute(text(push_am))
            conn.execute(text(push_fce))
            conn.execute(text(push_rm))
            conn.execute(text(push_ytd.replace("@role", "'FCE'")))
            conn.execute(text(push_ytd.replace("@role", "'REP'")))
            conn.execute(text(push_ytd.replace("@role", "'RM'")))
            conn.commit()
        else:
            print("Code halted. No data has been pushed.")
    else:
        revised_integrity_check = (integrity_check + " AND [EID] IN" + f" {emails}".replace('[', '(')
                                   .replace(']', ')'))
        push_specific_fce = (push_fce + " WHERE [FCE_EMAIL] IN" + F" {emails}".replace('[', '(')
                             .replace(']', ')'))
        push_specific_am = (push_am + " WHERE [REP_EMAIL] IN" + f" {emails}".replace('[', '(')
                            .replace(']', ')'))
        push_specific_rm = (push_rm + " WHERE [SALES_CREDIT_RM_EMAIL] IN" + f" {emails}"
                            .replace('[', '(').replace(']', ')'))
        push_specific_ytd_po = (push_ytd + " AND [EID] IN" + f" {emails}".replace('[', '(')
                                .replace(']', ')'))
        print(f"Deleting {emails} from tblPayout where YYYYMM = {last_month} "
              f"(so there will not be duplicates).")
        conn.execute(text(revised_integrity_check))
        conn.commit()
        print(f"Pushing data to tblPayout for {emails}")
        conn.execute(text(push_specific_fce))
        conn.execute(text(push_specific_am))
        conn.execute(text(push_specific_rm))
        conn.execute(text(push_specific_ytd_po.replace("@role", "'FCE'")))
        conn.execute(text(push_specific_ytd_po.replace("@role", "'REP'")))
        conn.execute(text(push_specific_ytd_po.replace("@role", "'RM'")))
        conn.commit()


remove_tmp_tables()
create_tmp_tables()
push_to_tblpayout(emails=['dharper@cvrx.com', 'jviduna@cvrx.com', 'kwolf@cvrx.com'])

conn.close()