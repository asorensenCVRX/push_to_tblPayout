DECLARE @CURRENT_MONTH VARCHAR(7) = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM');


DECLARE @CURRENT_QUARTER VARCHAR(7) = CONCAT(
    LEFT(@CURRENT_MONTH, 4),
    '_Q',
    (
        (CAST(RIGHT(@CURRENT_MONTH, 2) AS INT) -1) / 3 + 1
    )
);


DECLARE @SQL NVARCHAR(MAX);


IF OBJECT_ID(N'tempdb..##ATM', N'U') IS NOT NULL DROP TABLE ##ATM;
SET
    @SQL = N'
    SELECT
    YYYYMM,
    EID,
    YYYYQQ,
    [ROLE],
    [STATUS],
    CAST([VALUE] AS VARCHAR(MAX)) AS [VALUE],
    [CATEGORY],
    NULL AS NOTES INTO ##ATM
FROM
    (
        SELECT
            @CURRENT_MONTH AS YYYYMM,
            @CURRENT_QUARTER AS YYYYQQ,
            REP_EMAIL AS EID,
            ''ATM'' AS [ROLE],
            ''ACTIVE'' AS [STATUS],
            ROUND([' + @CURRENT_MONTH + '], 0) AS MBO_PO,
            ISNULL(MBO_COMPLETION, 0) AS MBO_COMPLETION,
            ROUND([' + @CURRENT_MONTH + '], 0) AS PO_AMT
        FROM
            tmpATM_PO AS A
            LEFT JOIN tblATM_MBO B ON A.REP_EMAIL = B.EID
            AND B.YYYYMM = @CURRENT_MONTH
    ) AS SOURCE UNPIVOT (
        [VALUE] FOR CATEGORY IN ([MBO_PO], [MBO_COMPLETION], [PO_AMT])
    ) AS UNPVT';


EXEC sp_executesql @SQL,
N'@CURRENT_MONTH VARCHAR(7), @CURRENT_QUARTER VARCHAR(7)',
@CURRENT_MONTH,
@CURRENT_QUARTER;


INSERT INTO
    tblPayout
SELECT
    *
FROM ##ATM;

DROP TABLE ##ATM