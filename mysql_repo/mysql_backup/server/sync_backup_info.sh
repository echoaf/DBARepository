#!/bin/bash

# description:同步备份信息表
# arthur
# 2018-10-16

base_dir="/data/repository/mysql_repo/mysql_backup"
common_dir="$base_dir/common"
shell_cnf="$common_dir/shell.cnf"
source $shell_cnf

f_name=$(basename "$0")

function getMBInstance()
{
    sql="select concat(Ftype,'--',Fserver_host,'--',Fserver_port) from $t_mysql_info where Fstate='online' and Frole='MasterBackup';"
    values=$($DBA_MYSQL -e "$sql" -N)
    if (($?!=0));then
        printLog "执行sql失败:$values"
        exit 64
    fi
    echo "$values"
}


function syncFull()
{
    instance="$1"
    host="$2"
    port="$3"
    sql="select count(*) from $t_mysql_fullbackup_info where Ftype='$instance';"
    cnt=$(echo "$sql"| $DBA_MYSQL)
    if ((${cnt}==0));then
        sql="insert into $t_mysql_fullbackup_info (Ftype,Fbackup_address,Fdata_source,Fbackup_mode,Fbackup_weekday,Fstart_time,Fend_time,Fclear_rule,Fmemo,Fstate,Fcreate_time,Fmodify_time) values ('$instance','$host','${host}:${port}','xtrabackup','$tommorow_week','00:00:01','08:00:00','0-7-365-3650','第一次上报','wait_online',now(),now());"
        printLog "[$f_name]start config $instance to $host:$port." "$normal_log"
        printLog "[$f_name]$sql" "$normal_log"
        echo "$sql" | $DBA_MYSQL
    fi
    
}


function main()
{
    printLog "[$f_name]start sync info." "$normal_log"
    tommorow_week=$(date -d '1 days' "+%w")
    mbinfos=$(getMBInstance)
    for mbinfo in $(echo "$mbinfos")
    do
        instance=$(echo "$mbinfo"| awk -F"--" '{print $1}')
        host=$(echo "$mbinfo"| awk -F"--" '{print $2}')
        port=$(echo "$mbinfo"| awk -F"--" '{print $3}')
        syncFull "$instance" "$host" "$port"
    done
    printLog "[$f_name]end sync info." "$normal_log"
}


main "$@"
