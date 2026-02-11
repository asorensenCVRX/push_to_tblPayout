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
            FORMAT(SALES, '0.00') AS SALES,
            FORMAT(ATM_ACCOUNT_REVENUE, '0.00') AS ATM_ACCOUNT_REV,
            FORMAT(ATM_ACCOUNT_PO, '0.00') AS ATM_ACCOUNT_PO,
            FORMAT(L1_REV, '0.00') AS L1_REV,
            FORMAT(L1_PO, '0.00') AS L1_PO,
            FORMAT(L2_REV, '0.00') AS L2_REV,
            FORMAT(L2_PO, '0.00') AS L2_PO,
            FORMAT(CPAS_PO, '0.00') AS CPAS_PO,
            FORMAT(IMPLANT_ACCEL_TRUE_UP, '0.00') AS IMPLANT_ACCEL_TRUE_UP,
            FORMAT(PROGRAM_ACCEL_PO, '0.00') AS PROGRAM_ACCEL_PO,
            FORMAT(TTL_PO, '0.00') AS TTL_PO,
            FORMAT(GAURANTEE_AMT, '0.00') AS GUR_AMT,
            FORMAT(PO_AMT, '0.00') AS PO_AMT,
            FORMAT(IMPLANT_UNITS, '0.00') AS IMPLANT_UNITS,
            FORMAT(REVENUE_UNITS, '0.00') AS REVENUE_UNITS,
            FORMAT(QTD_SALES, '0.00') AS QTD_SALES,
            FORMAT(QTD_IMPL_REV_RATIO, '0.0000') AS QTD_IMPL_REV_RATIO
        FROM
            tmpTM_PO
    ) AS P UNPIVOT (
        [VALUE] FOR [CATEGORY] IN (
            SALES,
            ATM_ACCOUNT_REV,
            ATM_ACCOUNT_PO,
            L1_REV,
            L1_PO,
            L2_REV,
            L2_PO,
            CPAS_PO,
            IMPLANT_ACCEL_TRUE_UP,
            PROGRAM_ACCEL_PO,
            TTL_PO,
            GUR_AMT,
            PO_AMT,
            IMPLANT_UNITS,
            REVENUE_UNITS,
            QTD_SALES,
            QTD_IMPL_REV_RATIO
        )
    ) AS UNPVT