/***************/
INSERT INTO
    tblPayout
/**************/
SELECT
    @yyyymm AS YYYYMM,
    EID,
    @quarter AS YYYYQQ,
    @role AS ROLE,
    CASE
        WHEN EID IN (
            SELECT
                DISTINCT EID
            FROM
                tblPayout
            WHERE
                yyyymm = @yyyymm
                AND [STATUS] = 'ACTIVE'
        ) THEN 'ACTIVE'
        ELSE 'TERMED'
    END AS STATUS,
    VALUE,
    'YTD_PO' AS CATEGORY,
    NULL AS NOTES
FROM
    (
        SELECT
            EID,
            ROUND(sum(cast(value AS float)), 0) AS VALUE
        FROM
            tblPayout
        WHERE
            left(YYYYMM, 4) = @year
            AND CATEGORY = 'PO_AMT'
            AND ROLE = @role
        GROUP BY
            eid
    ) A
WHERE
    EID IN (
        SELECT
            DISTINCT EID
        FROM
            tblPayout
        WHERE
            yyyymm = @yyyymm
    )