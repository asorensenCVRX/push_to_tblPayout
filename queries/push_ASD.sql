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
            CAST(SALES AS VARCHAR) AS SALES,
            CAST(L1_PO AS VARCHAR) AS L1_PO,
            CAST(L2_PO AS VARCHAR) AS L2_PO,
            CAST(L1_REV AS VARCHAR) AS L1_REV,
            CAST(L2_REV AS VARCHAR) AS L2_REV,
            CAST(ASD_TTL_PO AS VARCHAR) AS TTL_PO,
            CAST(GUARANTEE AS VARCHAR) AS GUARANTEE,
            CAST(PO_AMT AS VARCHAR) AS PO_AMT,
            CAST(REVENUE_UNITS AS VARCHAR) AS REVENUE_UNITS,
            CAST(IMPLANT_UNITS AS VARCHAR) AS IMPLANT_UNITS --SPIFF PO
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