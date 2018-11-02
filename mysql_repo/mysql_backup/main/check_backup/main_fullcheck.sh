#!/bin/bash

# description:MySQL全备检测主函数
# arthur
# 2018-11-01

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


function restoreMain()
{
    sql="select Findex from $t_mysql_check_info where Fstate='online' and Frestore_address='$local_ip' and Fcheck_info!='Restoring';"
    indexs=$(echo "$sql"| $DBA_MYSQL)
    for index in $(echo "$indexs")
    do
        instance=$(echo "select Ftype from $t_mysql_check_info where Findex='$index'"| $DBA_MYSQL)
        sql="select Findex from $t_mysql_fullbackup_result
            where Fback_status='Succ' and Ftype='$instance' 
            and Fdate_time>date_sub(CURDATE(),interval 1 week) 
            order by Fdate_time desc limit 1;"
        result_index=$(echo "$sql"| $DBA_MYSQL)

        if [ -z "$result_index" ];then
            printLog "[$instance]找不到最近一周需要恢复集" "$normal_log"
        else
            tmp=$(echo "select count(*) from $t_mysql_check_result where Ftype='$instance' and Frestore_result='Doing'"| $DBA_MYSQL)
            if [ "$tmp" = "1" ];then
                printLog "[$instance]当前有正在恢复的数据集" "$normal_log"
            else
                restore_source=$(echo "select Frestore_source from $t_mysql_check_info where Findex='$index'"| $DBA_MYSQL)
                load_thread=$(echo "select Fload_thread from $t_mysql_check_info where Findex='$index'"| $DBA_MYSQL)
                innodb_buff=$(echo "select Finnodb_buff from $t_mysql_check_info where Findex='$index'"| $DBA_MYSQL)

                backup_mode=$(echo "select Fbackup_mode from $t_mysql_fullbackup_result where Findex='$result_index'"| $DBA_MYSQL)
                backup_path=$(echo "select Fbackup_path from $t_mysql_fullbackup_result where Findex='$result_index'"| $DBA_MYSQL)

                task_id=$(echo "select Ftask_id from $t_mysql_fullbackup_result where Findex='$result_index'"| $DBA_MYSQL)
                printLog "[$instance]开始恢复task_id($task_id)数据" "$normal_log"
                echo "update $t_mysql_check_info set Fcheck_info='Restoring' where Findex='$index';" | $DBA_MYSQL
                tmp=$(echo "select count(*) from $t_mysql_check_result where Ftask_id='$task_id'"| $DBA_MYSQL)
                if [ "$tmp" = "1" ];then
                    sql="update $t_mysql_check_result 
                        set Ftype='$instance',Ftask_id='$task_id',Frestore_address='$local_ip',Frestore_result='Doing',
                        Fmodify_time=now()
                        where Ftask_id='$task_id'"
                else
                    sql="insert into $t_mysql_check_result (Ftype,Ftask_id,Frestore_address,Frestore_result,
                        Frestore_start_time,Fcreate_time,Fmodify_time) 
                        values ('$instance','$task_id','$local_ip','Doing',now(),now(),now())"
                fi
                echo "$sql"| $DBA_MYSQL

                # TIPS:
                # 置于后台执行
                echo "$mysql_restore_build_py --instance='$instance' --dest='$restore_source' 
                    --load_thread='$load_thread' --innodb_buff='$innodb_buff' --remote_backup_path='$backup_path'" >>$normal_log 2>&1
                $mysql_restore_build_py --instance="$instance" --dest="$restore_source" \
                    --load_thread="$load_thread" --innodb_buff="$innodb_buff" --remote_backup_path="$backup_path" >>$normal_log 2>&1 &
            fi
        fi
    done
}


function checkMain()
{
    # 1、正在Restoring是否已经Succ或者Fail
    sql="select Findex from $t_mysql_check_info where Fstate='online' and Frestore_address='$local_ip' and Fcheck_info='Restoring';"
    indexs=$(echo "$sql"| $DBA_MYSQL)
    for index in $(echo "$indexs")
    do  
        instance=$(echo "select Ftype from $t_mysql_check_info where Findex='$index'"| $DBA_MYSQL)
        restore_source=$(echo "select Frestore_source from $t_mysql_check_info where Findex='$index'"| $DBA_MYSQL)
        restore_host=$(echo "$restore_source" | awk -F":" '{print $1}')
        restore_port=$(echo "$restore_source" | awk -F":" '{print $2}')
        if ps aux| grep "$mysql_restore_build_py --instance='$instance'" -q; then
            printLog "[$instance]正在还原中" "$normal_log"
            sql="update $t_mysql_check_result 
                set Ftype='$instance',Ftask_id='$task_id',Frestore_address='$local_ip',Frestore_result='Doing',
                Fmodify_time=now(),Finfo='检测还原进程存在,等待还原完成'
                where Ftask_id='$task_id'"
            echo "$sql" | $DBA_MYSQL
        else
            # 这里只做检测的检测是否还原成功
            # 检测目标实例是否是空实例
            # 是否真的还原成功,需要追binlog才知道
            checkMySQLConnection "$restore_host" "$restore_port" "$read_user" "$read_pass" "$normal_log"
            if (($?!=0));then
                printLog "检测还原失败,实例连接失败,更新状态为Restored" "$normal_log"
                sql="update $t_mysql_check_result 
                set Ftype='$instance',Ftask_id='$task_id',Frestore_result='Fail',
                Fmodify_time=now(),Finfo='检测还原失败,实例连接失败'
                where Ftask_id='$task_id'"
            else
                tmp=$(echo "select count(*) from information_schema.tables 
                where table_schema not in ('information_schema','mysql','sys','test_db','performance_schema');
                " | $mysql -u$read_user -p$read_pass -h$restore_host -P$restore_port -N)
                if [ "$tmp" = "0" ];then
                    printLog "检测还原失败,空实例,更新状态为Restored" "$normal_log"
                    sql="update $t_mysql_check_result 
                    set Ftype='$instance',Ftask_id='$task_id',Frestore_result='Fail',
                    Fmodify_time=now(),Finfo='检测还原失败,空实例'
                    where Ftask_id='$task_id'"
                else
                    printLog "检测还原成功,更新状态为Restored" "$normal_log"
                    sql="update $t_mysql_check_result 
                    set Ftype='$instance',Ftask_id='$task_id',Frestore_result='Fail',
                    Fmodify_time=now(),Finfo='检测还原成功'
                    where Ftask_id='$task_id'"
                fi
            fi

            echo "$sql" | $DBA_MYSQL
            echo "update $t_mysql_check_info set Fcheck_info='Restored' where Ftype='$instance'" | $DBA_MYSQL
        fi
    done

    
}


function main()
{
    lockFile "$0" "$f_lock" "$$"

    while ((1))
    do
        restoreMain
        checkMain
        exit
        sleep 60
    done
   
}


main "$@"
