#!/bin/bash

# description:MySQL全备自动清理函数
# arthur
# 2018-11-13

base_dir="/data/repository/mysql_repo/mysql_backup"
shell_cnf="$base_dir/common/shell.cnf"
if [ ! -f "$shell_cnf" ] ;then
    echo "$0:找不到配置文件"
    exit 64
else
    source $shell_cnf
fi

f_lock="$tmp_dir/"$(basename "$0"| awk -F"." '{print $1}')".sock"

bd=$(date +%s) # 脚本开始执行时间
maxr_second=3600 # 脚本执行时间


function checkDisk()
{
    disk_percent=$(df -hP $full_backup_dir | tail -1 | awk '{print $5}'| sed 's/%//g')   
    if ((${disk_percent}>${disk_max}));then
        clean_status=1
    else
        clean_status=0
    fi
    return $clean_status
}


function lookSavedBackup()
{
    instance="$1"
    backup_path="$2"
    start_days="$3"
    end_days="$4"
    is_new="$5"
    start_time=$(date -d "${end_days} days ago" +"%F %T") # 转换思路
    end_time=$(date -d "${start_days} days ago" +"%F %T")
    if ((${is_new}==1));then # 保留最新的一份
        sql="select Fbackup_path from $t_mysql_fullbackup_result 
            where Fback_status='Succ' and Fclear_state='todo' 
            and Ftype='$instance' 
            and Fbackup_end_time >='$start_time' and Fbackup_end_time<'$end_time' 
            order by Fbackup_end_time desc limit 1;"
    else # 保留最老的一份
        sql="select Fbackup_path from $t_mysql_fullbackup_result 
            where Fback_status='Succ' and Fclear_state='todo' 
            and Ftype='$instance' 
            and Fbackup_end_time >='$start_time' and Fbackup_end_time<'$end_time' 
            order by Fbackup_end_time limit 1;"
    fi
    #echo "$sql"
    save_backup_path=$(echo "$sql" | $DBA_MYSQL)
    if [ "$backup_path" == "$save_backup_path" ];then
        printLog "在时间范围(${start_time}-${end_time})内待保留的记录为$save_backup_path,与验证路径$backup_path一致,不清理" "$normal_log"
        deleted="0"
    else
        printLog "在时间范围(${start_time}-${end_time})内待保留的记录为$save_backup_path,与验证路径$backup_path不一致,可以清理" "$normal_log"
        deleted="1"
    fi
    return $deleted
}


function cleanOne()
{
    instance="$1"
    task_id="$2"
    backup_path="$3"
    # Tips:
    # 1、Ftype是唯一键
    # 2、不需要加Fstate='online',避免不小心改Fstate数据都被清理掉,但是有可能实例下线,数据没清理
    clear_rule=$(echo "select Fclear_rule from $t_mysql_fullbackup_info where Ftype='TestDB';"| $DBA_MYSQL)
    num=$(echo "$clear_rule" |awk -F"-" '{print NF}')

    lookSavedBackup "$instance" "$backup_path" "0" "36500" "0" # 保留最老的一份数据
    deleted=$?
    if (($deleted==0));then
        printLog "验证路径$backup_path在总时间范围内待保留的记录,不清理" "$normal_log"
        return
    fi

    lookSavedBackup "$instance" "$backup_path" "0" "0" "0" # 保留最新的一份数据
    deleted=$?
    if (($deleted==0));then
        printLog "验证路径$backup_path在总时间范围内待保留的记录,不清理" "$normal_log"
        return
    fi

    for ((start_pos=1;start_pos<${num};start_pos++))
    do
        end_pos=$((${start_pos}+1))
        start_days=$(echo "$clear_rule" | sed 's/-/\n/g'| sed -n ${start_pos}p)
        end_days=$(echo "$clear_rule" | sed 's/-/\n/g'| sed -n ${end_pos}p)
        if ((${end_pos}==${num}));then
            lookSavedBackup "$instance" "$backup_path" "$start_days" "$end_days" "0" # 保留老的
        else
            lookSavedBackup "$instance" "$backup_path" "$start_days" "$end_days" "1" # 保留新的
        fi
        deleted=$?
        if (($deleted==0));then
            printLog "验证路径$backup_path在总时间范围内待保留的记录,不清理" "$normal_log"
            return
        fi
    done
    printLog "验证路径$backup_path不在总时间范围内待保留的记录,清理" "$normal_log"
    echo "cd $full_backup_dir && cd $dir && rm -rf $backup_file"
    #echo "update $t_mysql_fullbackup_result set Fclear_state='done',Fmodify_time=now() where Findex='$index'" | $DBA_MYSQL
}


