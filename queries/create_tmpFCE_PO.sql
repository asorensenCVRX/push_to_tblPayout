SELECT
    ISNULL(A.SALES_CREDIT_FCE_EMAIL, B.EMP_EMAIL) AS [FCE_EMAIL],
    C.NAME_REP AS [NAME],
    c.REGION_NM,
    ISNULL(A.ROLE, B.ROLE) AS [ROLE],
    ISNULL(A.PAY_PERIOD, B.[YYYYMM]) AS [YYYYMM],
    (
        SELECT
            DISTINCT YYYYQQ
        FROM
            qrycalendar Q
        WHERE
            Q.YYYYMM = ISNULL(A.PAY_PERIOD, B.[YYYYMM])
    ) AS [YYYYQQ],
    isnull(M0.M0_QTY, 0) AS QTY,
    isnull(M0.M0_SALES, 0) AS SALES,
    YTD_TGT_IMPLANTS,
    A.[%_FY_QUOTA],
    isnull(A.YTD_BASE_BONUS_PAID, 0) + isnull(A.BASE_BONUS_PO, 0) AS YTD_BASE_BONUS_PAID,
    --A.FY_TGT_BONUS_PAID, 
    A.OTHER_PO,
    A.TGT_BONUS_PO,
    CPAS_SPIFF_DEDUCTION,
    ISNULL(sp.PO, 0) [CPAS_SPIFF_PO],
    A.BASE_BONUS_PO,
    (
        ISNULL(A.TGT_BONUS_PO + A.BASE_BONUS_PO, 0)
    ) + ISNULL(A.OTHER_PO, 0) AS FCE_TTL_PO,
    SALES AS FY_BASE_SALES,
    B.PO_FREQ,
    CAST(ROUND(B.PO_AMT, 2) AS MONEY) [GUR_AMT],
    --D.AMT AS [ADJUSTMENTS],
    CAST(
        ROUND(
            CASE
                WHEN PO_FREQ = 'M'
                AND B.PO_AMT > (
                    ISNULL(A.TGT_BONUS_PO + A.BASE_BONUS_PO, 0) + ISNULL(A.OTHER_PO, 0)
                ) THEN B.PO_AMT - (
                    ISNULL(A.TGT_BONUS_PO + A.BASE_BONUS_PO, 0) + ISNULL(A.OTHER_PO, 0)
                )
                ELSE 0
            END,
            2
        ) AS MONEY
    ) AS [GUR_ADJ],
    CAST(
        ROUND(
            CASE
                WHEN PO_FREQ = 'M'
                AND B.PO_AMT > (
                    ISNULL(A.TGT_BONUS_PO + A.BASE_BONUS_PO, 0) + ISNULL(A.OTHER_PO, 0)
                ) --+ ISNULL(D.AMT, 0)
                THEN B.PO_AMT
                ELSE(
                    ISNULL(A.TGT_BONUS_PO + A.BASE_BONUS_PO, 0) + ISNULL(A.OTHER_PO, 0)
                ) + ISNULL(sp.PO, 0) --+ ISNULL(D.AMT, 0)
            END,
            2
        ) AS MONEY
    ) AS [PO_AMT] INTO dbo.tmpFCE_PO
