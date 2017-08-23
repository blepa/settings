WITH CTE_1
AS
(
  SELECT OBJECT_NAME(a.Object_id) as table_name,
         a.Name as columnname,
         CONVERT(bigint, ISNULL(a.last_value,0)) AS last_value,
         Case
              When b.name = 'tinyint'   Then 255
              When b.name = 'smallint'  Then 32767
              When b.name = 'int'       Then 2147483647
              When b.name = 'bigint'    Then 9223372036854775807
            End As dt_value
    FROM sys.identity_columns a
   INNER JOIN sys.types As b
      ON a.system_type_id = b.system_type_id
),
CTE_2
AS
(
SELECT *,
       CONVERT(Numeric(18,2), ((CONVERT(Float, last_value) / CONVERT(Float, dt_value)) * 100)) AS "Percent"
  FROM CTE_1
)
SELECT *
  FROM CTE_2
 ORDER BY "Percent" DESC;
