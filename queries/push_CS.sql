INSERT INTO
    tblPayout
SELECT
    YYYYMM,
    SALES_CREDIT_CS_EMAIL AS EID,
    CONCAT(
        YEAR(DATEADD(MONTH, -1, GETDATE())),
        '_Q',
        DATEPART(QUARTER, DATEADD(MONTH, -1, GETDATE()))
    ) AS YYYYQQ,
    'CS' AS [ROLE],
    'ACTIVE' AS [STATUS],
    [VALUE],
    [CATEGORY],
    NULL AS NOTES
FROM
    (
        SELECT
            YYYYMM,
            SALES_CREDIT_CS_EMAIL,
            FORMAT(SALES, '0.00') AS SALES,
            FORMAT(TGT_PO, '0.00') AS TGT_PO,
            FORMAT(REGIONAL_PO, '0.00') AS REGIONAL_PO,
            FORMAT(TOTAL_PO, '0.00') AS PO_AMT,
            FORMAT(YTD_SALES, '0.00') AS YTD_SALES,
            FORMAT([%_FY_PLAN], '0.0000') AS [%_FY_PLAN]
        FROM
            tmpCS_PO
    ) AS P UNPIVOT (
        [VALUE] FOR [CATEGORY] IN (
            SALES,
            TGT_PO,
            REGIONAL_PO,
            PO_AMT,
            YTD_SALES,
            [%_FY_PLAN]
        )
    ) AS UNPVT