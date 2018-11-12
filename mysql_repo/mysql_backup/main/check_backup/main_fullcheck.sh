#!/bin/bash

# description:MySQL全备检测主函数
# arthur
# 2018-11-01

# 很神奇的逻辑


github_dir="/data/code/github/repository/mysql_repo/mysql_backup"
mysql_restore_build_py="$github_dir/main/backup_script/mysql_restore_build.py"
shell_function_cnf="$github_dir/main/shell_function.cnf"
function_xtraback_cnf="$github_dir/main/full_backup/backupXtrabackup/function_xtraback.cnf"
if [ ! -f "$shell_function_cnf" ] || [ ! -f "$function_xtraback_cnf" ] || [ ! -f "$mysql_restore_build_py" ];then
    echo "$0:找不到配置文件"
    exit 64
else
    source $shell_function_cnf
    source $function_xtraback_cnf
fi

f_lock="$tmp_dir/"$(basename "$0"| awk -F"." '{print $1}')".sock"


function checkOne()
{
    instance="$1"
    restore_source_host="$2"
    restore_source_port="$3"
    task_id="$4"
    if [ -z "$task_id" ];then
        return_info="未知的恢复task_id($task_id),需要kill线程重新恢复"
        # Tips:kill pid,注意
        ps aux | grep -v grep | grep -q "$mysql_restore_build_py --instance='$instance'" | awk '{print $2}' | xargs kill
        echo "update $t_mysql_check_info set Finfo='$return_info',Fmodify_time=now() where Ftype='$instance';" | $DBA_MYSQL
        return 0
    else
        slave_status=$(echo "show slave status\G"| $mysql -u$repl_user -p$repl_pass -h$restore_source_host -P$restore_source_port)
        Slave_IO_Running=$(echo "$slave_status"| grep -w "Slave_IO_Running" | awk -F"Slave_IO_Running:" '{print $2}'| sed 's/ //g')
        Slave_SQL_Running=$(echo "$slave_status"| grep -w "Slave_SQL_Running" | awk -F"Slave_SQL_Running:" '{print $2}'| sed 's/ //g')
        # 主从延迟小于delay_time才认为已经是恢复成功了的数据集,此时等待删除数据,做另外的task_id恢复校验
        if [ "$Slave_IO_Running" = "Yes" ] && [ "$Slave_SQL_Running" = "Yes" ];then
            Seconds_Behind_Master=$(echo "$slave_status" | grep -w "Seconds_Behind_Master"| awk -F"Seconds_Behind_Master:" '{print $2}'| sed 's/ //g')
            if ((${Seconds_Behind_Master}<${delay_time}));then
                return_info="restore_source是有效数据集,等待数据被删除"
                cnt=$(echo "select count(*) from $t_mysql_check_result where Ftask_id='$task_id';"| $DBA_MYSQL)
                if ((${cnt}==1));then
                    echo "update $t_mysql_check_result set Frestore_address='$restore_source_host:$restore_source_port',
                    Frestore_result='Succ',Frestore_end_time=now(),Finfo='$return_info',Fmodify_time=now() where Ftask_id='$task_id';" | $DBA_MYSQL
                else
                    echo "insert into $t_mysql_check_result (Ftask_id,Frestore_address,Frestore_result,Frestore_start_time,
                    Frestore_end_time,Finfo,Fcreate_time,Fmodify_time) 
                    values 
                    ('$task_id','$restore_source_host:$restore_source_port','Succ',now(),now(),'$return_info',now(),now());" | $DBA_MYSQL
                fi
                echo "update $t_mysql_check_info set Finfo='$return_info',Fmodify_time=now() where Ftype='$instance';" | $DBA_MYSQL
                return 0
            fi
        fi
    fi

    return_info="[$task_id]正在恢复中"
    echo "update $t_mysql_check_info set Finfo='$return_info',Fmodify_time=now() where Ftype='$instance';" | $DBA_MYSQL
    cnt=$(echo "select count(*) from $t_mysql_check_result where Ftask_id='$task_id';"| $DBA_MYSQL)
    if ((${cnt}==1));then
        echo "update $t_mysql_check_result set Frestore_address='$restore_source_host:$restore_source_port',
        Frestore_result='Doing',Finfo='$return_info',Fmodify_time=now() where Ftask_id='$task_id';" | $DBA_MYSQL
    else
        echo "insert into $t_mysql_check_result (Ftask_id,Frestore_address,Frestore_result,Frestore_start_time,
        Finfo,Fcreate_time,Fmodify_time) 
        values 
        ('$task_id','$restore_source_host:$restore_source_port','Doing',now(),'$return_info',now(),now());" | $DBA_MYSQL
    fi
}


