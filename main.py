from database import engine
from sqlalchemy import text
from datetime import datetime
from dateutil.relativedelta import relativedelta

conn = engine.connect()
last_month_full_date = datetime.now() - relativedelta(months=1)
last_month = last_month_full_date.strftime("%Y-%m")


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


def push_to_tblpayout(**kwargs):
    """Use kwargs 'csr_emails=', 'am_emails=', or 'rm_emails=' to push data only for specific people. Must be entered
    as a list. There is an integrity check in place to delete data from the table for the same month and email before
    pushing the new data, so there will not be duplicate entries. Note that leaving the kwargs blank will push data for
    everyone."""
    csr_emails = kwargs.get('csr_emails', None)
    am_emails = kwargs.get('am_emails', None)
    rm_emails = kwargs.get('rm_emails', None)
    with open(r"queries/integrity_check.sql") as file:
        integrity_check = file.read()
    with open(r"queries/push_AM.sql") as file:
        push_am = file.read()
    with open(r"queries/push_FCE.sql") as file:
        push_fce = file.read()
    with open(r"queries/push_RM.sql") as file:
        push_rm = file.read()
    if csr_emails is None and am_emails is None and rm_emails is None:
        print(f"Deleting from tblPayout all records where YYYYMM = {last_month} (so there will not be duplicates).")
        conn.execute(text(integrity_check))
        conn.commit()
        print(f"Pushing data for all roles to tblPayout...")
        conn.execute(text(push_am))
        conn.execute(text(push_fce))
        conn.execute(text(push_rm))
        conn.commit()
        print("testing")
    else:
        if csr_emails is not None:
            csr_integrity_check = (integrity_check + " AND [EID] IN" + f" {csr_emails}".replace('[', '(')
                                   .replace(']', ')'))
            push_specific_fce = (push_fce + " WHERE [FCE_EMAIL] IN" + F" {csr_emails}".replace('[', '(')
                                 .replace(']', ')'))
            print(f"Deleting {csr_emails} from tblPayout where YYYYMM = {last_month} "
                  f"(so there will not be duplicates).")
            conn.execute(text(csr_integrity_check))
            conn.commit()
            print(f"Pushing data to tblPayout for {csr_emails}")
            conn.execute(text(push_specific_fce))
            conn.commit()
        if am_emails is not None:
            am_integrity_check = (integrity_check + " AND [EID] IN" + f" {am_emails}".replace('[', '(')
                                  .replace(']', ')'))
            push_specific_am = (push_am + " WHERE [REP_EMAIL] IN" + f" {am_emails}".replace('[', '(')
                                .replace(']', ')'))
            print(f"Deleting {am_emails} from tblPayout where YYYYMM = {last_month} "
                  f"(so there will not be duplicates).")
            conn.execute(text(am_integrity_check))
            conn.commit()
            print(f"Pushing data to tblPayout for {am_emails}")
            conn.execute(text(push_specific_am))
            conn.commit()
        if rm_emails is not None:
            rm_integrity_check = (integrity_check + " AND [EID] IN" + f" {rm_emails}"
                                  .replace('[', '(').replace(']', ')'))
            push_specific_rm = (push_rm + " WHERE [SALES_CREDIT_RM_EMAIL] IN" + f" {rm_emails}"
                                .replace('[', '(').replace(']', ')'))
            print(f"Deleting {rm_emails} from tblPayout where YYYYMM = {last_month} "
                  f"(so there will not be duplicates).")
            conn.execute(text(rm_integrity_check))
            conn.commit()
            print(f"Pushing data to tblPayout for {rm_emails}")
            conn.execute(text(push_specific_rm))
            conn.commit()


remove_tmp_tables()
create_tmp_tables()
push_to_tblpayout(csr_emails=['swalz@cvrx.com', 'cmccurley@cvrx.com'])

conn.close()
