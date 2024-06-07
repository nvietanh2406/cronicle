# I. Config and setup backup database with cronicle
```shell
    cd /opt/ &&
    git clone https://github.com/nvietanh2406/cronicle.git &&
    mkdir -p /opt/backup/adhoc /opt/backup/checkdb
```
Link setup:

G:\GIT\nvietanh2406\cronicle\sample_backupdb\Setup-backupdb_mysql.md

# II. create file temp and change server
## Mongodb
### backup adhoc for 

```shell
server_ip="192.168.0.22"
hostname="datx-mongo02"
env="Production"
db_type="Redis"

mkdir -p /opt/backup/adhoc/$server_ip/
rm -f /opt/backup/adhoc/$server_ip/backup-mongodb.sh 
cp "/opt/backup/backup-mongodb" "/opt/backup/adhoc/$server_ip/backup-adhoc-mongodb"

sed -i 's/server_ip="192.168.0.22"/server_ip="'$server_ip'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
sed -i 's/hostname="datx-mongo02"/hostname="'$hostname'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
sed -i 's/env="Production"/env="'$env'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
sed -i 's/db_type="Redis"/db_type="'$db_type'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh


```

# III. Script check mongo db

```shell
#!/bin/bash

# Khai báo biến
server_ip="your_mongodb_server_ip"
mongo_user="your_mongodb_username"
mongo_pass="your_mongodb_password"

# Tạo file tạm thời để chứa script MongoDB
temp_file=$(mktemp)
cat << EOF > "$temp_file"
// Lấy danh sách tất cả các database
db = db.getSiblingDB('admin');
db.auth('$mongo_user', '$mongo_pass');
dbs = db.adminCommand('listDatabases');
print('------- Danh sách database -------');
printjson(dbs.databases);

// Lấy thông tin về một database ngẫu nhiên
randomDbName = dbs.databases[Math.floor(Math.random() * dbs.databases.length)].name;
randomDb = db.getSiblingDB(randomDbName);
print('\n------- Database ngẫu nhiên: ' + randomDbName + ' -------');

// Lấy danh sách các collection trong database đó
collections = randomDb.getCollectionNames();
print('Số collection: ' + collections.length);
print('Danh sách collection:');
printjson(collections);

// Lấy 10 document ngẫu nhiên từ một collection ngẫu nhiên
if (collections.length > 0) {
    randomCollection = collections[Math.floor(Math.random() * collections.length)];
    print('\nCollection ngẫu nhiên: ' + randomCollection);
    docs = randomDb.getCollection(randomCollection).find().limit(10).toArray();
    print('10 document ngẫu nhiên:');
    printjson(docs);
} else {
    print('Database không có collection');
}
EOF

# Thực thi script MongoDB và lưu kết quả vào file result.txt
mongo --host "$server_ip" --quiet "$temp_file" > /opt/backup/mongodb/result.txt

# Xóa file tạm thời
rm "$temp_file"
```