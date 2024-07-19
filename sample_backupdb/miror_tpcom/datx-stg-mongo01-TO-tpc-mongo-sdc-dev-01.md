datx-stg-mongo01-TO-tpc-mongo-sdc-dev-01

## add host to server ssh-key
```shell
echo '192.168.12.21    datx-stg-mongo01'| sudo tee -a /etc/hosts
echo '10.48.15.120    tpc-mongo-sdc-dev-01'| sudo tee -a /etc/hosts

```
## Copy client ssh-key

```shell
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVaV+4oJHIRSbEMHuWQ2bA0ta1S+W+dB53jQf3dto35AOoqRJgLiLMhVP9fGQPh+unb+3CUZl8bFZWFxHfFs4FZV+0ttCMgmRxc8n0Oegdb86dEko8/zDnHEG3bjhUzwciWzvn7FJ4ChYq9jWJC8jkiTpTZDMibtAdo5tTWFtFHB+B6b2D3JH1/GxZzJ0PxT7tZ9HES0+FMVvFFMI5BzhXjdYuHIkAdjhP6UPv0uAmEWncWvQYAgYq7Oz5vAWcprVKY9BRjBx0ThmWfZXAhNYwUaaguoCSlwMpckwcjjFFf7O70F1rZulGG+PvhghDMrUYgASl0lwE2t6yBrKZZmpUGY0xp8dqKYWQHbG1sd1Kv+Nau7usl8xttwTrVLBTGeql78Dv7a1aThzQGy6v7JiGcyE9jwUXSjC/K3ObFABpYsV8iIRCpgag1jJUfeOdy2JZHf2EPvFddcNJa6IxccR7j3qowvlHJ/9DG0r65B6B8yNeue/7BGUW/OXlWU3wHqTeovNAopCZupNrwtTJPkqhtLAqBS6q4pUtJPw0EfRaBuSWiR7T8UknmtnZ/C5OvJxekwPEz9O6aYWvRaQyp+wxT+KY9Gk1Jxymh3tHkx56y55sazVBjnTSTadJzPL0Ri6Z50Q79tWiJV2gHN8hR6jcAyxeNXhltsFDuMvRDNuoMQ== datxbackup@192.168.0.11' |sudo tee -a /home/datxbackup/.ssh/authorized_keys

```
## Test ssh
```shell
ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@datx-stg-mongo01
ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@tpc-mongo-sdc-dev-01

## config backup target server need backup
ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@datx-stg-mongo01 "sudo mkdir -p /opt/backup/ /var/log/backup/ /data/backup/ && sudo chown datxbackup.datxbackup /opt/backup/ /var/log/backup/ /data/backup/ -R "
ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@tpc-mongo-sdc-dev-01 "sudo mkdir -p /opt/backup/ /var/log/backup/ /data/backup/ && sudo chown datxbackup.datxbackup /opt/backup/ /var/log/backup/ /data/backup/ -R "

# Source
server_ip="192.168.12.21"
hostname="datx-stg-mongo01"
env="Development"
db_type="Mongo"

# Destination
des_server_ip="10.48.15.120"
des_hostname="tpc-mongo-sdc-dev-01"
env="Development"
db_type="Mongo"

    mkdir -p /opt/backup/adhoc/$server_ip/
    rm -f /opt/backup/adhoc/$server_ip/backup-adhoc-mongodb_ori.sh 
    cp "/opt/backup/backup-mongodb_ori.sh" "/opt/backup/adhoc/$server_ip/backup-adhoc-mongodb_ori.sh"
    
    sed -i 's/server_ip="192.168.0.22"/server_ip="'$server_ip'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mongodb_ori.sh
    sed -i 's/hostname="datx-mongo02"/hostname="'$hostname'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mongodb_ori.sh
    sed -i 's/remote_backup_ip="192.168.0.110"/remote_backup_ip="'$des_server_ip'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mongodb_ori.sh
    sed -i 's/backup/middleware/data/backup/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mongodb_ori.sh

    server_ip="192.168.12.21"
    time rsync -avzP -e "ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no" /opt/backup/adhoc/$server_ip/backup-adhoc-mongodb_ori.sh datxbackup@$hostname:/opt/backup/

    hostname="tpc-mongo-sdc-dev-01"
    hostname="datx-stg-mongo01"
    time rsync -avzP -e "ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no" /home/datxbackup/.ssh/id_rsa datxbackup@$hostname:/home/datxbackup/.ssh/

8. Create a key file for mongodb
# on Primary server tpc-mongo-sdc-dev-01
openssl rand -base64 756 > /opt/mongo-keyfile
# copy file key mongo sang các node
rsync -avzP -e "ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no" /opt/mongo-keyfile root@tpc-mysql-mongo-sdc-dev-02:/opt/
rsync -avzP -e "ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no" /opt/mongo-keyfile root@tpc-mysql-mongo-sdc-dev-03:/opt/

# phân quyền file key ở all nodes
chmod 400 /opt/mongo-keyfile
chown mongodb:mongodb /opt/mongo-keyfile


# backup
backup_user="mongo-root"
backup_pass="w2tWZe3HKJHcgxLLQoudnp4d"
backup_auth_db="admin"
local_backup_path="/data/backup/mongodb"
backup_file="${local_backup_path}"/all-database-$(date +%Y-%m-%d_%Hh%Mm).gz

time mongodump --authenticationDatabase="${backup_auth_db}" --username="${backup_user}" --password="${backup_pass}" --gzip --archive="${backup_file}"

# transfer
hostname="tpc-mongo-sdc-dev-01"
rsync -avzP --bwlimit=90000 -e "ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no" /data/backup/mongodb/all-database-2024-06-*.gz datxbackup@$hostname:/data/backup/mongodb/


# Run
# Check thông tin prymary
mongosh -u mongo-root -p --authenticationDatabase admin
w2tWZe3HKJHcgxLLQoudnp4d
mongosh -u backupUser -p --authenticationDatabase admin
PtZUE9KkEMKviFazn2ipJ3kgoShf2SQf
rs.status()

# Tạm dừng đồng bộ hóa trên các secondary
    rs.freeze(7200) # 2h dong bang
# remove slave node để không mất master khi restore
rs.remove("10.48.15.121:27017")
rs.remove("10.48.15.122")

#restore
mongorestore -u mongo-root --authenticationDatabase=admin --drop --gzip --archive=/data/backup/mongodb/all-database-2024-06-29_18h31m.gz
w2tWZe3HKJHcgxLLQoudnp4d

mongorestore -u mongo-root --authenticationDatabase=admin  --gzip --archive=/data/backup/mongodb/all-database-2024-06-29_18h31m.gz  --oplogReplay

# tại slave node check db và xóa các db đang tồn tại
```shell
# check db
db.getMongo().getDBNames().forEach(function(dbName) {
    var dbStats = db.getSiblingDB(dbName).stats();
    print("- " + dbName + " (" + (dbStats.dataSize / 1024 / 1024).toFixed(4) + " MB)");
});

