DECLARE	@table_name sysname
	,	@object_name sysname
    ,	@object_id int

DECLARE @is_drop_table bit = 1
DECLARE @is_create_fk bit = 0
DECLARE @is_create_ix bit = 1
DECLARE @is_create_df bit = 1

DECLARE @check_table_exists bit = 1

DECLARE @SQL nvarchar(max)

DECLARE cur_create_tables CURSOR
FOR
	SELECT	t.object_id
	FROM	sys.tables t
	WHERE	t.name IN ('INSTANCE')
	ORDER	BY t.name

OPEN cur_create_tables

FETCH NEXT FROM cur_create_tables
INTO @object_id	



WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT 
		  @object_name = '[' + s.name + '].[' + o.name + ']'
		, @object_id = o.[object_id]
	FROM sys.objects o WITH (NOWAIT)
	JOIN sys.schemas s WITH (NOWAIT) ON o.[schema_id] = s.[schema_id]
	WHERE o.object_id = @object_id
	
	SET @SQL = ''

	;WITH index_column AS 
	(
		SELECT 
			  ic.[object_id]
			, ic.index_id
			, ic.is_descending_key
			, ic.is_included_column
			, c.name
		FROM sys.index_columns ic WITH (NOWAIT)
		JOIN sys.columns c WITH (NOWAIT) ON ic.[object_id] = c.[object_id] AND ic.column_id = c.column_id
		WHERE ic.[object_id] = @object_id
	),
	fk_columns AS 
	(
		 SELECT 
			  k.constraint_object_id
			, cname = c.name
			, rcname = rc.name
		FROM sys.foreign_key_columns k WITH (NOWAIT)
		JOIN sys.columns rc WITH (NOWAIT) ON rc.[object_id] = k.referenced_object_id AND rc.column_id = k.referenced_column_id 
		JOIN sys.columns c WITH (NOWAIT) ON c.[object_id] = k.parent_object_id AND c.column_id = k.parent_column_id
		WHERE k.parent_object_id = @object_id
	),
	df_columns AS 
	(
		SELECT	d.parent_object_id
			,	defname = d.name
			,	cname = c.name
			,	cdefintion = d.definition
		FROM	sys.default_constraints d WITH(NOWAIT)
				JOIN sys.columns c WITH(NOWAIT) ON d.[parent_object_id] = c.[object_id] AND d.[parent_column_id] = c.[column_id]
	)
	SELECT @SQL = 
		CASE
			WHEN @is_drop_table = 1 THEN 'DROP TABLE ' + @object_name + CHAR(10) + CHAR(13) + 'GO' + CHAR(10) + CHAR(13) 
			ELSE ''
		END 
		+
		--CASE
		--	WHEN @check_table_exists = 1 THEN 'IF NOT EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = OBJECT_ID(''' + @object_name + ''') AND OBJECTPROPERTY(id, "IsUserTable") = 1)' + CHAR(13)
		--	ELSE ''
		--END
		--+
		'CREATE TABLE ' + @object_name + CHAR(13) + '(' + CHAR(13) + STUFF((
		SELECT CHAR(9) + ', [' + c.name + '] ' + 
			CASE WHEN c.is_computed = 1
				THEN 'AS ' + cc.[definition] 
				ELSE UPPER(tp.name) + 
					CASE WHEN tp.name IN ('varchar', 'char', 'varbinary', 'binary', 'text')
						   THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR(5)) END + ')'
						 WHEN tp.name IN ('nvarchar', 'nchar', 'ntext')
						   THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length / 2 AS VARCHAR(5)) END + ')'
						 WHEN tp.name IN ('datetime2', 'time2', 'datetimeoffset') 
						   THEN '(' + CAST(c.scale AS VARCHAR(5)) + ')'
						 WHEN tp.name = 'decimal' 
						   THEN '(' + CAST(c.[precision] AS VARCHAR(5)) + ',' + CAST(c.scale AS VARCHAR(5)) + ')'
						ELSE ''
					END +
					CASE WHEN c.collation_name IS NOT NULL THEN ' COLLATE ' + c.collation_name ELSE '' END +
					CASE WHEN c.is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END +					
					CASE WHEN ic.is_identity = 1 THEN ' IDENTITY(' + CAST(ISNULL(ic.seed_value, '0') AS CHAR(1)) + ',' + CAST(ISNULL(ic.increment_value, '1') AS CHAR(1)) + ')' ELSE '' END 
			END + CHAR(13)
		FROM sys.columns c WITH (NOWAIT)
		JOIN sys.types tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id
		LEFT JOIN sys.computed_columns cc WITH (NOWAIT) ON c.[object_id] = cc.[object_id] AND c.column_id = cc.column_id		
		LEFT JOIN sys.identity_columns ic WITH (NOWAIT) ON c.is_identity = 1 AND c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
		WHERE c.[object_id] = @object_id
		ORDER BY c.column_id
		FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, CHAR(9) + ' ')
		+ ISNULL((SELECT CHAR(9) + ', CONSTRAINT [' + k.name + '] PRIMARY KEY (' + 
						(SELECT STUFF((
							 SELECT ', [' + c.name + '] ' + CASE WHEN ic.is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END
							 FROM sys.index_columns ic WITH (NOWAIT)
							 JOIN sys.columns c WITH (NOWAIT) ON c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
							 WHERE ic.is_included_column = 0
								 AND ic.[object_id] = k.parent_object_id 
								 AND ic.index_id = k.unique_index_id     
							 FOR XML PATH(N''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, ''))
				+ ')' + CHAR(13)
				FROM sys.key_constraints k WITH (NOWAIT)
				WHERE k.parent_object_id = @object_id 
					AND k.[type] = 'PK'), '') + ')'  + CHAR(10) + CHAR(13) + 'GO' + CHAR(10) + CHAR(13) 
		+ CASE 
			WHEN @is_create_fk = 1 THEN 
			ISNULL((SELECT (
			SELECT CHAR(13) +
				 'ALTER TABLE ' + @object_name + ' WITH' 
				+ CASE WHEN fk.is_not_trusted = 1 
					THEN ' NOCHECK' 
					ELSE ' CHECK' 
				  END + 
				  ' ADD CONSTRAINT [' + fk.name  + '] FOREIGN KEY(' 
				  + STUFF((
					SELECT ', [' + k.cname + ']'
					FROM fk_columns k
					WHERE k.constraint_object_id = fk.[object_id]
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '')
				   + ')' +
				  ' REFERENCES [' + SCHEMA_NAME(ro.[schema_id]) + '].[' + ro.name + '] ('
				  + STUFF((
					SELECT ', [' + k.rcname + ']'
					FROM fk_columns k
					WHERE k.constraint_object_id = fk.[object_id]
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '')
				   + ')' + CHAR(13) + 'GO'
				+ CASE 
					WHEN fk.delete_referential_action = 1 THEN ' ON DELETE CASCADE' 
					WHEN fk.delete_referential_action = 2 THEN ' ON DELETE SET NULL'
					WHEN fk.delete_referential_action = 3 THEN ' ON DELETE SET DEFAULT' 
					ELSE '' 
				  END
				+ CASE 
					WHEN fk.update_referential_action = 1 THEN ' ON UPDATE CASCADE'
					WHEN fk.update_referential_action = 2 THEN ' ON UPDATE SET NULL'
					WHEN fk.update_referential_action = 3 THEN ' ON UPDATE SET DEFAULT'  
					ELSE '' 
				  END 
				+ CHAR(13) + 'ALTER TABLE ' + @object_name + ' CHECK CONSTRAINT [' + fk.name  + ']' + CHAR(10) + CHAR(13) + 'GO' + CHAR(10) + CHAR(13) 
			FROM sys.foreign_keys fk WITH (NOWAIT)
			JOIN sys.objects ro WITH (NOWAIT) ON ro.[object_id] = fk.referenced_object_id
			WHERE fk.parent_object_id = @object_id
			FOR XML PATH(N''), TYPE).value('.', 'NVARCHAR(MAX)')), '')
			ELSE ''
		END
		+ CASE
			WHEN @is_create_ix = 1 THEN
			ISNULL(((SELECT
			 CHAR(13) + 'CREATE' + CASE WHEN i.is_unique = 1 THEN ' UNIQUE' ELSE '' END 
					+ ' ' + type_desc + ' INDEX [' + i.name + '] ON ' + @object_name + ' (' +
					STUFF((
					SELECT ', [' + c.name + ']' + CASE WHEN c.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END
					FROM index_column c
					WHERE c.is_included_column = 0
						AND c.index_id = i.index_id
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ')'  
					+ ISNULL(CHAR(13) + 'INCLUDE (' + 
						STUFF((
						SELECT ', [' + c.name + ']'
						FROM index_column c
						WHERE c.is_included_column = 1
							AND c.index_id = i.index_id
						FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ')', '')  + CHAR(10) + CHAR(13) + 'GO' + CHAR(10) + CHAR(13) 
			FROM sys.indexes i WITH (NOWAIT)
			WHERE i.[object_id] = @object_id
				AND i.is_primary_key = 0
				AND i.[type] = 2
			FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')
		), '')
		ELSE ''
		END
		+ CASE
			WHEN @is_create_df = 1 THEN
			ISNULL(((SELECT CHAR(13) +
						'ALTER TABLE ' + @object_name + CHAR(13) +
						'ADD CONSTRAINT [' + d.defname + ']' + CHAR(13) +
						'DEFAULT ' + d.cdefintion + CHAR(13) +
						'FOR [' + d.cname + ']' + CHAR(10) + CHAR(13) + 'GO' + CHAR(10) + CHAR(13) 	 
					FROM df_columns d
					WHERE d.parent_object_id = @object_id
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)') 
				),'')
		END 

		FETCH NEXT FROM cur_create_tables
		INTO @object_id	

		PRINT @SQL
END

CLOSE cur_create_tables
DEALLOCATE cur_create_tables