FROM
    (
        /*** THIS IS THE GROUP BY AND PO SUBQUERY START **/
        SELECT
            (
                SELECT
                    YYYYMM
                FROM
                    qryCalendar
                WHERE
                    [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
            ) AS [PAY_PERIOD],
            C1.SALES_CREDIT_FCE_EMAIL,
            C1.NAME_REP,
            C1.ROLE,
            C2.BASE_BONUS [BASE_BONUS],
            C2.TGT_BONUS,
            c1.TGT_PO - ISNULL(
                (
                    SELECT
                        SUM(CAST([VALUE] AS MONEY))
                    FROM
                        [dbo].[qryPayout_ADJ] A
                    WHERE
                        ROLE = 'FCE'
                        AND CATEGORY = 'TGT_BONUS_PO'
                        AND YYYYMM < (
                            SELECT
                                YYYYMM
                            FROM
                                qryCalendar
                            WHERE
                                [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
                        )
                        AND c1.SALES_CREDIT_FCE_EMAIL = A.EID
                ),
                0
            ) [TGT_BONUS_PO],
            C2.BATwire_PO,
            C1.DOH,
            C1.QTY,
            YTD_TGT_IMPLANTS,
            C1.SALES,
            X.QUOTA,
            ROUND(ISNULL(C1.SALES / NULLIF(X.QUOTA, 0), 0), 3) * 100 AS [%_FY_QUOTA],
            CAST(
                ISNULL(C1.SALES / NULLIF(X.QUOTA, 0), 0) * (C2.BASE_BONUS) AS MONEY
            ) AS [FY_BASE_BONUS_EARNED],
            ISNULL(
                (
                    SELECT
                        SUM(CAST([VALUE] AS MONEY))
                    FROM
                        [dbo].[qryPayout_ADJ] A
                    WHERE
                        ROLE = 'FCE'
                        AND CATEGORY = 'BASE_BONUS_PO'
                        AND YYYYMM < (
                            SELECT
                                YYYYMM
                            FROM
                                qryCalendar
                            WHERE
                                [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
                        )
                        AND c1.SALES_CREDIT_FCE_EMAIL = A.EID
                ),
                0
            ) AS [YTD_BASE_BONUS_PAID],
            ISNULL(
                CAST(
                    ISNULL(C1.SALES / NULLIF(X.QUOTA, 0), 0) * (C2.BASE_BONUS) AS MONEY
                ) - ISNULL(
                    (
                        SELECT
                            SUM(CAST([VALUE] AS MONEY))
                        FROM
                            [dbo].[qryPayout_ADJ] A
                        WHERE
                            ROLE = 'FCE'
                            AND CATEGORY = 'BASE_BONUS_PO'
                            AND YYYYMM < (
                                SELECT
                                    YYYYMM
                                FROM
                                    qryCalendar
                                WHERE
                                    [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
                            )
                            AND c1.SALES_CREDIT_FCE_EMAIL = A.EID
                    ),
                    0
                ),
                0
            ) AS [BASE_BONUS_PO],
            ISNULL(
                (
                    SELECT
                        SUM(CAST([VALUE] AS MONEY))
                    FROM
                        [dbo].[qryPayout_ADJ] A
                    WHERE
                        ROLE = 'FCE'
                        AND CATEGORY = 'TGT_BONUS_PO'
                        AND YYYYMM < (
                            SELECT
                                YYYYMM
                            FROM
                                qryCalendar
                            WHERE
                                [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
                        )
                        AND c1.SALES_CREDIT_FCE_EMAIL = A.EID
                ),
                0
            ) AS [TGT_BONUS_PAID],
            -- c3.PO_PER [TGT_BONUS_PO],
            OTHER_PO,
            [CPAS_SPIFF_DEDUCTION]
        FROM
            (
                SELECT
                    [SALES_CREDIT_FCE_EMAIL],
                    [NAME_REP],
                    [ROLE],
                    DOH,
                    ISNULL(SUM([QTY]), 0) [QTY],
                    ISNULL(SUM([SALES_BASE]), 0) [SALES],
                    ISNULL(SUM([isTarget?]), 0) [YTD_TGT_IMPLANTS],
                    SUM(PO_PER) [PO_PER],
                    SUM(TGT_PO) [TGT_PO],
                    SUM(CPAS_SPIFF_DEDUCTION) [CPAS_SPIFF_DEDUCTION],
                    0 OTHER_PO --SUM(CM_AUX_PO) OTHER_PO
                FROM
                    qry_COMP_FCE_DETAIL AS T
                GROUP BY
                    [SALES_CREDIT_FCE_EMAIL],
                    [NAME_REP],
                    [ROLE],
                    DOH
            ) AS C1
            LEFT JOIN tblFCE_COMP C2 ON c1.SALES_CREDIT_FCE_EMAIL = c2.FCE_EMAIL
            LEFT JOIN (
                SELECT
                    A.*,
                    B.QUOTA
                FROM
                    [dbo].[tblFCE_COMP] A
                    LEFT JOIN (
                        SELECT
                            A.EMAIL,
                            A.ACTIVE_YYYYMM,
                            A.DOT_YYYYMM,
                            SUM(QUOTA) [QUOTA]
                        FROM
                            (
                                SELECT
                                    A.EMAIL,
                                    A.ACTIVE_YYYYMM,
                                    A.DOT_YYYYMM,
                                    ISNULL(
                                        CASE
                                            WHEN A.[KEY] IN ('RE_05', 'RE_07') THEN REVISED_Q.QUOTA_FY
                                            ELSE R.Quota
                                        END,
                                        y.QUOTA_FY
                                    ) QUOTA
                                FROM
                                    qryAlign_FCE A
                                    LEFT JOIN tblRates_RM R ON R.REGION_ID = A.[KEY]
                                    LEFT JOIN qryRates_AM Y ON a.[KEY] = Y.TERR_ID
                                    LEFT JOIN (
                                        /*  This query takes into account H2 quota changes for RE_07 and RE_05 so CSRs are calc'd on original H1 quotas and revised H2 quotas */
                                        SELECT
                                            B.REGION_ID,
                                            CASE
                                                WHEN REGION_ID = 'RE_07' THEN 1252705.23
                                                WHEN REGION_ID = 'RE_05' THEN 207248.37
                                                ELSE Q1_Q
                                            END AS Q1_Q,
                                            CASE
                                                WHEN REGION_ID = 'RE_07' THEN 1491315.75
                                                WHEN REGION_ID = 'RE_05' THEN 246724.25
                                                ELSE Q2_Q
                                            END AS Q2_Q,
                                            A.Q3_Q,
                                            A.Q4_Q,
                                            CASE
                                                WHEN REGION_ID = 'RE_07' THEN 1252705.23 + 1491315.75 + Q3_Q + Q4_Q
                                                WHEN REGION_ID = 'RE_05' THEN 207248.37 + 246724.25 + Q3_Q + Q4_Q
                                                ELSE A.QUOTA_FY
                                            END AS QUOTA_FY
                                        FROM
                                            qryRates_RM A
                                            LEFT JOIN tblRates_RM B ON A.EID = B.EID
                                            /* SUB QUERY END */
                                    ) AS REVISED_Q ON A.[KEY] = REVISED_Q.REGION_ID
                                WHERE
                                    [TYPE] IN('REGION', 'TERR')
                            ) AS A
                        GROUP BY
                            A.EMAIL,
                            A.ACTIVE_YYYYMM,
                            A.DOT_YYYYMM
                    ) AS B ON a.FCE_EMAIL = b.EMAIL
            ) AS X ON c1.SALES_CREDIT_FCE_EMAIL = x.FCE_EMAIL
            /** THIS IS THE DETAILED GROUP BY AND PO SUBQUERY END **/
    ) AS A
    LEFT JOIN qryGuarantee B ON A.SALES_CREDIT_FCE_EMAIL = B.EMP_EMAIL
    AND A.ROLE = B.ROLE
    AND A.PAY_PERIOD = B.YYYYMM
    LEFT JOIN qryRoster C ON ISNULL(A.SALES_CREDIT_FCE_EMAIL, B.EMP_EMAIL) = C.REP_EMAIL
    AND C.ROLE = 'FCE'
    AND [isLATEST?] = 1
    LEFT JOIN (
        SELECT
            SPIF_PO_YYYYMM,
            ISNULL(SUM(PO), 0) [PO],
            EMAIL
        FROM
            [dbo].[tblCPAS_PO]
        GROUP BY
            SPIF_PO_YYYYMM,
            EMAIL
    ) AS SP ON ISNULL(A.SALES_CREDIT_FCE_EMAIL, B.EMP_EMAIL) = SP.EMAIL
    AND sp.SPIF_PO_YYYYMM = ISNULL(A.PAY_PERIOD, B.[YYYYMM])
    LEFT JOIN (
        SELECT
            SALES_CREDIT_FCE_EMAIL,
            sum(SALES_BASE) AS M0_SALES,
            SUM(QTY) AS M0_QTY
        FROM
            qry_COMP_FCE_DETAIL
        WHERE
            CLOSE_YYYYMM = (
                SELECT
                    YYYYMM
                FROM
                    qryCalendar
                WHERE
                    [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
            )
        GROUP BY
            SALES_CREDIT_FCE_EMAIL
    ) AS M0 ON M0.SALES_CREDIT_FCE_EMAIL = ISNULL(A.SALES_CREDIT_FCE_EMAIL, B.EMP_EMAIL)
WHERE
    ISNULL(A.ROLE, B.ROLE) = 'FCE'
    AND ISNULL(A.SALES_CREDIT_FCE_EMAIL, B.EMP_EMAIL) IS NOT NULL
    AND ISNULL(c.DOT_YYYYMM, '2099_12') >= (
        SELECT
            YYYYMM
        FROM
            qryCalendar
        WHERE
            [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
    );