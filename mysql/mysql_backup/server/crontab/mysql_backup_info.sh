#!/bin/bash


main_dir="/data/DBARepository/mysql/mysql_backup"
resident="$main_dir/client/resident/"
normal_log="$main_dir/log/shell.log"
mysql="$main_dir/common/mysql"

address="172.16.112.12" # 默认的备份地址
dba_host="172.16.112.12"
dba_port=10000
dba_user="master_user"
dba_pass="redhat"
t_mysql_info="mysql_info_db.t_mysql_info"
t_mysql_backup_info="mysql_backup_db.t_mysql_backup_info"
DBA_MYSQL="$mysql -h$dba_host -P$dba_port -u$dba_user -p$dba_pass -N"

function printLog()
{
    content="$1"
    normal_log="$2"
    color="$3"
    echo "[$(date +"%F %T")] $content" >>$normal_log 2>&1
    case "$color" in
        green) echo -e "[`date +"%F %T"`] \033[32m$content \033[0m";;
        red) echo -e "[`date +"%F %T"`] \033[31m$content \033[0m";;
        normal) echo -e "[`date +"%F %T"`] $content";;
        *) echo -e "[`date +"%F %T"`] \033[32m$content \033[0m";;
    esac
}


function getSlave()
{
    instance="$1"
    sql="select concat(Fserver_host,':',Fserver_port) from $t_mysql_info where Fstate='online' and Ftype='$instance' and Frole='Masterbackup';"
    i=$(echo "$sql"| $DBA_MYSQL)
    if [ -z "$i" ];then
        sql="select concat(Fserver_host,':',Fserver_port) from $t_mysql_info where Fstate='online' and Ftype='$instance' and Frole='Slave';"
        i=$(echo "$sql"| $DBA_MYSQL)
    fi
    echo "$i"
}


function updateInfo()
{
    instance="$1"
    slave="$2"
    if [ -z "$slave" ];then # slave不存在,则清空备份信息
        sql="update $t_mysql_backup_info set Fstate='offline' where Ftype='$instance';"
        echo "$sql" | $DBA_MYSQL
        return # Trips
    fi

    slave_host=$(echo "$slave"| awk -F":" '{print $1}')
    slave_port=$(echo "$slave"| awk -F":" '{print $2}')
    sql="select count(*) from $t_mysql_backup_info where Ftype='$instance';"
    c=$(echo "$sql"| $DBA_MYSQL)
    if [ "$c" == "0" ];then
        sql="insert into $t_mysql_backup_info (Ftype,Faddress,Fsource_host,Fsource_port,Fxtrabackup_state,Fxtrabackup_weekday,Fxtrabackup_start_time,Fxtrabackup_end_time,Fxtrabackup_clear_rule,Fmydumper_state,Fmydumper_weekday,Fmydumper_start_time,Fmydumper_end_time,Fmydumper_clear_rule,Fmysqldump_state,Fmysqldump_weekday,Fmysqldump_start_time,Fmysqldump_end_time,Fmysqldump_clear_rule,Fbinary_name,Fmemo,Fstate,Fcreate_time,Fmodify_time) values ('$instance','$address','$slave_host','$slave_port','online','9','00:00:00','23:59:59','0-7-365-3650','online','9','00:00:00','23:59:59','0-7-365-3650','online','9','00:00:00','23:59:59','0-7-365-3650','empty','','online',now(),now());"
        echo "$sql" | $DBA_MYSQL
    else
        # 不动Fstate,可能临时手动关了
        sql="update $t_mysql_backup_info 
             set Faddress='$address',Fsource_host='$slave_host',Fsource_port='$slave_port' 
             where Ftype='$instance';"
        echo "$sql" | $DBA_MYSQL
    fi
}


function main()
{
    sql="select Ftype from $t_mysql_info where Fstate='online' and Frole='Master';"
    instances=$(echo "$sql"| $DBA_MYSQL)

    # offline的实例同步到备份信息表
    in_instance=$(echo $(echo "$instances"| sed -e "s/^/'/g" -e "s/$/'/g")| sed 's/ /,/g' | sed -e "s/^/(/g" -e "s/$/)/g")
    sql="update $t_mysql_backup_info set Fstate='offline' where Ftype not in $in_instance;"
    echo "$sql" | $DBA_MYSQL

    for instance in $(echo "$instances")
    do
        slave=$(getSlave "$instance")
        printLog "[$instance $slave]同步备份信息" "$normal_log" "green"
        updateInfo "$instance" "$slave"
    done
}

main "$@"
