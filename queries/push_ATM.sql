INSERT INTO
    tblPayout
SELECT
    YYYYMM,
    ATM_EMAIL,
    YYYYQQ,
    'ATM' AS [ROLE],
    'ACTIVE' AS [STATUS],
    [VALUE],
    [CATEGORY],
    NULL AS NOTES
FROM
    (
        SELECT
            ATM_EMAIL,
            YYYYMM,
            YYYYQQ,
            FORMAT(SALES_COMMISSIONABLE, '0.00') AS SALES,
            FORMAT(PAYOUT, '0.00') AS PO_AMT,
            FORMAT(IMPLANT_UNITS, '0.00') AS IMPLANT_UNITS,
            FORMAT(REVENUE_UNITS, '0.00') AS REVENUE_UNITS
        FROM
            tmpATM_PO
    ) AS P UNPIVOT (
        [VALUE] FOR [CATEGORY] IN (
            SALES,
            PO_AMT,
            IMPLANT_UNITS,
            REVENUE_UNITS
        )
    ) AS UNPVT