#!/bin/bash

# description:MySQL全备主函数
# arthur
# 2018-10-16

base_dir="/data/repository/mysql_repo/mysql_backup"
common_dir="$base_dir/common"
shell_cnf="$common_dir/shell.cnf"
source $shell_cnf
f_name=$(basename "$0")
f_lock="$tmp_dir/"$(basename "$0"| awk -F"." '{print $1}')".sock"
bd=$(date +%s) # 脚本开始执行时间
maxr_second=3600 # 脚本执行时间



function syncFullResult()
{
    task_id="$1"
    instance="$2"
    master_host="$3"
    master_port="$4"
    backup_mode="$5"
    backup_path="$6"
    back_status="$7"
    backup_info="$8"
    is_task_id=$(echo "select count(*) from $t_mysql_fullbackup_result where Ftask_id='$task_id'"| $DBA_MYSQL)
    if ((${is_task_id}==0));then
        sql="insert into $t_mysql_fullbackup_result 
        (Ftype,Ftask_id,Fdate_time,Fdata_source,Fbackup_mode,
        Fbackup_address,Fbackup_path,Fback_status,Fbackup_info,Fcreate_time,Fmodify_time) 
        values 
        ('$instance','$task_id',CURDATE(),'$master_host:$master_port','$backup_mode',
        '$local_ip','$backup_path','$back_status','$backup_info',now(),now());"
    else
        sql="update $t_mysql_fullbackup_result 
        set Ftype='$instance',Fdate_time=CURDATE(),Fdata_source='$master_host:$master_port',Fbackup_mode='$backup_mode',
        Fbackup_address='$local_ip',Fbackup_path='$backup_path',Fback_status='$back_status',Fbackup_info='$backup_info',
        Fmodify_time=now()
        where Ftask_id='$task_id';"
    fi
    echo "$sql"| $DBA_MYSQL
}


function backupFunctionMain()
{

    task_id="$1"
    instance="$2"
    backup_mode="$3"
    master_host="$4"
    master_port="$5"
    
    suff_time=$(echo "$task_id"| awk -F"_" '{print $NF}')
    backup_path="$full_backup_dir/$(upperString "$instance")/${suff_time}" # 备份目录
    mkdir -p $backup_path

    # Tips:依赖mydumper_backup脚本返回值
    tmp_bmode=$(upperString "$backup_mode")
    if [ "$tmp_bmode" = "MYDUMPER" ];then
        return_info=$(checkMydumper "$master_host" "$master_port" "$backup_path")
        if (($?==0));then
            return_info=$(backupMydump "$master_host" "$master_port" "$backup_path" "N")
        else
            ec >/dev/null 2>&1 # Tips:主动生成一个错误
        fi
    elif [ "$tmp_bmode" = "XTRABACKUP" ];then
        return_info=$(checkXtrabackup "$master_host" "$master_port" "$backup_path")
        if (($?==0));then
            # backupXtrabackupLocal:在本地备份
            # backupXtrabackupRemote:在远程备份,使用scp
            #return_info=$(backupXtrabackupLocal "$master_host" "$master_port" "$backup_path" "N")
            return_info=$(backupXtrabackupRemote "$master_host" "22" "$master_port" "22" "$backup_path" "N")
        else
            ec >/dev/null 2>&1 # Tips:主动生成一个错误
        fi
    elif [ "$tmp_bmode" = "MYSQLDUMP" ];then
        return_info="[$f_name][$task_id]不支持mysqldump($backup_mode)"
        ec >/dev/null 2>&1 # Tips:主动生成一个错误
    else
        return_info="[$f_name][$task_id]unknow backup mode($backup_mode)"
        ec >/dev/null 2>&1 # Tips:主动生成一个错误
    fi

    if (($?==0));then
        printLog "[$f_name][$task_id]$return_info" "$normal_log"
        tmp_bstatus="Backing"
        tmp_memo="尝试备份成功"
    else
        printLog "[$f_name][$task_id]$return_info" "$normal_log"
        tmp_bstatus="Fail"
        tmp_memo="尝试备份失败:$return_info"
    fi
    syncFullResult "$task_id" "$instance" "$master_host" "$master_port" "$backup_mode" "$backup_path" "$tmp_bstatus" "$tmp_memo" 
}



