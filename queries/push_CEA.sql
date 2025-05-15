INSERT INTO
    tblPayout
SELECT
    *,
    NULL AS NOTES
FROM
    (
        SELECT
            YYYYMM,
            REP_EMAIL AS EID,
            CONCAT(
                YEAR(DATEADD(MONTH, -1, GETDATE())),
                '_Q',
                DATEPART(QUARTER, DATEADD(MONTH, -1, GETDATE()))
            ) AS YYYYQQ,
            'CEA' AS [ROLE],
            'ACTIVE' AS [STATUS],
            CAST(SALES_COMMISSIONABLE AS VARCHAR) AS SALES_COMMISSIONABLE,
            CAST(L1_REV AS VARCHAR) AS L1_REV,
            CAST(L2_REV AS VARCHAR) AS L2_REV,
            CAST(L3_REV AS VARCHAR) AS L3_REV,
            CAST(L1_PO AS VARCHAR) AS L1_PO,
            CAST(L2_PO AS VARCHAR) AS L2_PO,
            CAST(L3_PO AS VARCHAR) AS L3_PO,
            CAST(EOQ_RATIO_PAYOUT AS VARCHAR) AS EOQ_RATIO_PO,
            CAST(Q0_RATIO AS VARCHAR) AS Q0_RATIO,
            CAST(PO_AMT AS VARCHAR) AS PO_AMT
        FROM
            tmpCEA_PO
    ) AS SOURCE UNPIVOT (
        [VALUE] FOR CATEGORY IN (
            SALES_COMMISSIONABLE,
            L1_REV,
            L2_REV,
            L3_REV,
            L1_PO,
            L2_PO,
            L3_PO,
            EOQ_RATIO_PO,
            Q0_RATIO,
            PO_AMT
        )
    ) AS UNPVT