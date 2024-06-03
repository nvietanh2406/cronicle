#!/bin/bash

# Khai báo biến
server_ip="10.48.15.131"
backup_user="mysqlbackup"
backup_pass="3mTavkJ3W5Z&QR~W~Duy#rVW"
dbname="your_database_name"

# Tạo file tạm thời để chứa câu lệnh SQL
temp_file=$(mktemp)
cat << EOF > "$temp_file"
SELECT @@hostname AS Server, COUNT(*) AS TotalDatabases
FROM INFORMATION_SCHEMA.SCHEMATA;
SELECT '----------------------------', NULL;

SELECT
TABLE_SCHEMA AS DatabaseName,
COUNT(*) AS TableCount
FROM
INFORMATION_SCHEMA.TABLES
GROUP BY
TABLE_SCHEMA;
SELECT '----------------------------', NULL;

SET @randomDb = (SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA ORDER BY RAND() LIMIT 1);
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = @randomDb
ORDER BY RAND()
LIMIT 10;

EOF

# Thực thi câu lệnh SQL và lưu kết quả vào file result.txt
mysql -h"$server_ip" -u"$backup_user" -p"$backup_pass" < "$temp_file" > /opt/backup/mysql/result.txt

# Xóa file tạm thời
rm "$temp_file"