DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql = @sql + '
DROP TRIGGER [' + s.name + '].[' + tr.name + ']; '
FROM sys.triggers tr
JOIN sys.tables t ON tr.parent_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE tr.name LIKE 'trg_CRUD_LastUpdated_%';

-- Thá»±c thi lá»nh xÃ³a trigger
EXEC sp_executesql @sql;
