## add host to server ssh-key
```shell
echo '10.48.15.130    tpc-mysql-mongo-sdc-dev-01'| sudo tee -a /etc/hosts
echo '10.48.15.131    tpc-mysql-mongo-sdc-dev-02'| sudo tee -a /etc/hosts
echo '192.168.12.11    datx-stg-db01'| sudo tee -a /etc/hosts
```
## Copy client ssh-key

```shell
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVaV+4oJHIRSbEMHuWQ2bA0ta1S+W+dB53jQf3dto35AOoqRJgLiLMhVP9fGQPh+unb+3CUZl8bFZWFxHfFs4FZV+0ttCMgmRxc8n0Oegdb86dEko8/zDnHEG3bjhUzwciWzvn7FJ4ChYq9jWJC8jkiTpTZDMibtAdo5tTWFtFHB+B6b2D3JH1/GxZzJ0PxT7tZ9HES0+FMVvFFMI5BzhXjdYuHIkAdjhP6UPv0uAmEWncWvQYAgYq7Oz5vAWcprVKY9BRjBx0ThmWfZXAhNYwUaaguoCSlwMpckwcjjFFf7O70F1rZulGG+PvhghDMrUYgASl0lwE2t6yBrKZZmpUGY0xp8dqKYWQHbG1sd1Kv+Nau7usl8xttwTrVLBTGeql78Dv7a1aThzQGy6v7JiGcyE9jwUXSjC/K3ObFABpYsV8iIRCpgag1jJUfeOdy2JZHf2EPvFddcNJa6IxccR7j3qowvlHJ/9DG0r65B6B8yNeue/7BGUW/OXlWU3wHqTeovNAopCZupNrwtTJPkqhtLAqBS6q4pUtJPw0EfRaBuSWiR7T8UknmtnZ/C5OvJxekwPEz9O6aYWvRaQyp+wxT+KY9Gk1Jxymh3tHkx56y55sazVBjnTSTadJzPL0Ri6Z50Q79tWiJV2gHN8hR6jcAyxeNXhltsFDuMvRDNuoMQ== datxbackup@192.168.0.11' |sudo tee -a /home/datxbackup/.ssh/authorized_keys

```
## Test ssh
```shell
ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@tpc-mysql-mongo-sdc-dev-01
ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@tpc-mysql-mongo-sdc-dev-02
ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@datx-stg-db01

# config backup target server need backup
ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@tpc-mysql-mongo-sdc-dev-01 "sudo mkdir -p /opt/backup/ /var/log/backup/ /data/backup/ && sudo chown datxbackup.datxbackup /opt/backup/ /var/log/backup/ /data/backup/ -R "
ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@tpc-mysql-mongo-sdc-dev-02 "sudo mkdir -p /opt/backup/ /var/log/backup/ /data/backup/ && sudo chown datxbackup.datxbackup /opt/backup/ /var/log/backup/ /data/backup/ -R "
ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@datx-stg-db01 "sudo mkdir -p /opt/backup/ /var/log/backup/ /data/backup/ && sudo chown datxbackup.datxbackup /opt/backup/ /var/log/backup/ /data/backup/ -R "

```
# create account mysql backup for dc (if new install)

```shell
mysql -u"datadm" -p"5f0D4e60-5bac-4927-b17d-2a8bc1ae4733" -h "localhost"  -e "create user 'mysqlbackup'@'%' IDENTIFIED BY '3mTavkJ3W5Z&QR~W~Duy#rVW';
GRANT Process ON *.* TO 'mysqlbackup'@'%';
GRANT Reload ON *.* TO 'mysqlbackup'@'%';
GRANT Replication client ON *.* TO 'mysqlbackup'@'%';
GRANT Super ON *.* TO 'mysqlbackup'@'%';
REVOKE Usage ON *.* FROM 'mysqlbackup'@'%';
GRANT BACKUP_ADMIN ON *.* TO 'mysqlbackup'@'%';
GRANT Select ON *.* TO 'mysqlbackup'@'%';
GRANT Lock tables ON *.* TO 'mysqlbackup'@'%';
"
```

## crete backup adhoc for 
    ```shell

    # Destination
    server_ip="10.48.15.130"
    hostname="tpc-mysql-mongo-sdc-dev-01"
    env="Development"
    db_type="MySQL"

    server_ip="10.48.15.131"
    hostname="tpc-mysql-mongo-sdc-dev-02"
    env="Development"
    db_type="MySQL"

    # Source
    server_ip="192.168.12.11"
    hostname="datx-stg-db01"
    env="Development"
    db_type="MySQL"

    mkdir -p /opt/backup/adhoc/$server_ip/
    rm -f /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh 
    cp "/opt/backup/backup-mysqldb.sh" "/opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh"
    
    sed -i 's/server_ip="192.168.0.11"/server_ip="'$server_ip'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    sed -i 's/mysqldump -h"${server_ip}"/mysqldump -h"localhost"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh    
    sed -i 's/hostname="datx-db01"/hostname="'$hostname'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    sed -i 's/env="Production"/env="'$env'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    sed -i 's/db_type="MySQL"/db_type="'$db_type'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    sed -i 's/backup full on servers/backup adhoc full on servers/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    sed -i 's/all-database-/adhoc-/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    sed -i '136,137s/^/#/' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    cat /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh

    # copy backup sh file to destination server
    time rsync -avzP -e "ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no" /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh datxbackup@$hostname:/opt/backup/mysql
    # copy key file to source server
    time rsync -avzP -e "ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no" /home/datxbackup/.ssh/id_rsa datxbackup@$hostname:/home/datxbackup/.ssh/
    ```
