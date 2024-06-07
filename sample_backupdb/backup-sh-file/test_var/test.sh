server_ip="10.48.15.131"
hostname="tpc-mysql-dev02"
env="Development"
db_type="MySQL"
local_backup_path="/data/backup/mysql"
discord_error_webhook="https://discordapp.com/api/webhooks/1199528077328384020/F_9iGgoF_a5VeE5F5UHJO8NtiL-ib-2u6N3HgHKlyDLYKAk6MNN5T-XuEjgzQxqw-m26"
discord_ok_webhook="https://discord.com/api/webhooks/1136571040013750423/1IgNHredddX5aH2t2e_TbQfH98b1esOhuGNyTga2oDE0JICLU_tEEPifec_O_aJVx3bG"
remote_backup_path="${remote_backup_ip}::database/${server_ip}/"
backup_file="${local_backup_path}"/adhoc-$(date +%Y-%m-%d_%Hh%Mm).sql.gz
keep_day=2
backup_file_size=0
file_size_min=1000
backup_user="mysqlbackup"
backup_pass="3mTavkJ3W5Z&QR~W~Duy#rVW"
log_dir="/var/log/backup"
log_file="$log_dir/backup-mysqldb.log"
dbname=""

ARGV="$@"
 if [ "x$ARGV" = "x" ] ; then
     ARGS="--all-databases"
     else
     ARGS=$ARGV
 fi
dbname=$ARGS
echo $dbname
log $dbname

mysqldump -h "${server_ip}"  -u "${backup_user}" -p"${backup_pass}" --databases $dbname | gzip > "${backup_file}"
#mysqldump -h 10.48.15.131 -u mysqlbackup '-p3mTavkJ3W5Z&QR~W~Duy#rVW' --databases datx_mautic_dev | gzip > adhoc.gz.zip