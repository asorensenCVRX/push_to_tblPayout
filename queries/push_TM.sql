INSERT INTO
    tblPayout
SELECT
    YYYYMM,
    EID,
    YYYYQQ,
    'TM' AS [ROLE],
    'ACTIVE' AS [STATUS],
    [VALUE],
    [CATEGORY],
    NULL AS NOTES
FROM
    (
        SELECT
            EID,
            YYYYMM,
            YYYYQQ,
            CAST(SALES AS VARCHAR) AS SALES,
            CAST(L1_REV AS VARCHAR) AS L1_REV,
            CAST(L1_PO AS VARCHAR) AS L1_PO,
            CAST(L2_REV AS VARCHAR) AS L2_REV,
            CAST(L2_PO AS VARCHAR) AS L2_PO,
            CAST(CS_DEDUCTION AS VARCHAR) AS CS_DEDUCTION,
            CAST(TTL_PO AS VARCHAR) AS TTL_PO,
            CAST(GAURANTEE_AMT AS VARCHAR) AS GUR_AMT,
            CAST(PO_AMT AS VARCHAR) AS PO_AMT,
            CAST(IMPLANT_UNITS AS VARCHAR) AS IMPLANT_UNITS,
            CAST(REVENUE_UNITS AS VARCHAR) AS REVENUE_UNITS
        FROM
            tmpTM_PO
    ) AS P UNPIVOT (
        [VALUE] FOR [CATEGORY] IN (
            SALES,
            L1_REV,
            L1_PO,
            L2_REV,
            L2_PO,
            CS_DEDUCTION,
            TTL_PO,
            GUR_AMT,
            PO_AMT,
            IMPLANT_UNITS,
            REVENUE_UNITS
        )
    ) AS UNPVT