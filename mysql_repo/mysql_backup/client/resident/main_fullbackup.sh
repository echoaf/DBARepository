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


function backupFunctionMain()
{
    backup_mode="$1"
    curday=$(date +"%F")
    tmp_type=$(echo "$type_name"| tr 'a-z' 'A-Z')
    tmp_time=$(echo "$task_id"| awk -F"_" '{print $2}')
    backup_path="${full_backup_dir}/${tmp_type}/${tmp_time}" # 备份目录
    mkdir -p $backup_path

    # Tips:依赖mydumper_backup脚本返回值
    tmp_bmode=$(echo "$backup_mode"| tr 'a-z' 'A-Z')
    if [ "$tmp_bmode" = "MYDUMPER" ];then
        mydumperBackup $master_host $master_port $backup_path "N" $normal_log
    elif [ "$tmp_bmode" = "XTRABACKUP" ];then
        master_my_cnf="/data/mysql/$master_port/my.cnf"
        xtrabackupBackup $master_host $master_port 22 $master_my_cnf $local_ip 22 $backup_path "N" "$normal_log"
    else
        printLog "[$f_name]未知的备份方式$backup_mode" "$normal_log"
        ec >/dev/null 2>&1 # Tips:生成一个错误
    fi

    if (($?==0));then
        printLog "[$f_name][$task_id $type_name $master_host:$master_port] 尝试备份Succ" "$normal_log"
        tmp_bstatus="Backing"
        tmp_memo="尝试备份成功"
    else
        printLog "[$f_name][$task_id $type_name $master_host:$master_port] 尝试备份Fail" "$normal_log"
        tmp_bstatus="Fail"
        tmp_memo="尝试备份失败"
        # 备份失败Nice值自增1
        echo "update $t_mysql_fullbackup_info set Fnice=Fnice+1,Fmodify_time=now() where Ftype='$type_name' and Fstate='online';" | $DBA_MYSQL
    fi

    is_task_id=$(echo "select count(*) from $t_mysql_fullbackup_result where Ftask_id='$task_id'"| $DBA_MYSQL)
    if ((${is_task_id}==0));then
        sql="insert into $t_mysql_fullbackup_result 
        (Ftype,Ftask_id,Fdate_time,Fdata_source,Fbackup_mode,
        Fbackup_address,Fbackup_path,Fback_status,Fbackup_info,Fcreate_time,Fmodify_time) 
        values 
        ('$type_name','$task_id','$curday','$master_host:$master_port','$backup_mode',
        '$local_ip','$backup_path','$tmp_bstatus','$tmp_memo',now(),now());"
    else
        sql="update $t_mysql_fullbackup_result 
        set Ftype='$type_name',Fdate_time='$curday',Fdata_source='$master_host:$master_port',Fbackup_mode='$backup_mode',
        Fbackup_address='$local_ip',Fbackup_path='$backup_path',Fback_status='$tmp_bstatus',Fbackup_info='$tmp_memo',
        Fmodify_time=now()
        where Ftask_id='$task_id';"
    fi
    echo "$sql"| $DBA_MYSQL
}


