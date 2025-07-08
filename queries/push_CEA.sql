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
            FORMAT(SALES_COMMISSIONABLE, '0.00') AS SALES_COMMISSIONABLE,
            FORMAT(L1_REV, '0.00') AS L1_REV,
            FORMAT(L2_REV, '0.00') AS L2_REV,
            FORMAT(L3_REV, '0.00') AS L3_REV,
            FORMAT(L1_PO, '0.00') AS L1_PO,
            FORMAT(L2_PO, '0.00') AS L2_PO,
            FORMAT(L3_PO, '0.00') AS L3_PO,
            FORMAT(EOQ_RATIO_PAYOUT, '0.0000') AS EOQ_RATIO_PO,
            FORMAT(Q0_RATIO, '0.0000') AS Q0_RATIO,
            FORMAT(PO_AMT, '0.00') AS PO_AMT
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