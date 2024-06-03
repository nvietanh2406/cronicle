# I. Config and setup backup database with cronicle

## Copy server ssh-key
```shell
rm /home/datxbackup/.ssh -rf
sudo useradd -m 'datxbackup' -s /bin/bash
sudo usermod -p "$(openssl passwd -1 Abcd@1234$)" datxbackup
sudo mkdir -p /home/datxbackup/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVaV+4oJHIRSbEMHuWQ2bA0ta1S+W+dB53jQf3dto35AOoqRJgLiLMhVP9fGQPh+unb+3CUZl8bFZWFxHfFs4FZV+0ttCMgmRxc8n0Oegdb86dEko8/zDnHEG3bjhUzwciWzvn7FJ4ChYq9jWJC8jkiTpTZDMibtAdo5tTWFtFHB+B6b2D3JH1/GxZzJ0PxT7tZ9HES0+FMVvFFMI5BzhXjdYuHIkAdjhP6UPv0uAmEWncWvQYAgYq7Oz5vAWcprVKY9BRjBx0ThmWfZXAhNYwUaaguoCSlwMpckwcjjFFf7O70F1rZulGG+PvhghDMrUYgASl0lwE2t6yBrKZZmpUGY0xp8dqKYWQHbG1sd1Kv+Nau7usl8xttwTrVLBTGeql78Dv7a1aThzQGy6v7JiGcyE9jwUXSjC/K3ObFABpYsV8iIRCpgag1jJUfeOdy2JZHf2EPvFddcNJa6IxccR7j3qowvlHJ/9DG0r65B6B8yNeue/7BGUW/OXlWU3wHqTeovNAopCZupNrwtTJPkqhtLAqBS6q4pUtJPw0EfRaBuSWiR7T8UknmtnZ/C5OvJxekwPEz9O6aYWvRaQyp+wxT+KY9Gk1Jxymh3tHkx56y55sazVBjnTSTadJzPL0Ri6Z50Q79tWiJV2gHN8hR6jcAyxeNXhltsFDuMvRDNuoMQ== datxbackup@datx.com.vn' |sudo tee -a /home/datxbackup/.ssh/authorized_keys
sudo chown -R datxbackup:datxbackup /home/datxbackup/.ssh
sudo chmod 600 /home/datxbackup/.ssh/authorized_keys
echo "datxbackup ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

cp /opt/temp/id_rsa* /home/datxbackup/.ssh/
chmod 400 /home/datxbackup/.ssh/id_rsa
eval "$(ssh-agent -s)"
ssh-add /home/datxbackup/.ssh/id_rsa
```
## add host to server ssh-key
```shell
echo '10.48.15.131    tpc-mysql-dev02'| sudo tee -a /etc/hosts
```
## Copy client ssh-key

