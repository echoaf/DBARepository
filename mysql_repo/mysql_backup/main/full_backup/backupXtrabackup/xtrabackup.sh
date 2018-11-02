#!/bin/bash

basedir="/data/mysql" 

check_user="read_user" # 只读权限
check_pass="read_user"
admin_user="remote_root" # surper权限
admin_pass="remote_root"
repl_user="repl_user" # 复制用户
repl_pass="repl_user"
dump_user="dump_user" # 备份用户
dump_pass="dump_user"

innobackupex="/usr/local/xtrabackup/bin/innobackupex"
mysqld_safe="/usr/local/mysql/bin/mysqld_safe"

mysql="/usr/bin/dba/mysql" && chmod a+x $mysql || exit 64
dirname="/tmp/backupXtrabackup"
source $dirname/function_xtraback.cnf || exit 64


function printLog()
{
    content="$1"
    normal_log="$2"
    color="$3"
    if [ -z "$normal_log" ];then
        normal_log="/tmp/shell.log"
    fi
    if [ -z "$color" ];then
        color="normal"
    fi
    echo "[$(date +"%F %T")] $content" >>$normal_log 2>&1
    case "$color" in
        green) echo -e "[`date +"%F %T"`] \033[32m$content \033[0m";;
        red) echo -e "[`date +"%F %T"`] \033[31m$content \033[0m";;
        normal) echo -e "[`date +"%F %T"`] $content";;
        *) echo -e "[`date +"%F %T"`] \033[32m$content \033[0m";;
    esac
}


function main()
{
    if (($#<=8)); then
        printLog "参数错误" 
        exit 64
    fi

    master_host="$1"
    master_port="$2"
    master_ssh_port="$3"
    local_host="$4"
    local_port="$5"
    local_ssh_port="$6"
    backupdir="$7"
    innodb_buff="$8"
    is_backup="$9"
    if [ -z "$is_backup" ];then
        is_backup="YES"
    fi
    tmp=$(echo "$is_backup"| tr 'a-z' 'A-Z')
    if [ "$tmp" == "YES" ];then
        is_check="YES"
    else
        is_check="NO"
    fi

    master_my_cnf="$basedir/$master_port/my.cnf"
    my_cnf="$dirname/my.cnf"
    normal_log="/tmp/backupXtrabackup/shell_$(date +"%Y%m%d").log"

    # 备份检测
    xtrabackupCheck $master_host $master_ssh_port $local_host $local_ssh_port $backupdir $normal_log "$is_check"
    if (($?!=0));then
        exit 64
    fi

    # 还原检测
    restoreXtrabackupCheck "$local_host" "$local_port" "$backupdir" "$normal_log" "$is_check"
    if (($?!=0));then
        exit 64
    fi

    tmp=$(echo "$is_backup"| tr 'a-z' 'A-Z')
    if [ "$tmp" == "YES" ];then
        # 备份
        xtrabackupBackup "$master_host" "$master_port" "$master_ssh_port" "$master_my_cnf" "$local_host" "$local_ssh_port" "$backupdir" "Y" "$normal_log"
        if (($?!=0));then
            exit 64
        fi
    else
        printLog "已存在备份集"
    fi

    # 结果集检测
    xtrabackupResultCheck "$backupdir"
    if (($?!=0));then
        exit 64
    fi

    # 还原
    restoreXtrabackup $master_host $master_port $slave_host $slave_port $backupdir $innodb_buff $my_cnf $normal_log 
    if (($?!=0));then
        exit 64
    fi
    
}


main "$@"