# xóa db

# Thiết lập read preference
db.getMongo().setReadPref("secondary")

# Lấy danh sách các database cần xóa
var dbsToDelete = [];
try {
  dbsToDelete = db.getMongo().getDBNames().filter(function(dbName) {
    return !['admin', 'config', 'local'].includes(dbName);
  });
} catch (e) {
  print("Lỗi khi lấy danh sách database: " + e);
}

# In ra danh sách các database sẽ bị xóa
print("Các database sẽ bị xóa:");
printjson(dbsToDelete);

# Xóa các database
dbsToDelete.forEach(function(dbName) {
  print("Đang xóa database: " + dbName);
  try {
    db.getSiblingDB(dbName).dropDatabase();
  } catch (e) {
    print("Lỗi khi xóa database " + dbName + ": " + e);
  }
});

# Kiểm tra kết quả
var remainingDBs = [];
try {
  remainingDBs = db.getMongo().getDBNames();
} catch (e) {
  print("Lỗi khi lấy danh sách database còn lại: " + e);
}

print("\nCác database còn lại sau khi xóa:");
printjson(remainingDBs);

# In ra số lượng database đã xóa
print("\nSố lượng database đã xóa: " + (dbsToDelete.length));
print("Số lượng database còn lại: " + remainingDBs.length);
```

# resync cluster node ( add từng node đợi sync xong)
rs.add("10.48.5.12")
rs.add("10.48.5.13")
# check 
use local
db.oplog.rs.find().sort({$natural:-1}).limit(1)
# Khởi động mongod với cấu hình này:
mongod --config /etc/mongod.conf

# Link 
mongodb:#mongo-root:w2tWZe3HKJHcgxLLQoudnp4d@10.48.15.120:27017,10.48.15.121:27017,10.48.15.122:27017/?replicaSet=rsdev01&readPreference=primary&authMechanism=DEFAULT&authSource=admin




### thay đổi ip cấu hình mongo cluster
```shell
# Lấy cấu hình hiện tại
var cfg = rs.conf()

# In ra cấu hình cũ
print("Cấu hình cũ:")
printjson(cfg)

# Thay đổi địa chỉ
cfg.members[0].host = "10.48.5.11:27017"

# In ra cấu hình mới
print("\nCấu hình mới:")
printjson(cfg)

# Áp dụng cấu hình mới
print("\nĐang áp dụng cấu hình mới...")
rs.reconfig(cfg)

# Kiểm tra lại status
print("\nStatus sau khi thay đổi:")
printjson(rs.status())
```