function backupChild()
{
    indexs="$1"
    echo "$indexs"
    exit
    for index in $(echo "$indexs")
    do
        type_name=$(echo "select Ftype from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
        weekday=$(echo "select Fbackup_weekday from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
        # Tips:task_id生成规则
        # 每周备份一次:type_name_备份日期
        # 每天备份:type_name_当天日期
        if ((${weekday}!=9));then
            task_id="${type_name}_$(date -d "$(($(date +%w)-${weekday})) days ago" +"%Y%m%d")"
        else
            task_id="${type_name}_$(date +"%Y%m%d")"
        fi

        # Tips:version2.0
        start_time=$(echo "select Fstart_time from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
        end_time=$(echo "select Fend_time from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
        cur_time=$(date +"%H:%M:%S")
        start_pos=$(date -d "$start_time" +"%s") # 每天开始启动备份时间点(unix时间戳,下同)
        end_pos=$(date -d "$end_time" +"%s") # 备份结束时间点
        cur_pos=$(date -d "$cur_time" +"%s") # 当前时间点
        if [ -z "$start_pos" ];then
            start_pos=$(date -d "00:00:01" +"%s")
        fi
        if [ -z "$end_pos" ];then
            end_pos=$(date -d "08:00:00" +"%s")
        fi

        if ((${cur_pos}>=${start_pos})) && ((${cur_pos}<=${end_pos})); then
            printLog "[$f_name][$task_id]当前事件点${cur_time}在备份时间点(${start_time}-${end_time})内,开始进入今天的备份逻辑"
            data_source=$(echo "select Fdata_source from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
            backup_mode=$(echo "select Fbackup_mode from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
            master_host=$(echo "$data_source"| awk -F":" '{print $1}')
            master_port=$(echo "$data_source"| awk -F":" '{print $2}')

            # Tips:Succ和Backing状态的task_id不进入逻辑
            back_status=$(echo "select Fback_status from $t_mysql_fullbackup_result where Ftask_id='$task_id'"| $DBA_MYSQL)
            tmp_bstatus=$(echo "$back_status"|tr 'a-z' 'A-Z')
            if [ "$tmp_bstatus" = "SUCC" ] || [ "$tmp_bstatus" = "BACKING" ];then
                printLog "[$f_name][$task_id]当前备份状态为:${back_status},不进入备份逻辑" "$normal_log"
            else
                printLog "[$f_name][$task_id]当前备份状态为:${back_status},进入备份逻辑" "$normal_log"
                backupFunctionMain "$backup_mode"
            fi
        else
            printLog "[$f_name][$task_id]当前事件点${cur_time}不在备份时间点(${start_time}-${end_time})内,不进入今天的备份逻辑"
        fi
    done
}


function backupMain()
{
    # Tips:
    # 本周今天之前需要备份的或者每天备份一次的
    # 并且没有在备份成功或正在备份中的数据库

    # 今天之前需要备份，但是没有在备份成功或者备份中的数据库
    sql="select Findex from $t_mysql_fullbackup_info 
    where Fstate='online' and Fbackup_address='$local_ip'
    and Fbackup_weekday<='$curweek'
    and Ftype not in 
    (select Ftype from $t_mysql_fullbackup_result
    where Fdate_time>='$monday' and Fdate_time<='$sunday' and Fback_status in ('Succ','Backing'));"
    indexs=$($DBA_MYSQL -e "$sql")
    backupChild "$indexs"

    # 每天需要备份，但是没有在备份中的数据库
    sql="select Findex from $t_mysql_fullbackup_info 
    where Fstate='online' and Fbackup_address='$local_ip'
    and Fbackup_weekday=9
    and Ftype not in 
    (select Ftype from $t_mysql_fullbackup_result
    where Fdate_time>='$monday' and Fdate_time<='$sunday' and Fback_status in ('Backing'));"
    indexs=$($DBA_MYSQL -e "$sql")
    backupChild "$indexs"
}


function checkBackStatus()
{
    # 此indexs非彼indexs
    indexs=$(echo "select Findex from $t_mysql_fullbackup_result 
    where Fdate_time>='$monday' and Fdate_time<='$sunday' 
    and Fback_status='Backing' and Fbackup_address='$local_ip';"| $DBA_MYSQL)

    for index in $(echo "$indexs")
    do
        task_id=$(echo "select Ftask_id from $t_mysql_fullbackup_result where Findex='$index';"| $DBA_MYSQL)
        backup_path=$(echo "select Fbackup_path from $t_mysql_fullbackup_result where Findex='$index';"| $DBA_MYSQL)
        backup_mode=$(echo "select Fbackup_mode from $t_mysql_fullbackup_result where Findex='$index';"| $DBA_MYSQL)
        data_source=$(echo "select Fdata_source from $t_mysql_fullbackup_result where Findex='$index';"| $DBA_MYSQL)

        tmp_bmode=$(echo "$backup_mode"| tr 'a-z' 'A-Z')
        if [ "$tmp_bmode" = "MYDUMPER" ];then
            mydumperResultCheck ""$backup_path/metadata""
        elif [ "$tmp_bmode" = "XTRABACKUP" ];then
            # 写死了backup.tar
            xtrabackupResultCheck "$backup_path/backup.tar"
        else
            return_info="备份失败,未知的备份方式"
            ech >/dev/null 2>&1 # Tips:生成一个失败
        fi

        if (($?==0));then
            echo "update $t_mysql_fullbackup_result 
            set Fbackup_size='$size',Fbackup_start_time='$f_start_time',Fbackup_end_time='$f_end_time',
            Fbackup_metadata=\"$metadata_jason\",Fback_status='Succ',Fmodify_time=now(),Fbackup_info='$return_info'
            where Ftask_id='$task_id';" | $DBA_MYSQL
            # 刷新nice值为0
            echo "update $t_mysql_fullbackup_info set Fnice=0,Fmodify_time=now() 
            where Ftype='$type_name' and Fstate='online';" | $DBA_MYSQL
        elif (($?==1));then
            echo "update $t_mysql_fullbackup_result 
            set Fback_status='Backing',Fmodify_time=now(),Fbackup_info='$return_info' 
            where Ftask_id='$task_id';" | $DBA_MYSQL
        else
            echo "update $t_mysql_fullbackup_result 
            set Fback_status='Fail',Fmodify_time=now(),Fbackup_info='$return_info'
            where Ftask_id='$task_id';" | $DBA_MYSQL
            echo "update $t_mysql_fullbackup_info set Fnice=Fnice+1,Fmodify_time=now() 
            where Ftype='$type_name' and Fstate='online';" | $DBA_MYSQL
        fi
    done
}


function main()
{
    lockFile "$0" "$f_lock" "$$"

    while ((1))
    do
        curday=$(date +"%F")
        curweek=$(date +"%w") 
        sunday="$(date -d "$(($(date +%w)-6)) days ago" +"%Y-%m-%d")" # 本周周六日期
        monday="$(date -d "$(($(date +%w)-0)) days ago" +"%Y-%m-%d")" # 本周周日日期

        printLog "[$f_name]start full backup do,please don't quit at will." "$normal_log" 
        backupMain 
        printLog "[$f_name]end full backup do,quit if you need." "$normal_log" 
        sleep 60 # 开始备份后不一定马上会生成备份文件,需要sleep

        # 检测备份成功失败状态(只检测Backing状态的task_id)
        printLog "[$f_name]start full backup check." "$normal_log" 
        #checkBackStatus

        sleep 10 # 留给退出时间
        lastExit $bd $maxr_second
    done
}


main "$@"