function mainClean()
{
    dirs=$(ls $full_backup_dir)
    for dir in $(echo "$dirs")
    do
        instance="$dir"
        clean_backupdir="$full_backup_dir/$dir"
        cd $clean_backupdir # Tips:cd操作
        backup_files=$(ls)
        for backup_file in $(echo "$backup_files")
        do
            backup_path="$full_backup_dir/$dir/$backup_file"
            printLog "==========[${instance}:$backup_path]开始进入逻辑" "$normal_log"
            # Tips:Fbackup_path是唯一键
            index=$(echo "select Findex from $t_mysql_fullbackup_result where Fbackup_path='$backup_path' and Fbackup_address='$local_ip'"| $DBA_MYSQL) 
            if [ -z "$index" ];then
                # 在结果表找不到记录,认为垃圾数据
                # Tips:rm -rf操作
                printLog "在数据库中找不到backup_path记录,清理($backup_path)" "$normal_log"
                echo "cd $full_backup_dir && cd $dir && rm -rf $backup_file"
            else
                back_status=$(echo "select Fback_status from $t_mysql_fullbackup_result where Findex='$index'" | $DBA_MYSQL)
                tmp=$(echo "$back_status"| tr 'a-z' 'A-Z')
                if [ "$tmp" == "FAIL" ];then
                    printLog "数据库记录为$back_status,清理($backup_path)" "$normal_log"
                    echo "cd $full_backup_dir && cd $dir && rm -rf $backup_file"
                    #echo "update $t_mysql_fullbackup_result set Fclear_state='done',Fmodify_time=now() where Findex='$index'" | $DBA_MYSQL
                elif [ "$tmp" == "BACKING" ];then
                    printLog "数据库记录为$back_status,退出此次循环($backup_path)" "$normal_log"
                    continue
                elif [ "$tmp" == "SUCC" ];then
                    clear_state=$(echo "select Fclear_state from $t_mysql_fullbackup_result where Findex='$index'" | $DBA_MYSQL)
                    clear_state=$(echo "$clear_state"| tr 'a-z' 'A-Z')
                    if [ "$clear_state" == "NOT" ];then
                        printLog "数据库状态为$clear_state,退出此次循环($backup_path)" "$normal_log"
                        continue
                    else
                        # 进入备份成功的且是清理的逻辑
                        task_id=$(echo "select Ftask_id from $t_mysql_fullbackup_result where Findex='$index'" | $DBA_MYSQL)
                        cleanOne "$instance" "$task_id" "$backup_path"
                    fi
                else
                    printLog "未知的数据库状态,退出此次循环$(backup_path)" "$normal_log"
                    continue
                fi
            fi
        done
    done
}


function main()
{
    disk_max="30" # 磁盘开始清理阈值百分比
    lockFile "$0" "$f_lock" "$$"
    while ((1))
    do
        checkDisk
        if (($?==1));then
            printLog "当前磁盘使用$disk_percent,进入清理逻辑(阈值:$disk_max)" "$normal_log"
            mainClean
        else
            printLog "当前磁盘使用$disk_percent,不进入清理逻辑(阈值:$disk_max)" "$normal_log"
        fi
        exit
        lastExit $bd $maxr_second
    done
}


main "$@"

