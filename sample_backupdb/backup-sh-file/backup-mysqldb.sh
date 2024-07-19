#!/bin/bash
set -x

# constant var
start_time=$(date +%Y-%m-%d_%Hh%Mm)
end_time=""
server_ip="192.168.0.11"
hostname="datx-db01"
env="Production"
db_type="MySQL"
local_backup_path="/data/backup/mysql"
discord_error_webhook="https://discordapp.com/api/webhooks/1199528077328384020/F_9iGgoF_a5VeE5F5UHJO8NtiL-ib-2u6N3HgHKlyDLYKAk6MNN5T-XuEjgzQxqw-m26"
discord_ok_webhook="https://discord.com/api/webhooks/1136571040013750423/1IgNHredddX5aH2t2e_TbQfH98b1esOhuGNyTga2oDE0JICLU_tEEPifec_O_aJVx3bG"
remote_backup_path="${remote_backup_ip}::database/${server_ip}/"
backup_file="${local_backup_path}"/all-database-$(date +%Y-%m-%d_%Hh%Mm).sql.gz
keep_day=2
backup_file_size=0
file_size_min=1000
backup_user="mysqlbackup"
backup_pass="3mTavkJ3W5Z&QR~W~Duy#rVW"
log_dir="/var/log/backup"
log_file="$log_dir/backup-mysqldb.log"
dbname=""

# constant var MySQL
mysql_host="localhost"
mysql_user="your_mysql_user"
mysql_password="your_mysql_password"
mysql_database="backupdb"
mysql_table="backup_logs"


# Declaration function
log() {
        if [ -n "$1" ]
        then
                IN="$1"
        else
                read IN
        fi
        DateTime=$(date "+%Y/%m/%d %H:%M:%S")
        echo -e "${DateTime}\t${IN}" >> "$log_file"
}

die() {
        log "ERROR: $1"
        exit 1
}

#OK: 2021216
#NOK: 14177041


# Seting database need backup parameter

ARGV="$@"
 if [ "x$ARGV" = "x" ] ; then 
     ARGS="--all-databases"
     else
     ARGS="--databases $ARGV"
 fi
dbname=$ARGS
echo $dbname
log $dbname

function generate_post_data {
    cat <<EOF
{
  "avatar_url": "https://i.imgur.com/oBPXx0D.png",
  "content": "$1",
  "embeds": [{
    "color": "$2",
    "title": "Server Information",
    "fields":[
      {
        "name": "Enviroment",
        "value": "${env}",
        "inline": true
      },
      {
        "name": "IP Address",
        "value": "${server_ip}",
        "inline": true
      },
      {
        "name": "Hostname",
        "value": "${hostname}",
        "inline": true
      },
      {
        "name": "DB Type",
        "value": "${db_type}",
        "inline": true
      },
      {
        "name": "Start Time",
        "value": "${start_time}",
        "inline": true
      },
      {
        "name": "End Time",
        "value": "$4",
        "inline": true
      },
      {
        "name": "Local backup file",
        "value": "${backup_file}",
        "inline": false
      },
      {
        "name": "Local backup file size",
        "value": "$3",
        "inline": false
      }
    ]
  }]
}
EOF
}

# Hàm kiểm tra kết nối MySQL và tạo DB/bảng nếu chưa tồn tại
check_and_create_mysql() {
    if mysql -h "$mysql_host" -u "$mysql_user" -p"$mysql_password" -e "USE $mysql_database;" 2>/dev/null; then
        echo "Database $mysql_database đã tồn tại."
    else
        echo "Tạo database $mysql_database..."
        mysql -h "$mysql_host" -u "$mysql_user" -p"$mysql_password" -e "CREATE DATABASE $mysql_database;"
    fi

    if mysql -h "$mysql_host" -u "$mysql_user" -p"$mysql_password" "$mysql_database" -e "DESCRIBE $mysql_table;" 2>/dev/null; then
        echo "Bảng $mysql_table đã tồn tại."
    else
        echo "Tạo bảng $mysql_table..."
        mysql -h "$mysql_host" -u "$mysql_user" -p"$mysql_password" "$mysql_database" << EOF
CREATE TABLE $mysql_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    backup_file VARCHAR(255),
    file_size VARCHAR(50),
    start_time DATETIME,
    end_time DATETIME,
    server_ip VARCHAR(15),
    hostname VARCHAR(255),
    env VARCHAR(50),
    db_type VARCHAR(50)
);
EOF
    fi
}

#Log started backup
log "Started backup"

#create backup folder
mkdir -p ${local_backup_path} ${log_dir}

# Create a backup
if mysqldump -h"${server_ip}"  -u"${backup_user}" -p "${backup_pass}" --all-databases |gzip > "${backup_file}"
then
  backup_file_size=$(wc -c "${backup_file}"| awk '{ print $1}')
  if [[ ${backup_file_size} -lt ${file_size_min} ]]
  then
    end_time=$(date +%Y-%m-%d_%Hh%Mm)
    backup_error_data=$(generate_post_data "${db_type} backup file size on server ${server_ip} is too small!!!" "14177041" "${backup_file_size}" "${end_time}")
    curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
    die "Backup failed. ${db_type} backup file size on server ${server_ip} is too small \n"
  fi
else
  end_time=$(date +%Y-%m-%d_%Hh%Mm)
  backup_error_data=$(generate_post_data "No ${db_type} backup file on server ${server_ip} was created!" "14177041" "${backup_file_size}" "${end_time}")
  curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
  die "Backup failed. No ${db_type} backup file on server ${server_ip} was created! \n"
fi

# Delete old backups
find $local_backup_path -mtime +$keep_day -delete

# Local and remote storage sync
if 
  #rsync -avz $local_backup_path $remote_backup_path
  echo "backup adhoc for golive"
then
  log "backup adhoc for golive"
else
  end_time=$(date +%Y-%m-%d_%Hh%Mm)
  backup_file_size=$(du -hs "${backup_file}"| awk '{ print $1}')
  backup_error_data=$(generate_post_data "No ${db_type} backup file on servers ${server_ip} was synded!" "14177041" "${backup_file_size}" "${end_time}")
  curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
  die "No ${db_type} backup file on servers ${server_ip} was synded! \n"
fi

backup_file_size=$(du -hs "${backup_file}"| awk '{ print $1}')
end_time=$(date +%Y-%m-%d_%Hh%Mm)
backup_ok_data=$(generate_post_data "${db_type} backup full on servers ${server_ip} was successfully created" "2021216" "${backup_file_size}" "${end_time}")
curl -H "Content-Type: application/json" -X POST -d "${backup_ok_data}" "${discord_ok_webhook}"

# Hàm insert thông tin backup vào MySQL
insert_backup_info() {
    mysql -h "$mysql_host" -u "$mysql_user" -p"$mysql_password" "$mysql_database" << EOF
INSERT INTO $mysql_table 
(backup_file, file_size, start_time, end_time, server_ip, hostname, env, db_type)
VALUES 
('$backup_file', '$backup_file_size', '$start_time', '$end_time', '$server_ip', '$hostname', '$env', '$db_type');
EOF
}

# Kiểm tra và tạo DB/bảng nếu cần
check_and_create_mysql

# Insert thông tin backup
insert_backup_info

#Log finished backup
log "Finished backup \n"
