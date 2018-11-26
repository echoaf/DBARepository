#!/bin/bash


#pwd=$()

cwd=$(cd $(dirname $0);pwd)
log=$(cd $cwd && cd ../log && pwd)
mkdir -p $log

# 备份计划任务
crontab_backup_file="$log/crontab_$(date +"%Y%m%d_%H%M%S").log"
crontab -l >>$crontab_backup_file

# 清除老的计划任务
(crontab -l | grep -v 'monitor监控') | crontab
(crontab -l | grep -v "cd $cwd && sh monitor_cron.sh") | crontab

# 添加计划任务
(crontab -l; echo -e "\n# monitor监控 | $(date +"%F %T")\n*/1 * * * * cd $cwd && sh monitor_cron.sh >>${log}/monitor_cron.log 2>&1\n") | crontab

