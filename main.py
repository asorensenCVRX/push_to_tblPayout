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


def push_all_to_tblpayout():
    with open(r"queries/integrity_check.sql") as file:
        integrity_check = file.read()
    with open(r"queries/push_AM.sql") as file:
        push_am = file.read()
    with open(r"queries/push_FCE.sql") as file:
        push_fce = file.read()
    with open(r"queries/push_RM.sql") as file:
        push_rm = file.read()
    print(f"Deleting from tblPayout all records where YYYYMM = {last_month} (so there will not be duplicates).")
    conn.execute(text(integrity_check))
    conn.commit()
    conn.execute(text(push_am))
    conn.execute(text(push_fce))
    conn.execute(text(push_rm))
    conn.commit()


remove_tmp_tables()
create_tmp_tables()
push_all_to_tblpayout()
conn.close()
