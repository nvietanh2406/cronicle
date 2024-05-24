#!/bin/bash
set -x
# constant var
start_time=$(date +%Y-%m-%d_%Hh%Mm)
end_time=""
server_ip="192.168.0.110"
hostname="datx-backup01"
env="prod"
db_type="RabbitMQ"
local_backup_path="/backup/middleware/rabbitmq/data"
discord_error_webhook="https://discord.com/api/webhooks/1121131006934646946/Ady9uM2tL-aoX1QO8yOePDGvd6V4GfzQUpTc2qDsAs0XwGvt0-0LS-ym7OMONOJGm1Ox"
discord_ok_webhook="https://discord.com/api/webhooks/1136571040013750423/1IgNHredddX5aH2t2e_TbQfH98b1esOhuGNyTga2oDE0JICLU_tEEPifec_O_aJVx3bG"

backup_file="${local_backup_path}/${env}/${env}-rabbitmq-config-$(date +%Y%m%d%H%M%S).json"
backup_file_size=0
file_size_min=1000
log_dir="/var/log/backup"
log_file="$log_dir/backup-rabbitmq.log"

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
        "value": "$5",
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

#Log started backup
log "Started backup"

#create backup folder
mkdir -p ${local_backup_path} ${log_dir}

#backup rabbitmq prod
env="prod"
backup_file="${local_backup_path}/${env}/${env}-rabbitmq-config-$(date +%Y%m%d%H%M%S).json"
if /usr/bin/rabbitmqadmin -u admin -p 'j@kPkm25h$3A2^dl' -H 10.0.129.22 -P 32024 export "${backup_file}"
then
  backup_file_size=$(wc -c "${backup_file}"| awk '{ print $1}')
  if [[ ${backup_file_size} -lt ${file_size_min} ]]
  then
    end_time=$(date +%Y-%m-%d_%Hh%Mm)
    backup_error_data=$(generate_post_data ${env} "${db_type} backup file size on server ${server_ip} is too small!!!" "14177041" "${backup_file_size}" "${end_time}" "prod")
    curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
    die "Backup failed. ${env} ${db_type} backup file size on server ${server_ip} is too small \n"
  fi
else
  end_time=$(date +%Y-%m-%d_%Hh%Mm)
  backup_error_data=$(generate_post_data "No ${env} ${db_type} backup file on server ${server_ip} was created!" "14177041" "${backup_file_size}" "${end_time}" "prod")
  curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
  die "Backup failed. No ${env} ${db_type} backup file on server ${server_ip} was created! \n"
fi

backup_file_size=$(du -hs "${backup_file}"| awk '{ print $1}')
end_time=$(date +%Y-%m-%d_%Hh%Mm)
backup_ok_data=$(generate_post_data "${env} ${db_type} backup full on servers ${server_ip} was successfully created" "2021216" "${backup_file_size}" "${end_time}" "prod")
curl -H "Content-Type: application/json" -X POST -d "${backup_ok_data}" "${discord_ok_webhook}"

log "backup RabbitMQ on ${env} DONE"

#backup rabbitmq dev
env="dev"
backup_file="${local_backup_path}/${env}/${env}-rabbitmq-config-$(date +%Y%m%d%H%M%S).json"
if /usr/bin/rabbitmqadmin -u admin -p 'Dat@2023' -H 10.0.1.22 -P 32024 export "${backup_file}"
then
  backup_file_size=$(wc -c "${backup_file}"| awk '{ print $1}')
  if [[ ${backup_file_size} -lt ${file_size_min} ]]
  then
    end_time=$(date +%Y-%m-%d_%Hh%Mm)
    backup_error_data=$(generate_post_data "${env} ${db_type} backup file size on server ${server_ip} is too small!!!" "14177041" "${backup_file_size}" "${end_time}" "dev")
    curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
    die "Backup failed. ${env} ${db_type} backup file size on server ${server_ip} is too small \n"
  fi
else
  end_time=$(date +%Y-%m-%d_%Hh%Mm)
  backup_error_data=$(generate_post_data "No ${env} ${db_type} backup file on server ${server_ip} was created!" "14177041" "${backup_file_size}" "${end_time}" "dev")
  curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
  die "Backup failed. No ${env} ${db_type} backup file on server ${server_ip} was created! \n"
fi

backup_file_size=$(du -hs "${backup_file}"| awk '{ print $1}')
end_time=$(date +%Y-%m-%d_%Hh%Mm)
backup_ok_data=$(generate_post_data "${env} ${db_type} backup full on servers ${server_ip} was successfully created" "2021216" "${backup_file_size}" "${end_time}" "dev")
curl -H "Content-Type: application/json" -X POST -d "${backup_ok_data}" "${discord_ok_webhook}"
log "backup RabbitMQ on ${env} DONE"