# Cronjob
## Backup from source
    ```shell
    hostnamesrc="datx-stg-db01"
    time ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@$hostnamesrc "/usr/bin/bash /opt/backup/mysql/backup-adhoc-mysqldb.sh >> /var/log/backup/backup-mysqldb-cronjob.log 2>&1"
    ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@$hostnamesrc "tail /var/log/backup/backup-mysqldb-cronjob.log"


    ```
## transfer file backup to des server
    ```shell
    # in cron server
    hostnamesrc="datx-stg-db01"
    ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@$hostnamesrc 

    hostnamedes="tpc-mysql-mongo-sdc-dev-02" \
    local_backup_path="/data/backup/mysql" \
    backup_file="${local_backup_path}"/adhoc-$(date +2024-06-12_15h21m*).sql.gz \ 
    echo '10.48.15.131    tpc-mysql-mongo-sdc-dev-02' | sudo tee -a /etc/hosts \
    time rsync -avzP -e "ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no" ${backup_file} datxbackup@$hostnamedes:/data/backup/mysql/
    

    ```


# test
    ```shell
    hostnamesrc="datx-stg-db01"
    hostnamesrc="datx-stg-db01"
    ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@$hostnamesrc "hostnamedes="tpc-mysql-mongo-sdc-dev-02" && echo '10.48.15.131    tpc-mysql-mongo-sdc-dev-02'| sudo tee -a /etc/hosts && local_backup_path="/data/backup/mysql" &&  backup_file="${local_backup_path}"/adhoc-2024-06-12_15h20m.sql.gz && time rsync -avzP -e "ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no" ${backup_file} datxbackup@$hostnamedes:/data/backup/mysql/"

    ```
## restore to destination db

    ```shell
    # in cron server
    byobu-screen -DDR va
    hostnamedes="tpc-mysql-mongo-sdc-dev-02"
    local_backup_path="/data/backup/mysql"
    backup_file="${local_backup_path}"/adhoc-$(date +%Y-%m-%d_*).sql.gz
   
    # gunzip file sql
    time ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@$hostnamedes "time gunzip "${backup_file}" "

    backup_user="datadm"
    backup_pass="5f0D4e60-5bac-4927-b17d-2a8bc1ae4733"
    hostnamedes="tpc-mysql-mongo-sdc-dev-01"
    local_backup_path="/data/backup/mysql"
    backup_file="${local_backup_path}"/adhoc-$(date +%Y-%m-%d_*).sql.gz
    ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@$hostnamedes "time mysql -u"${backup_user}" -p"${backup_pass}"  < "${local_backup_path}"/adhoc-$(date +%Y-%m-%d_*).sql"    

    ```


# Check db

```shell
# nơi khai báo ip srv and des
set -x
srv_server_ip="192.168.12.11"
srv_hostname="datx-stg-db01"
des_server_ip="10.48.15.131"
des_hostname="tpc-mysql-mongo-sdc-dev-01"
```
### SOURCE
```shell
    # tạo file runcheck for source
    rm -f /opt/backup/adhoc/$srv_server_ip/run_check.sh 
    cp "/opt/cronicle/sample_backupdb/run_check.sh" "/opt/backup/adhoc/$srv_server_ip/run_check.sh"
    mkdir -p /opt/backup/checkdb/$srv_server_ip/

    cp "/opt/backup/run_check.sh" "/opt/backup/adhoc/$srv_server_ip/run_check.sh"

    # thay đổi thông tin ip srv source
    sed -i 's/server_ip="10.48.15.131"/server_ip="'$srv_server_ip'"/g' /opt/backup/adhoc/$srv_server_ip/run_check.sh
    
    sed -i 's/result.txt/srv_result.txt/g' /opt/backup/adhoc/$srv_server_ip/run_check.sh
    
    # copy file sửa này tơi srv sourve

    time rsync -avzP -e "ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no" /opt/backup/adhoc/$srv_server_ip/run_check.sh datxbackup@$srv_hostname:/opt/backup/mysql/
    

    # run file check source 
    ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@$srv_hostname "/usr/bin/bash /opt/backup/mysql/run_check.sh"

    # get kết quả về tập trung

    time rsync -avzP -e "ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no" datxbackup@$srv_hostname:/opt/backup/mysql/srv_result.txt /opt/backup/checkdb/$srv_server_ip/

    cat /opt/backup/checkdb/$srv_server_ip/srv_result.txt
```

### destination
```shell
    # tạo file runcheck for destination
    rm -f /opt/backup/adhoc/$des_server_ip/run_check.sh 
    cp "/opt/cronicle/sample_backupdb/run_check.sh" "/opt/backup/adhoc/$des_server_ip/run_check.sh"
    mkdir -p /opt/backup/checkdb/$des_server_ip/

    cp "/opt/backup/run_check.sh" "/opt/backup/adhoc/$des_server_ip/run_check.sh"

    # thay đổi thông tin ip srv destination
    sed -i 's/server_ip="10.48.15.131"/server_ip="'$des_server_ip'"/g' /opt/backup/adhoc/$des_server_ip/run_check.sh
    
    sed -i 's/result.txt/des_result.txt/g' /opt/backup/adhoc/$des_server_ip/run_check.sh
    
    # copy file sửa này tơi srv sourve

    time rsync -avzP -e "ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no" /opt/backup/adhoc/$des_server_ip/run_check.sh datxbackup@$srv_hostname:/opt/backup/mysql/
    

    # run file check destination 
    ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@$srv_hostname "/usr/bin/bash /opt/backup/mysql/run_check.sh"

    # get kết quả về tập trung

    time rsync -avzP -e "ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no" datxbackup@$srv_hostname:/opt/backup/mysql/des_result.txt /opt/backup/checkdb/$des_server_ip/

    cat /opt/backup/checkdb/$des_server_ip/des_result.txt



