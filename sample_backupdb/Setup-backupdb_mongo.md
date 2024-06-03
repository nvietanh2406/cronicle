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