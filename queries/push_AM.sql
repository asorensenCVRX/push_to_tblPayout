INSERT INTO
    dbo.tblPayout
SELECT
    [YYYYMM],
    [REP_EMAIL] AS [EID],
    YYYYQQ,
    [ROLE],
    [STATUS],
    [VALUE],
    [CATEGORY],
    [Notes]
FROM
    (
        SELECT
            CAST(A.REP_EMAIL AS varchar) AS REP_EMAIL,
            CAST(A.NAME AS varchar) AS NAME,
            CAST(A.STATUS AS varchar) AS STATUS,
            CAST(A.ROLE AS varchar) AS ROLE,
            NULL AS [Notes],
            CAST(A.YYYYMM AS varchar) AS YYYYMM,
            CAST(A.YYYYQQ AS varchar) AS YYYYQQ,
            CAST(A.QTY AS varchar) AS QTY,
            CAST(A.SALES AS varchar) AS SALES,
            CAST(A.AM_L1_REV AS varchar) AS AM_L1_REV,
            CAST(A.AM_L2_REV AS varchar) AS AM_L2_REV,
            CAST(A.AM_L1_PO AS varchar) AS AM_L1_PO,
            CAST(A.AM_L2_PO AS varchar) AS AM_L2_PO,
            CAST(A.FCE_DEDUCTION AS varchar) AS FCE_DEDUCTION,
            CAST(A.AM_TTL_PO AS varchar) AS AM_TTL_PO,
            -- CAST(A.[SPIFF_DEDUCTION] AS varchar) [SPIFF_DEDUCTION],
            CAST(A.[CPAS_SPIFF_PO] AS varchar) [CPAS_SPIFF_PO],
            --CAST(A.AM_TTL_PO_QTD as varchar) as AM_TTL_PO_QTD,
            CAST(A.PO_FREQ AS varchar) AS PO_FREQ,
            CAST(A.GUR_AMT AS varchar) AS GUR_AMT,
            CAST(A.ADJUSTMENTS AS varchar) AS ADJUSTMENTS,
            CAST(A.GUR_ADJ AS varchar) AS GUR_ADJ,
            CAST(A.PO_AMT AS varchar) AS PO_AMT
        FROM
            dbo.tmpAM_PO A
            LEFT JOIN (
                SELECT
                    m.TM_EID [SALES_CREDIT_TM],
                    [CLOSE_YYYYMM],
                    [CLOSE_YYYYQQ],
                    O.TM_RATE,
                    ISNULL(SUM([QTY]), 0) [QTY],
                    ISNULL(SUM([SALES]), 0) [SALES]
                FROM
                    qry_COMP_AM_DETAIL AS T
                    LEFT JOIN tblRates_AM M ON t.SALES_CREDIT_REP_EMAIL = M.EID
                    LEFT JOIN tblRates_AM O ON m.TM_EID = O.EID
                WHERE
                    M.TM_EID IS NOT NULL
                GROUP BY
                    m.TM_EID,
                    [CLOSE_YYYYMM],
                    [CLOSE_YYYYQQ],
                    O.TM_RATE
            ) AS B ON a.REP_EMAIL = b.SALES_CREDIT_TM
            AND a.YYYYMM = b.CLOSE_YYYYMM
    ) P UNPIVOT (
        [VALUE] FOR [CATEGORY] IN (
            SALES,
            AM_L1_REV,
            AM_L2_REV,
            AM_L1_PO,
            AM_L2_PO,
            FCE_DEDUCTION,
            AM_TTL_PO,
            -- [SPIFF_DEDUCTION],
            [CPAS_SPIFF_PO],
            --PO_FREQ, 
            GUR_AMT,
            ADJUSTMENTS,
            GUR_ADJ,
            PO_AMT,
            QTY
        )
    ) AS UNPVT