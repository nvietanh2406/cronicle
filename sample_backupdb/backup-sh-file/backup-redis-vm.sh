#!/bin/bash
set -x

# constant var
start_time=$(date +%Y-%m-%d_%Hh%Mm)
end_time=""
#Local backup VM info
db_type="redis"
server_ip=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
host_name=$(hostname -s)
env="dev"
local_backup_path="/data/backup/redis"
backup_file="${local_backup_path}"/${env}-dump-$(date +%Y-%m-%d_%Hh%Mm).rdb
backup_file_gzip="${local_backup_path}"/${env}-dump-$(date +%Y-%m-%d_%Hh%Mm).rdb.gz
#Remote Backup VM
remote_backup_ip="192.168.0.110"
remote_backup_user="datxbackup"
remote_backup_path="/backup/middleware/${db_type}/${env}/${server_ip}"
#Redis Info
auth_pass="tpWDHUF2Lucjftuut2PQrKvh"
keep_day=10
backup_file_size=0
file_size_min=1000
log_dir="/var/log/backup"
log_file="$log_dir/backup-redis.log"
#Alert info
discord_error_webhook="https://discordapp.com/api/webhooks/1199528077328384020/F_9iGgoF_a5VeE5F5UHJO8NtiL-ib-2u6N3HgHKlyDLYKAk6MNN5T-XuEjgzQxqw-m26"
discord_ok_webhook="https://discord.com/api/webhooks/1136571040013750423/1IgNHredddX5aH2t2e_TbQfH98b1esOhuGNyTga2oDE0JICLU_tEEPifec_O_aJVx3bG"

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
        "name": "host_name",
        "value": "${host_name}",
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

#create backup folder
mkdir -p ${local_backup_path} ${log_dir}
# Save data from mem to dis on redis
if /usr/bin/redis-cli -a "${auth_pass}" save
then
  log "Redis save data on ${env} done."
else
  end_time=$(date +%Y-%m-%d_%Hh%Mm)
  backup_error_data=$(generate_post_data "No ${db_type} backup file on servers ${server_ip} was created!" "14177041" "0" "${end_time}")
  curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
  die "Redis save data on ${env} failed. No ${db_type} data file on  ${env} was created! \n"
fi

#Backup Redis
if cp /var/lib/redis/dump.rdb "${backup_file}"
then
  # Gzip data file
  /usr/bin/gzip -v9 "${backup_file}"
  backup_file_size=$(wc -c "${backup_file_gzip}"| awk '{ print $1}')
  if [[ ${backup_file_size} -lt ${file_size_min} ]]
  then
    end_time=$(date +%Y-%m-%d_%Hh%Mm)
    backup_error_data=$(generate_post_data "${db_type} backup file size on servers ${server_ip} is too small!!!" "14177041" "${backup_file_size}" "${end_time}")
    curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
    die "Backup failed. ${env} ${db_type} backup file size on server ${server_ip} is too small!!! \n"
  fi
else
  end_time=$(date +%Y-%m-%d_%Hh%Mm)
  backup_error_data=$(generate_post_data "No ${db_type} backup file on servers ${server_ip} was created!" "14177041" "${backup_file_size}" "${end_time}")
  curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
  die "Backup failed. No [${env}] ${db_type} backup file on server ${server_ip} was created! \n"
fi

# Delete old backups
find "${local_backup_path}"/ -mtime +$keep_day -delete

# Create remote backup dir
if ssh "${remote_backup_user}"@"${remote_backup_ip}" "mkdir -p ${remote_backup_path}"
then
  log "Created remote backup dir"
else
  end_time=$(date +%Y-%m-%d_%Hh%Mm)
  backup_file_size=$(du -hs "${backup_file_gzip}"| awk '{ print $1}')
  backup_error_data=$(generate_post_data "Cannot create remote backup dir on VM ${remote_backup_ip}" "14177041" "${backup_file_size}" "${end_time}")
  curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
  die "Cannot create remote backup dir on VM ${remote_backup_ip} \n"
fi

# Local and remote storage sync
if rsync -avh "$backup_file_gzip" "${remote_backup_user}"@"${remote_backup_ip}":"${remote_backup_path}"/
then
  log "Local backup file sended"
else
  end_time=$(date +%Y-%m-%d_%Hh%Mm)
  backup_file_size=$(du -hs "${backup_file_gzip}"| awk '{ print $1}')
  backup_error_data=$(generate_post_data "No ${db_type} VM backup file on servers ${server_ip} was synded!" "14177041" "${backup_file_size}" "${end_time}")
  curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
  die "No [${env}] ${db_type} backup file on servers ${server_ip} was synded! \n"
fi

backup_file_size=$(du -hs "${backup_file_gzip}"| awk '{ print $1}')
end_time=$(date +%Y-%m-%d_%Hh%Mm)
backup_ok_data=$(generate_post_data "[${env}] ${db_type} VM backup full on servers ${server_ip} was successfully created" "2021216" "${backup_file_size}" "${end_time}")
curl -H "Content-Type: application/json" -X POST -d "${backup_ok_data}" "${discord_ok_webhook}"

#Log finished backup
log "Finished backup Redis on ${env} \n"