INSERT INTO
    tblPayout
SELECT
    CLOSE_YYYYMM AS YYYYMM,
    SALES_CREDIT_ASD_EMAIL AS EID,
    CONCAT(
        YEAR(DATEADD(MONTH, -1, GETDATE())),
        '_Q',
        DATEPART(QUARTER, DATEADD(MONTH, -1, GETDATE()))
    ) AS YYYYQQ,
    'ASD' AS [ROLE],
    'ACTIVE' AS [STATUS],
    [VALUE],
    [CATEGORY],
    NULL AS NOTES
FROM
    (
        SELECT
            SALES_CREDIT_ASD_EMAIL,
            CLOSE_YYYYMM,
            FORMAT(SALES, '0.00') AS SALES,
            FORMAT(L1_PO, '0.00') AS L1_PO,
            FORMAT(L2_PO, '0.00') AS L2_PO,
            FORMAT(L1_REV, '0.00') AS L1_REV,
            FORMAT(L2_REV, '0.00') AS L2_REV,
            FORMAT(ASD_TTL_PO, '0.00') AS TTL_PO,
            FORMAT(GUARANTEE, '0.00') AS GUARANTEE,
            FORMAT(PO_AMT, '0.00') AS PO_AMT,
            FORMAT(REVENUE_UNITS, '0.00') AS REVENUE_UNITS,
            FORMAT(IMPLANT_UNITS, '0.00') AS IMPLANT_UNITS
        FROM
            tmpASD_PO
    ) P UNPIVOT (
        [VALUE] FOR [CATEGORY] IN (
            SALES,
            L1_PO,
            L2_PO,
            L1_REV,
            L2_REV,
            TTL_PO,
            GUARANTEE,
            PO_AMT,
            REVENUE_UNITS,
            IMPLANT_UNITS
        )
    ) AS UNPV