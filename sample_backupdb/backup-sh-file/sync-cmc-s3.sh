#!/bin/bash
set -x

start_time=$(date +%Y-%m-%d_%Hh%Mm)
server_ip="192.168.0.110"
hostname="datx-backup01"
log_dir="/var/log/backup"
log_file="$log_dir/backup-sync-s3.log"
local_backup_path="/backup"
cmc_s3_backup_path="/mnt/datxbackup/"
cmc_s3_backup_check="/mnt/datxbackup/.keep"
discord_error_webhook="https://discord.com/api/webhooks/1121131006934646946/Ady9uM2tL-aoX1QO8yOePDGvd6V4GfzQUpTc2qDsAs0XwGvt0-0LS-ym7OMONOJGm1Ox"
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
        "name": "Backup Type",
        "value": "Sync to CMC S3",
        "inline": true
      },
      {
        "name": "Start Time",
        "value": "${start_time}",
        "inline": true
      },
      {
        "name": "End Time",
        "value": "$3",
        "inline": true
      }
    ]
  }]
}
EOF
}

#Log started backup
log "Started sync data to CMC Cloud S3"

if [[ -f "$cmc_s3_backup_check" ]]
then
    log "Access to CMC Cloud S3 OK"
else
    end_time=$(date +%Y-%m-%d_%Hh%Mm)
    backup_error_data=$(generate_post_data "Cannot access to CMC Cloud S3" "14177041" "${end_time}")
    curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
    die "Cannot access to CMC S3"
fi

if rsync -avz "$local_backup_path"/* $cmc_s3_backup_path
then
    log "Synced all data file to CMC Cloud S3"
else
    end_time=$(date +%Y-%m-%d_%Hh%Mm)
    backup_error_data=$(generate_post_data "Cannot SYNC dat to CMC Cloud S3" "14177041" "${end_time}")
    curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
    die "Cannot sync data file to CMC S3"
fi

end_time=$(date +%Y-%m-%d_%Hh%Mm)
backup_ok_data=$(generate_post_data "ALL backup file was successfully synced to CMC Cloud S3" "2021216" "${end_time}")
curl -H "Content-Type: application/json" -X POST -d "${backup_ok_data}" "${discord_ok_webhook}"

log "Finished sync data to CMC Cloud S3"