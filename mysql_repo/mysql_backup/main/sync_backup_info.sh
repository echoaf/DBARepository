#!/bin/bash

# description:同步备份信息表
# arthur
# 2018-10-16

github_dir="/data/code/github/repository/mysql_repo/mysql_backup"
shell_function_cnf="$github_dir/main/shell_function.cnf"
function_xtraback_cnf="$github_dir/main/full_backup/backupXtrabackup/function_xtraback.cnf"
if [ ! -f "$shell_function_cnf" ] || [ ! -f "$function_xtraback_cnf" ];then
    echo "$0:找不到配置文件"
    exit 64
else
    source $shell_function_cnf
    source $function_xtraback_cnf
fi



function syncFullBackupInfo()
{
    instances=$(echo "select distinct Ftype from $t_mysql_info 
        where Fstate='online' and Fserver_host='$local_ip' and Frole='Masterbackup';" | $DBA_MYSQL)

    for instance in $(echo "$instances")
    do
        echo "$instance"
        data_source=$(echo "select concat(Fserver_host,':',Fserver_port) from $t_mysql_info 
        where Fstate='online' and Frole='Masterbackup' and Fserver_host='$local_ip' and Ftype='$instance'"| $DBA_MYSQL)

        if [ ! -z "$instance" ];then
            cnt=$(echo "select count(*) from $t_mysql_fullbackup_info where Ftype='$instance';" | $DBA_MYSQL)
            if ((${cnt}==0));then
                sql="insert into $t_mysql_fullbackup_info (Ftype,Fbackup_address,Fdata_source,Fbackup_mode,
                Fbackup_weekday,Fstate,Fcreate_time,Fmodify_time) 
                values 
                ('$instance','$local_ip','$data_source','mydumper','9','tmp_online',now(),now());"   
            else
                sql="update $t_mysql_fullbackup_info set Fbackup_address='$local_ip',Fdata_source='$data_source',Fstate='online'
                where Ftype='$instance' and Fstate='online';"
            fi
            echo "$sql"| $DBA_MYSQL

            cnt=$(echo "select count(*) from $t_mysql_binarylog_info where Ftype='$instance';" | $DBA_MYSQL)
            if ((${cnt}==0));then
                sql="insert into $t_mysql_binarylog_info (Ftype,Fbackup_address,Fdata_source,Fstate,Fcreate_time,Fmodify_time) 
                values 
                ('$instance','$local_ip','$data_source','tmp_online',now(),now());"   
            else
                sql="update $t_mysql_binarylog_info set Fbackup_address='$local_ip',Fdata_source='$data_source',Fstate='online'
                where Ftype='$instance' and Fstate='online';"
            fi
            echo "$sql"| $DBA_MYSQL

            cnt=$(echo "select count(*) from $t_mysql_check_info where Ftype='$instance';" | $DBA_MYSQL)
            if ((${cnt}==0));then
                sql="insert into $t_mysql_check_info
                (Ftype,Fdelay_time,Frestore_source,Frestore_address,Fload_thread,Finnodb_buff,Fstate,Fcreate_time,Fmodify_time) 
                values 
                ('$instance','600','$data_source','$local_ip','8','512M','tmp_online',now(),now());"   
            else
                sql="update $t_mysql_check_info set Frestore_address='$local_ip',Frestore_address='$data_source',Fstate='online'
                where Ftype='$instance' and Fstate='online';"
            fi
            echo "$sql"| $DBA_MYSQL
        fi
    done
}



function main()
{
    syncFullBackupInfo
}



main "$@"
