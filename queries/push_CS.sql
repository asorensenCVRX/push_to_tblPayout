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
            CAST(SALES AS VARCHAR) AS SALES,
            CAST(TGT_PO AS VARCHAR) AS TGT_PO,
            CAST(REGIONAL_PO AS VARCHAR) AS REGIONAL_PO,
            CAST(TOTAL_PO AS VARCHAR) AS TOTAL_PO,
            CAST(YTD_SALES AS VARCHAR) AS YTD_SALES,
            CAST([%_FY_PLAN] AS VARCHAR) AS [%_FY_PLAN]
        FROM
            tmpCS_PO
    ) AS P UNPIVOT (
        [VALUE] FOR [CATEGORY] IN (
            SALES,
            TGT_PO,
            REGIONAL_PO,
            TOTAL_PO,
            YTD_SALES,
            [%_FY_PLAN]
        )
    ) AS UNPVT