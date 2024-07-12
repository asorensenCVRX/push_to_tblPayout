DELETE FROM
    tblPayout
WHERE
    yyyymm = FORMAT(
        DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0),
        'yyyy_MM'
    )