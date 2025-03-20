DECLARE @tableName NVARCHAR(128);
DECLARE @tableSchema NVARCHAR(128);
DECLARE @pkColumn NVARCHAR(128);
DECLARE @sql NVARCHAR(MAX);

DECLARE table_cursor CURSOR FOR
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @tableSchema, @tableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Lấy cột đầu tiên của bảng (giả định là khóa chính)
    SELECT TOP 1 @pkColumn = COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @tableSchema
    AND TABLE_NAME = @tableName
    ORDER BY ORDINAL_POSITION;

    -- Kiểm tra bảng có cột last_updated không
    IF @pkColumn IS NOT NULL AND EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = @tableSchema 
        AND TABLE_NAME = @tableName 
        AND COLUMN_NAME = 'last_updated'
    )
    BEGIN
        -- Tạo câu lệnh SQL động
        SET @sql = '
        CREATE OR ALTER TRIGGER ' + QUOTENAME('trg_UpdateLastUpdated_' + @tableName) + '
        ON ' + QUOTENAME(@tableSchema) + '.' + QUOTENAME(@tableName) + '
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            UPDATE t
            SET last_updated = SYSDATETIMEOFFSET() AT TIME ZONE ''SE Asia Standard Time''
            FROM ' + QUOTENAME(@tableSchema) + '.' + QUOTENAME(@tableName) + ' t
            WHERE EXISTS (SELECT 1 FROM inserted i WHERE i.' + QUOTENAME(@pkColumn) + ' = t.' + QUOTENAME(@pkColumn) + ')
               OR EXISTS (SELECT 1 FROM deleted d WHERE d.' + QUOTENAME(@pkColumn) + ' = t.' + QUOTENAME(@pkColumn) + ');
        END';

        -- Chạy lệnh SQL
        EXEC sp_executesql @sql;
    END;

    FETCH NEXT FROM table_cursor INTO @tableSchema, @tableName;
END;

CLOSE table_cursor;
DEALLOCATE table_cursor;
