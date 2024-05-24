#!/usr/bin/env bash

VERBOSE=1
start_time=$(date +%Y-%m-%d_%Hh%Mm)
end_time=""
server_ip="192.168.2.6"
hostname="datx-git01"
discord_error_webhook="https://discord.com/api/webhooks/1121131006934646946/Ady9uM2tL-aoX1QO8yOePDGvd6V4GfzQUpTc2qDsAs0XwGvt0-0LS-ym7OMONOJGm1Ox"
discord_ok_webhook="https://discord.com/api/webhooks/1136571040013750423/1IgNHredddX5aH2t2e_TbQfH98b1esOhuGNyTga2oDE0JICLU_tEEPifec_O_aJVx3bG"
log_dir="/var/log/backup"
log_file="$log_dir/backup-gitlab.log"

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
log "Started backup"
mkdir -p "${log_dir}"

##
## usage [SUBCOMMAND]
##
##   Prints out SUBCOMMAND usage and exits with code `0`. Prints the general
##   usage when SUBCOMMAND is missing.
##
usage() {
  case "${1}" in
    create)
      echo 'Usage: gitlab-backup create [OPTIONS]'
      echo
      echo "  Create a new backup. Wrapper for \`gitlab-rake gitlab:backup:create\`."
      echo
      echo 'OPTIONS:'
      echo
      echo '  -h, --help    Display this help message and exits,'
      echo
      echo '  Additional OPTIONS are passed to the underlying command.'
      ;;
    restore)
      echo 'Usage: gitlab-backup restore [OPTIONS]'
      echo
      echo "  Restore from a backup. Wrapper for \`gitlab-rake gitlab:backup:restore\`."
      echo
      echo '  Automatically changes the ownership of registry directory (when enabled)'
      echo '  to ensure filesytem permissions are correct.'
      echo
      echo 'OPTIONS:'
      echo
      echo '  -h, --help    Display this help message and exits.'
      echo
      echo '  Additional OPTIONS passed to the underlying command.'
      ;;
    *)
      echo 'Usage: gitlab-backup COMMAND [OPTIONS]'
      echo
      echo 'OPTIONS:'
      echo
      echo "  -h, --help    Display this help message and exits. Use \`COMMAND --help\`"
      echo '                for more information on a command.'
      echo
      echo 'COMMANDS:'
      echo '  create        Creates a new backup.'
      echo '  restore       Restores from a backup.'
      ;;
  esac
  exit 0
}

##
## chown_registry USER
##
##   Transfers ownership of registry directory to USER.
##
chown_registry() {
  [ ${VERBOSE} -gt 0 ] && printf 'Transfering ownership of %s to %s\n' "${registry_dir}" "${1}"
  chown -R "${1}" "${registry_dir}"
}

##
## backup_create ARGS 
##
##   Calls `gitlab-rake gitlab:backup:create` and passess ARGS to it.
##
backup_create() {

  # Print usage if help flag is present.
  case "${1}" in
    -h|--help)
      shift
      usage 'create'
      ;;
    *)
      ;;
  esac

  /opt/gitlab/bin/gitlab-rake gitlab:backup:create ${@}
}

##
## backup_restore ARGS 
##
##   Calls `gitlab-rake gitlab:backup:restore` and passess ARGS to it. Also,
##   registers hooks to change ownership of registry directory before and 
##   after restore.
##
backup_restore() {

  # Print usage if help flag is present.
  case "${1}" in
    -h|--help)
      shift
      usage 'restore'
      ;;
    *)
      ;;
  esac

  if [ -n "${registry_dir}" ]; then
    # Transfer ownership to git user to ensure that recovery won't fail on 
    # the existing registry
    chown_registry ${gitlab_user}

    # Transfer ownership back to registry user when restore task is finished.
    trap "chown_registry ${registry_user}" EXIT
  fi

  /opt/gitlab/bin/gitlab-rake gitlab:backup:restore ${@}
}

# Load gitlab-rails-rc
gitlab_rails_rc='/opt/gitlab/etc/gitlab-rails-rc'
if ! [ -f ${gitlab_rails_rc} ] ; then
  >&2 echo "${0} error: could not load ${gitlab_rails_rc}"
  >&2 echo 'Either you are not allowed to read the file, or it does not exist yet.'
  >&2 echo "You can generate it with \`sudo gitlab-ctl reconfigure\`"
  exit 2
fi

. ${gitlab_rails_rc}

# Parse general options and sub-command.
while (( "${#}" )); do
  case "${1}" in
    -h|--help)
      shift
      usage
      ;;
    --)
      shift
      break
      ;;
    -*|--*)
      >&2 echo "Unsupported option: ${1}"
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

subcommand=${1:-create}
shift

# Run subcommand
case "${subcommand}" in
  create)
    backup_create ${@}
    ;;
  restore)
    backup_restore ${@}
    ;;
  *)
    >&2 echo "Unknown command: ${subcommand}"
    exit 1
    ;;
esac

if $? -ne 0
then
  end_time=$(date +%Y-%m-%d_%Hh%Mm)
  backup_error_data=$(generate_post_data "Backup failed. No gitlab backup file on server ${server_ip} was created! \n" "14177041" "${end_time}")
  curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
  die "Backup failed. No gitlab backup file on server ${server_ip} was created! \n"
fi
log "Gitlab backup done."

#sync backup
if /usr/bin/rsync -avz /var/opt/gitlab/backups/* datxbackup@192.168.0.110:/backup/gitlab/
then
  log "Local backup file sended"
else
  end_time=$(date +%Y-%m-%d_%Hh%Mm)
  backup_error_data=$(generate_post_data "No Gitlab backup file on servers ${server_ip} was synded!" "14177041" "${end_time}")
  curl -H "Content-Type: application/json" -X POST -d "${backup_error_data}" "${discord_error_webhook}"
  die "No Gitlab backup file on servers ${server_ip} was synded! \n"
fi

end_time=$(date +%Y-%m-%d_%Hh%Mm)
backup_ok_data=$(generate_post_data "Gitlab backup full on servers ${server_ip} was successfully created" "2021216" "${end_time}")
curl -H "Content-Type: application/json" -X POST -d "${backup_ok_data}" "${discord_ok_webhook}"
