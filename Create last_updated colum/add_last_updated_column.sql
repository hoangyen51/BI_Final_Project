DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql = @sql + 
'ALTER TABLE [' + s.name + '].[' + t.name + '] 
 ADD last_updated DATETIME DEFAULT (SYSDATETIMEOFFSET() AT TIME ZONE ''SE Asia Standard Time''); '
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id

EXEC sp_executesql @sql;
