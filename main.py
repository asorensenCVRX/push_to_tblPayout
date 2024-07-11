from database import engine
import pandas as pd


conn = engine.connect()


def remove_tmp_tables():
    with open(r"queries/create_tmpAM_PO.sql") as file:
        test = file.read()
        return test


print(remove_tmp_tables())
