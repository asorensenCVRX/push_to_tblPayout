INSERT INTO
    dbo.tblPayout
SELECT
    [YYYYMM],
    [SALES_CREDIT_RM_EMAIL] AS [EID],
    YYYYQQ,
    [ROLE],
    'ACTIVE' AS [STATUS],
    [VALUE],
    [CATEGORY],
    [NOTES]
FROM
    (
        SELECT
            CAST(A.[SALES_CREDIT_RM_EMAIL] AS VARCHAR) AS [SALES_CREDIT_RM_EMAIL],
            CAST(A.[NAME] AS VARCHAR) AS [NAME],
            CAST(A.[ROLE] AS VARCHAR) AS [ROLE],
            NULL AS [Notes],
            CAST(A.[YYYYMM] AS VARCHAR) AS [YYYYMM],
            CAST(A.[YYYYQQ] AS VARCHAR) AS [YYYYQQ],
            CAST(A.[QTY] AS VARCHAR) AS [QTY],
            CAST(A.[SALES] AS VARCHAR) AS [SALES],
            CAST(A.[PO_FREQ] AS VARCHAR) AS [PO_FREQ],
            CAST(A.[GUR_AMT] AS VARCHAR) AS [GUR_AMT],
            CAST(A.[GUR_ADJ] AS VARCHAR) AS [GUR_ADJ],
            CAST(A.[RM_L1_PO] AS VARCHAR) AS [RM_L1_PO],
            CAST(A.[RM_L2_PO] AS VARCHAR) AS [RM_L2_PO],
            CAST(A.[RM_L3_PO] AS VARCHAR) AS [RM_L3_PO],
            CAST(A.[RM_L1_REV] AS VARCHAR) AS [RM_L1_REV],
            CAST(A.[RM_L2_REV] AS VARCHAR) AS [RM_L2_REV],
            CAST(A.[RM_L3_REV] AS VARCHAR) AS [RM_L3_REV],
            CAST(A.AD_PO AS VARCHAR) AS [AD_PO],
            CAST(A.[EARNED_MNTH_PO] AS VARCHAR) AS [EARNED_MNTH_PO],
            CAST(A.[EARNED_QTD_PO] AS VARCHAR) AS [EARNED_QTD_PO],
            CAST(A.[PO_AMT] AS VARCHAR) AS [PO_AMT]
        FROM
            dbo.tmpRM_PO A
    ) P UNPIVOT(
        [VALUE] FOR [CATEGORY] IN(
            [QTY],
            [SALES],
            [PO_FREQ],
            [GUR_AMT],
            [GUR_ADJ],
            [RM_L1_PO],
            [RM_L2_PO],
            [RM_L3_PO],
            [AD_PO],
            [RM_L1_REV],
            [RM_L2_REV],
            [RM_L3_REV],
            [EARNED_MNTH_PO],
            [EARNED_QTD_PO],
            [PO_AMT]
        )
    ) AS UNPV