function getTaskID()
{
    instance="$1"
    weekday="$2"
    # Tips:task_id生成规则
    # 每周备份一次:instance_备份日期
    # 每天备份:instance_当天日期
    if ((${weekday}!=9));then
        task_id="${instance}_$(date -d "$(($(date +%w)-${weekday})) days ago" +"%Y%m%d")"
    else
        task_id="${instance}_$(date +"%Y%m%d")"
    fi
    echo "$task_id"
}


function checkBackupTime()
{
    start_time="$1"
    end_time="$2"
    cur_time="$3"
    start_pos=$(date -d "$start_time" +"%s") # 每天开始启动备份时间点(unix时间戳,下同)
    end_pos=$(date -d "$end_time" +"%s") # 备份结束时间点
    cur_pos=$(date -d "$cur_time" +"%s") # 当前时间点

    if [ -z "$start_pos" ];then
        start_pos=$(date -d "00:00:01" +"%s")
    fi
    if [ -z "$end_pos" ];then
        end_pos=$(date -d "08:00:00" +"%s")
    fi
    if ((${cur_pos}>=${start_pos})) && ((${cur_pos}<=${end_pos}));then
        E="0"
    else
        E="1"
    fi
    return "$E"
}


function backupChild()
{
    indexs="$1"
    for index in $(echo "$indexs")
    do
        instance=$(echo "select Ftype from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
        weekday=$(echo "select Fbackup_weekday from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
        task_id=$(getTaskID "$instance" "$weekday")
        start_time=$(echo "select Fstart_time from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
        end_time=$(echo "select Fend_time from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
        cur_time=$(date +"%H:%M:%S")
 
        checkBackupTime "$start_time" "$end_time" "$cur_time"   
        if (($?==0));then
            printLog "[$f_name][$task_id]current time is ${cur_time}, enter backup logic(start_time:$start_time,end_time:$end_time)." "$normal_log"
            data_source=$(echo "select Fdata_source from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
            backup_mode=$(echo "select Fbackup_mode from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
            master_host=$(echo "$data_source"| awk -F":" '{print $1}')
            master_port=$(echo "$data_source"| awk -F":" '{print $2}')

            # Tips:Succ和Backing状态的task_id不进入逻辑
            back_status=$(echo "select Fback_status from $t_mysql_fullbackup_result where Ftask_id='$task_id'"| $DBA_MYSQL)
            tmp_bstatus=$(upperString "$back_status")
            if [ -z "$back_status" ];then
                back_status="initbackup"
            fi
            if [ "$tmp_bstatus" = "SUCC" ] || [ "$tmp_bstatus" = "BACKING" ];then
                printLog "[$f_name][$task_id]backup status is ${back_status},return" "$normal_log"
            else
                printLog "[$f_name][$task_id]backup status is ${back_status},enter continue" "$normal_log"
                backupFunctionMain "$task_id" "$instance" "$backup_mode" "$master_host" "$master_port"
            fi
        else
            printLog "[$f_name][$task_id]current time is ${cur_time}, don't enter backup logic(start_time:$start_time,end_time:$end_time)." "$normal_log"
        fi
    done
}


function backupMain()
{
    # Tips:
    # 本周今天之前需要备份的或者每天备份一次的
    # 并且没有在备份成功或正在备份中的数据库

    # 今天之前需要备份，但是没有在备份成功或者备份中的数据库
    printLog "[$f_name]start deal with ervery week backupInfo." "$normal_log" 
    sql="select Findex from $t_mysql_fullbackup_info 
    where Fstate='online' and Fbackup_address='$local_ip'
    and Fbackup_weekday<='$curweek'
    and Ftype not in 
    (select Ftype from $t_mysql_fullbackup_result
    where Fdate_time>='$monday' and Fdate_time<='$sunday' and Fback_status in ('Succ','Backing'));"
    indexs=$($DBA_MYSQL -e "$sql")
    backupChild "$indexs"
    printLog "[$f_name]end deal with ervery week backupInfo." "$normal_log" 

    # 每天需要备份，但是没有在备份中的数据库
    printLog "[$f_name]start deal with ervery day backupInfo." "$normal_log" 
    sql="select Findex from $t_mysql_fullbackup_info 
    where Fstate='online' and Fbackup_address='$local_ip'
    and Fbackup_weekday=9
    and Ftype not in 
    (select Ftype from $t_mysql_fullbackup_result
    where Fdate_time>='$monday' and Fdate_time<='$sunday' and Fback_status in ('Backing'));"
    indexs=$($DBA_MYSQL -e "$sql")
    backupChild "$indexs"
    printLog "[$f_name]end deal with ervery day backupInfo." "$normal_log" 
}


function checkBackStatus()
{
    indexs=$(echo "select Findex from $t_mysql_fullbackup_result 
    where Fdate_time>='$monday' and Fdate_time<='$sunday' 
    and Fback_status='Backing' and Fbackup_address='$local_ip';"| $DBA_MYSQL)

    for index in $(echo "$indexs")
    do
        task_id=$(echo "select Ftask_id from $t_mysql_fullbackup_result where Findex='$index';"| $DBA_MYSQL)
        backup_path=$(echo "select Fbackup_path from $t_mysql_fullbackup_result where Findex='$index';"| $DBA_MYSQL)
        backup_mode=$(echo "select Fbackup_mode from $t_mysql_fullbackup_result where Findex='$index';"| $DBA_MYSQL)
        data_source=$(echo "select Fdata_source from $t_mysql_fullbackup_result where Findex='$index';"| $DBA_MYSQL)

        tmp_bmode=$(upperString $backup_mode)

        if [ "$tmp_bmode" = "MYDUMPER" ];then
            metadata="$backup_path/metadata"
            json_info=$(checkMydumperResult "$metadata" "$data_source")
        elif [ "$tmp_bmode" = "XTRABACKUP" ];then
            #json_info=$(checkXtrabackupResultLocal "$backup_path" "$data_source")
            json_info=$(checkXtrabackupResultRemote "$backup_path" "$data_source")
        elif [ "$tmp_bmode" = "MYSQLDUMP" ];then
            return_info="hell mysqldump"
        else
            return_info="unknow backup mode."
            ec >/dev/null 2>&1 # Tips:生成一个失败
        fi

        value="$?"
        backup_path=$(echo "select Fbackup_path from $t_mysql_fullbackup_result where Findex='$index';"| $DBA_MYSQL)
        if (($value==0));then
            size=$(du -shm $backup_path | awk '{print $1}')
            backup_start_time=$(echo "$json_info"| awk -F"--" '{print $1}')
            backup_end_time=$(echo "$json_info"| awk -F"--" '{print $2}')
            metadata_jason=$(echo "$json_info"| awk -F"--" '{print $3}')
            back_status="Succ"
            # Tips:归档留给check脚本,仅仅验证数据是有效集之后再进行压缩
            #dir_path=$(dirname "$backup_path")
            #base_path=$(basename "$backup_path")
            #archivePath "$dir_path" "$base_path" # 备份数据压缩归档
            #archive_file="${dir_path}/${base_path}.tar.gz"
            sql="update $t_mysql_fullbackup_result 
            set Fbackup_size='$backup_size',Fbackup_start_time='$backup_start_time',Fbackup_end_time='$backup_end_time',
            Fbackup_metadata=\"$metadata_jason\",Fback_status='$back_status',Fmodify_time=now(),Fbackup_info='备份完成'
            where Ftask_id='$task_id';"
        elif (($value==1));then
            back_status="Backing"
            sql="update $t_mysql_fullbackup_result 
            set Fback_status='Backing',Fmodify_time=now(),Fbackup_info='$json_info' 
            where Ftask_id='$task_id';"
        else
            back_status="Fail"
            sql="update $t_mysql_fullbackup_result 
            set Fback_status='$back_status',Fmodify_time=now(),Fbackup_info='$json_info'
            where Ftask_id='$task_id';"
        fi
        printLog "[$task_id] backup is $back_status($json_info)"
        echo "$sql" | $DBA_MYSQL
    done
}


function main()
{
    lockFile "$0" "$f_lock" "$$"

    while ((1))
    do
        curweek=$(date +"%w") 
        sunday="$(date -d "$(($(date +%w)-6)) days ago" +"%Y-%m-%d")" # 本周周六日期
        monday="$(date -d "$(($(date +%w)-0)) days ago" +"%Y-%m-%d")" # 本周周日日期

        printLog "[$f_name]start full backup do,please don't quit at will." "$normal_log" 
        backupMain 
        printLog "[$f_name]end full backup do,quit if you need." "$normal_log" 
        #sleep 60 # 开始备份后不一定马上会生成备份文件,需要sleep
        #检测备份成功失败状态(只检测Backing状态的task_id)
        printLog "[$f_name]start full backup check." "$normal_log" 
        checkBackStatus
        printLog "[$f_name]end full backup check." "$normal_log" 
        exit
        sleep 10 # 留给退出时间

        lastExit $bd $maxr_second $f_name
    done
}


main "$@"