```shell
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVaV+4oJHIRSbEMHuWQ2bA0ta1S+W+dB53jQf3dto35AOoqRJgLiLMhVP9fGQPh+unb+3CUZl8bFZWFxHfFs4FZV+0ttCMgmRxc8n0Oegdb86dEko8/zDnHEG3bjhUzwciWzvn7FJ4ChYq9jWJC8jkiTpTZDMibtAdo5tTWFtFHB+B6b2D3JH1/GxZzJ0PxT7tZ9HES0+FMVvFFMI5BzhXjdYuHIkAdjhP6UPv0uAmEWncWvQYAgYq7Oz5vAWcprVKY9BRjBx0ThmWfZXAhNYwUaaguoCSlwMpckwcjjFFf7O70F1rZulGG+PvhghDMrUYgASl0lwE2t6yBrKZZmpUGY0xp8dqKYWQHbG1sd1Kv+Nau7usl8xttwTrVLBTGeql78Dv7a1aThzQGy6v7JiGcyE9jwUXSjC/K3ObFABpYsV8iIRCpgag1jJUfeOdy2JZHf2EPvFddcNJa6IxccR7j3qowvlHJ/9DG0r65B6B8yNeue/7BGUW/OXlWU3wHqTeovNAopCZupNrwtTJPkqhtLAqBS6q4pUtJPw0EfRaBuSWiR7T8UknmtnZ/C5OvJxekwPEz9O6aYWvRaQyp+wxT+KY9Gk1Jxymh3tHkx56y55sazVBjnTSTadJzPL0Ri6Z50Q79tWiJV2gHN8hR6jcAyxeNXhltsFDuMvRDNuoMQ== datxbackup@192.168.0.11' |sudo tee -a /home/datxbackup/.ssh/authorized_keys
```
### delete esitx key (if need)
```shell
truncate -s 0 /home/datxbackup/.ssh/authorized_keys
```
# connect via private key
```shell
ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@tpc-mysql-dev02
```
# config backup target server need backup
```shell
ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@tpc-mysql-dev02 "sudo mkdir -p /opt/backup/ /var/log/backup/ /data/backup/ && sudo chown datxbackup. /opt/backup/ /var/log/backup/ /data/backup/ -R "
```
# create account db backup  
```shell
mysql -u"datadm" -p"5f0D4e60-5bac-4927-b17d-2a8bc1ae4733" -h 10.48.15.130  -e "create user 'mysqlbackup'@'%' IDENTIFIED BY '3mTavkJ3W5Z&QR~W~Duy#rVW';"
```
# II. create file temp and change server
## Mysql
### backup adhoc for 
    ```shell
    server_ip="10.48.15.131"
    hostname="tpc-mysql-dev02"
    env="Development"
    db_type="MySQL"

    mkdir -p /opt/backup/adhoc/$server_ip/
    rm -f /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh 
    cp "/opt/backup/backup-mysqldb.sh" "/opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh"
    sed -i 's/server_ip="192.168.0.11"/server_ip="'$server_ip'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    sed -i 's/hostname="datx-db01"/hostname="'$hostname'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    sed -i 's/env="Production"/env="'$env'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    sed -i 's/db_type="MySQL"/db_type="'$db_type'"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    sed -i 's/backup full on servers/backup adhoc full on servers/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    #sed -i 's/"if rsync -avz $local_backup_path $remote_backup_pat"/"echo "backup addhoc for golive""/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    #sed -i 's/"Local backup file sended"/"Backup addhoc for golive"/g' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    
    sed -i '136,137s/^/#/' /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh
    ```
# copy backup sh file to destination server

```shell
    time rsync -avzP -e ssh -i /home/datxbackup/.ssh/id_rsa /opt/backup/adhoc/$server_ip/backup-adhoc-mysqldb.sh datxbackup@$hostname:/opt/backup/mysql

```
# III. add evente backup run on cronicle

```shell
    su datxbackup && /opt/backup/mysql

```
### add manual cronicle even
```shell
ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@tpc-mysql-dev02 "/usr/bin/bash /opt/backup/mysql/backup-adhoc-mysqldb.sh >> /var/log/backup/backup-mysqldb-cronjob.log 2>&1"

ssh -i /home/datxbackup/.ssh/id_rsa -o StrictHostKeyChecking=no datxbackup@tpc-mysql-dev02 "tail /var/log/backup/backup-mysqldb-cronjob.log"


 
```
# IV. check db before store
## setup server check (cron) get git repo
```shell
    cd /opt/ &&
    git clone https://github.com/nvietanh2406/cronicle.git &&
    mkdir -p /opt/backup/adhoc /opt/backup/checkdb
    
```
## setup even with bash plugin 
Before running, make sure to have the ssh key and update the hosts file
Copy and paste in Plugin shell in cronicle
```shell
# nơi khai báo ip srv and des
set -x
srv_server_ip="10.48.15.131"
srv_hostname="tpc-mysql-dev02"
des_server_ip="10.48.15.131"
des_hostname="tpc-mysql-dev02"
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
```
