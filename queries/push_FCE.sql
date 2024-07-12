INSERT INTO
    dbo.tblPayout
SELECT
    [YYYYMM],
    [FCE_EMAIL] AS [EID],
    [YYYYQQ],
    [ROLE],
    'ACTIVE' AS [STATUS],
    [VALUE],
    [CATEGORY],
    NULL AS [NOTES]
FROM
    (
        SELECT
            CAST(A.FCE_EMAIL AS varchar(max)) AS FCE_EMAIL,
            CAST(A.NAME AS varchar(max)) AS NAME,
            CAST(A.ROLE AS varchar(max)) AS ROLE,
            CAST(A.YYYYMM AS varchar(max)) AS YYYYMM,
            CAST(A.YYYYQQ AS varchar(max)) AS YYYYQQ,
            CAST(A.QTY AS varchar(max)) AS QTY,
            CAST(CAST(A.SALES AS money) AS varchar(max)) AS SALES,
            CAST(A.YTD_TGT_IMPLANTS AS varchar(max)) AS YTD_TGT_IMPLANTS,
            CAST(A.[%_FY_QUOTA] AS varchar(max)) [%_FY_QUOTA],
            --  CAST(a.[H2_%_TGT_QUOTA] as varchar(max)) [H2_%_TGT_QUOTA],
            CAST(A.TGT_BONUS_PO AS varchar(max)) AS TGT_BONUS_PO,
            CAST(A.BASE_BONUS_PO AS varchar(max)) AS BASE_BONUS_PAID,
            --CAST(A.YTD_TGT_BONUS_PAID as varchar(max)) as H2_TGT_BONUS_PAID, 
            CAST(A.BASE_BONUS_PO AS varchar(max)) AS BASE_BONUS_PO,
            CAST(A.FCE_TTL_PO AS varchar(max)) AS FCE_TTL_PO,
            --CAST(A.H2_TARGET_SALES as varchar(max)) as H2_TARGET_SALES,
            CAST(CAST(A.FY_BASE_SALES AS money) AS varchar(max)) AS FY_BASE_SALES,
            CAST(A.PO_FREQ AS varchar(max)) AS PO_FREQ,
            CAST(A.GUR_AMT AS varchar(max)) AS GUR_AMT,
            CAST(A.GUR_ADJ AS varchar(max)) AS GUR_ADJ,
            CAST(A.PO_AMT AS varchar(max)) AS PO_AMT,
            CAST(A.OTHER_PO AS varchar(max)) AS OTHER_PO,
            cast(A.CPAS_SPIFF_PO AS varchar(max)) AS CPAS_SPIFF_PO,
            cast(A.YTD_BASE_BONUS_PAID AS varchar(max)) AS YTD_BASE_BONUS_PAID
        FROM
            dbo.tmpFCE_PO A
        WHERE
            FCE_EMAIL NOT IN ('bkelly@cvrx.com')
    ) P UNPIVOT (
        [VALUE] FOR [CATEGORY] IN (
            QTY,
            SALES,
            --[H2_%_TGT_QUOTA],
            --H2_TGT_BONUS_PAID,
            YTD_BASE_BONUS_PAID,
            CPAS_SPIFF_PO,
            TGT_BONUS_PO,
            BASE_BONUS_PO,
            FCE_TTL_PO,
            YTD_TGT_IMPLANTS,
            FY_BASE_SALES,
            GUR_AMT,
            GUR_ADJ,
            PO_AMT
        )
    ) AS UNPVT;