function restoreMain()
{
    instance="$1"
    restore_source_host="$2"
    restore_source_port="$3"
    load_thread="$4"
    innodb_buff="$5"
    task_id=$(echo "select Ftask_id from $t_mysql_fullbackup_result where Fback_status='Succ' and Ftype='$instance' and Fdate_time>date_sub(CURDATE(),interval 1 week) order by Fdate_time desc limit 1;" | $DBA_MYSQL)
    if [ -z "$task_id" ];then
        info="找不到最近一周成功的task_id" 
        printLog "$info" "$normal_log"
        echo "update $t_mysql_check_info set Finfo='$info',Fmodify_time=now() where Ftype='$instance';" | $DBA_MYSQL
    else
        restore_result=$(echo "select Frestore_result from $t_mysql_check_result where Ftask_id='$task_id';" | $DBA_MYSQL)
        tmp=$(echo "$restore_result"| tr 'a-z' 'A-Z')
        if [ "$tmp" == "SUCC" ];then
            info="$task_id最近已经成功恢复过" 
            printLog "$info" "$normal_log"
            checkOne "$instance" "$restore_source_host" "$restore_source_port" "$task_id"
            echo "update $t_mysql_check_info set Finfo='$info',Fmodify_time=now(),Ftask_id='$task_id' where Ftype='$instance';" | $DBA_MYSQL
        elif [ "$tmp" == "DOING" ];then
            info="$task_id正在做恢复" 
            printLog "$info" "$normal_log"
            checkOne "$instance" "$restore_source_host" "$restore_source_port" "$task_id"
            echo "update $t_mysql_check_info set Finfo='$info',Fmodify_time=now(),Ftask_id='$task_id' where Ftype='$instance';" | $DBA_MYSQL
        else
            #backup_mode=$(echo "select Fbackup_mode from $t_mysql_fullbackup_result where Ftask_id='$task_id';"| $DBA_MYSQL)
            backup_path=$(echo "select Fbackup_path from $t_mysql_fullbackup_result where Ftask_id='$task_id';"| $DBA_MYSQL)
            # TIPS:置于后台执行
            printLog "开始在后台执行:$mysql_restore_build_py --instance='$instance' --dest='$restore_source_host:$restore_source_port' --load_thread='$load_thread' --innodb_buff='$innodb_buff' --remote_backup_path='$backup_path'" $normal_log "green"
            $mysql_restore_build_py --instance="$instance" --dest="$restore_source_host:$restore_source_port" --load_thread="$load_thread" --innodb_buff="$innodb_buff" --remote_backup_path="$backup_path" >>$normal_log 2>&1 &
            info="$task_id正在做恢复" 
            echo "update $t_mysql_check_info set Finfo='$info',Fmodify_time=now(),Ftask_id='$task_id' where Ftype='$instance';" | $DBA_MYSQL
            cnt=$(echo "select count(*) from $t_mysql_check_result where Ftask_id='$task_id';"| $DBA_MYSQL)
            if ((${cnt}==1));then
                echo "update $t_mysql_check_result set Frestore_address='$restore_source_host:$restore_source_port',
                Frestore_result='Doing',Finfo='$info',Fmodify_time=now() where Ftask_id='$task_id';" | $DBA_MYSQL
            else
                echo "insert into $t_mysql_check_result (Ftask_id,Frestore_address,Frestore_result,Frestore_start_time,
                Finfo,Fcreate_time,Fmodify_time) 
                values 
                ('$task_id','$restore_source_host:$restore_source_port','Doing',now(),'$info',now(),now());" | $DBA_MYSQL
            fi
        fi
    fi
}


function restoreCheckMain()
{
    indexs=$(echo "select Findex from $t_mysql_check_info where Fstate='online' and Frestore_address='$local_ip'"| $DBA_MYSQL)
    for index in $(echo "$indexs")
    do
        instance=$(echo "select Ftype from $t_mysql_check_info where Findex='$index'"| $DBA_MYSQL)
        task_id=$(echo "select Ftask_id from $t_mysql_check_info where Findex='$index'"| $DBA_MYSQL)
        delay_time=$(echo "select Fdelay_time from $t_mysql_check_info where Findex='$index'"| $DBA_MYSQL)
        load_thread=$(echo "select Fload_thread from $t_mysql_check_info where Findex='$index'"| $DBA_MYSQL)
        innodb_buff=$(echo "select Finnodb_buff from $t_mysql_check_info where Findex='$index'"| $DBA_MYSQL)
        restore_source=$(echo "select Frestore_source from $t_mysql_check_info where Findex='$index'"| $DBA_MYSQL)
        restore_source_host=$(echo "$restore_source"| awk -F":" '{print $1}')
        restore_source_port=$(echo "$restore_source"| awk -F":" '{print $2}')
        
        # Tips:ps命令写死了
        # ps aux | grep -v grep | grep -q "$mysql_restore_build_py --instance='$instance'"
        if ps aux | grep -v grep | grep -q "$mysql_restore_build_py --instance='$instance'"; then
            checkOne "$instance" "$restore_source_host" "$restore_source_port" "$task_id" # 进入校验逻辑
        else
            restoreMain "$instance" "$restore_source_host" "$restore_source_port" "$load_thread" "$innodb_buff" # 进入恢复逻辑
        fi
        exit
    done

}


function main()
{
    lockFile "$0" "$f_lock" "$$"

    while ((1))
    do
	    restoreCheckMain
        lastExit $bd $maxr_second
    done
   
}


main "$@"

