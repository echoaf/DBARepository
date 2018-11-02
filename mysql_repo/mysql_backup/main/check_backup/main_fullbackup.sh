#!/bin/bash

# description:MySQL全备主函数
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

f_lock="$tmp_dir/"$(basename "$0"| awk -F"." '{print $1}')".sock"


function backupFunctionMain()
{
    backup_mode="$1"
    curtime=$(date +"%F")
    tmp_type=$(echo "$type_name"| tr 'a-z' 'A-Z')
    tmp_time=$(echo "$task_id"| awk -F"_" '{print $2}')
    backup_path="${full_backup_dir}/${tmp_type}/${tmp_time}" # 备份目录
    mkdir -p $backup_path

       # Tips:依赖mydumper_backup脚本返回值
    tmp_bmode=$(echo "$backup_mode"| tr 'a-z' 'A-Z')
    if [ "$tmp_bmode" = "MYDUMPER" ];then
        #sh $mydumper_backup --src_host="$master_host" --src_port="$master_port" --backup_path="$backup_path" >>$normal_log 2>&1
        mydumperBackup $master_host $master_port $backup_path "N" $normal_log
    elif [ "$tmp_bmode" = "XTRABACKUP" ];then
        #sh $xtrbackup_backup --src_host="$master_host" --src_port="$master_port" --backup_path="$backup_path" >>$normal_log 2>&1
        master_my_cnf="/data/mysql/$master_port/my.cnf"
        xtrabackupBackup $master_host $master_port 22 $master_my_cnf $local_ip 22 $backup_path "N" "$normal_log"
    else
        printLog "未知的备份方式$backup_mode" "$normal_log"
        ec >/dev/null 2>&1 # 生成一个错误
    fi

    if (($?==0));then
        printLog "[$task_id $type_name $master_host:$master_port] 尝试备份Succ" "$normal_log"
        tmp_bstatus="Backing"
        tmp_memo="尝试备份成功"
    else
        printLog "[$task_id $type_name $master_host:$master_port] 尝试备份Fail" "$normal_log"
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
        ('$type_name','$task_id','$curtime','$master_host:$master_port','$backup_mode',
        '$local_ip','$backup_path','$tmp_bstatus','$tmp_memo',now(),now());"
    else
        sql="update $t_mysql_fullbackup_result 
        set Ftype='$type_name',Fdate_time='$curtime',Fdata_source='$master_host:$master_port',Fbackup_mode='$backup_mode',
        Fbackup_address='$local_ip',Fbackup_path='$backup_path',Fback_status='$tmp_bstatus',Fbackup_info='$tmp_memo',
        Fmodify_time=now()
        where Ftask_id='$task_id';"
    fi
    echo "$sql"| $DBA_MYSQL
}


function backupChild()
{
    indexs="$1"
    for index in $(echo "$indexs")
    do
        type_name=$(echo "select Ftype from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
        data_source=$(echo "select Fdata_source from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
        backup_mode=$(echo "select Fbackup_mode from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
        weekday=$(echo "select Fbackup_weekday from $t_mysql_fullbackup_info where Findex='$index';"| $DBA_MYSQL)
        master_host=$(echo "$data_source"| awk -F":" '{print $1}')
        master_port=$(echo "$data_source"| awk -F":" '{print $2}')

        # Tips:task_id生成规则
        # 每周备份一次:type_name_备份日期
        # 每天备份:type_name_当天日期
        if ((${weekday}!=9));then
            task_id="${type_name}_$(date -d "$(($(date +%w)-${weekday})) days ago" +"%Y%m%d")"
        else
            task_id="${type_name}_$(date +"%Y%m%d")"
        fi

        # Tips:Succ和Backing状态的task_id不进入逻辑
        back_status=$(echo "select Fback_status from $t_mysql_fullbackup_result where Ftask_id='$task_id'"| $DBA_MYSQL)
        tmp_bstatus=$(echo "$back_status"|tr 'a-z' 'A-Z')
        if [ "$tmp_bstatus" = "SUCC" ] || [ "$tmp_bstatus" = "BACKING" ];then
            printLog "[$task_id]当前备份状态为:${back_status},不进入备份逻辑" "$normal_log"
        else
            printLog "[$task_id]当前备份状态为:${back_status},进入备份逻辑" "$normal_log"
            backupFunctionMain "$backup_mode"
        fi
    done
}


function backupMain()
{
    # Tips:
    # 本周今天之前需要备份的或者每天备份一次的
    # 并且没有在备份成功或正在备份中的数据库

    # 今天之前需要备份，但是没有在备份成功或者备份中的数据库
    indexs=$(echo "select Findex from $t_mysql_fullbackup_info 
    where Fstate='online' and Fbackup_address='$local_ip'
    and Fbackup_weekday<='$weekday'
    and Ftype not in 
    (select Ftype from $t_mysql_fullbackup_result
    where Fdate_time>='$monday' and Fdate_time<='$sunday' and Fback_status in ('Succ','Backing'));"| $DBA_MYSQL)
    backupChild "$indexs"

    # 每天需要备份，但是没有在备份中的数据库
    indexs=$(echo "select Findex from $t_mysql_fullbackup_info 
    where Fstate='online' and Fbackup_address='$local_ip'
    and Fbackup_weekday=9
    and Ftype not in 
    (select Ftype from $t_mysql_fullbackup_result
    where Fdate_time>='$monday' and Fdate_time<='$sunday' and Fback_status in ('Backing'));"| $DBA_MYSQL)
    backupChild "$indexs"
}


function checkLogicBackStatus()
{
    f_metadata="$backup_path/metadata"
    # 判断成功的逻辑是是否存在metadata
    if [ -f "$f_metadata" ];then
        printLog "[$task_id] 备份Succ" "$normal_log"

        f_start_time=$(cat "$f_metadata" | grep -w "Started dump at:"| awk -F"Started dump at: " '{print $2}')
        f_end_time=$(cat "$f_metadata" | grep -w "Finished dump at:"| awk -F"Finished dump at: " '{print $2}')

        f_slave_host=$(echo "$data_source"| awk -F":" '{print $1}')
        f_slave_port=$(echo "$data_source"| awk -F":" '{print $2}')
        f_slave_log_file=$(cat "$f_metadata"| grep -w "SHOW MASTER STATUS:" -A 3 | grep -w "Log:"| awk -F"Log:" '{print $2}' | sed 's/ //g')
        f_slave_log_pos=$(cat "$f_metadata"| grep -w "SHOW MASTER STATUS:" -A 3 | grep -w "Pos:"| awk -F"Pos:" '{print $2}' | sed 's/ //g')
        f_slave_gtid=$(cat "$f_metadata"| grep -w "SHOW MASTER STATUS:" -A 3 | grep -w "GTID:"| awk -F"GTID:" '{print $2}' | sed 's/ //g')

        f_master_host=$(cat "$f_metadata"| grep -w "SHOW SLAVE STATUS:" -A 4 | grep -w "Host:"| awk -F"Host:" '{print $2}' | sed 's/ //g')
        f_master_port=$(echo "show slave status\G" | mysql -u$repl_user -p$repl_pass -h$f_slave_host -P$f_slave_port \
            |grep -w "Master_Port:"| awk -F"Master_Port:" '{print $2}'| sed 's/ //g')
        f_master_log_file=$(cat "$f_metadata"| grep -w "SHOW SLAVE STATUS:" -A 4 | grep -w "Log:"| awk -F"Log:" '{print $2}' | sed 's/ //g')
        f_master_log_pos=$(cat "$f_metadata"| grep -w "SHOW SLAVE STATUS:" -A 4 | grep -w "Pos:"| awk -F"Pos:" '{print $2}' | sed 's/ //g')
        f_master_gtid=$(cat "$f_metadata"| grep -w "SHOW SLAVE STATUS:" -A 4 | grep -w "GTID:"| awk -F"GTID:" '{print $2}' | sed 's/ //g')

        
        metadata_jason="{'start_time':'$f_start_time','end_time':'$f_end_time','slave_host':'$f_slave_host','slave_port':'$f_slave_port','slave_log_file':'$f_slave_log_file','slave_log_pos':'$f_slave_log_pos','slave_gtid':'$f_slave_gtid','master_host':'$f_master_host','master_port':'$f_master_port','master_log_file':'$f_master_log_file','master_log_pos':'$f_master_log_pos','master_gitd':'$f_master_gtid'}"
        size=$(du -shm $backup_path | awk '{print $1}') 
        echo "update $t_mysql_fullbackup_result 
        set Fbackup_size='$size',Fbackup_start_time='$f_start_time',Fbackup_end_time='$f_end_time',
        Fbackup_metadata=\"$metadata_jason\",Fback_status='Succ',Fmodify_time=now(),Fbackup_info='备份完成'
        where Ftask_id='$task_id';" | $DBA_MYSQL
        # 刷新nice值为0
        echo "update $t_mysql_fullbackup_info set Fnice=0,Fmodify_time=now()
        where Ftype='$type_name' and Fstate='online';" | $DBA_MYSQL

    else
        if ps -ef | grep -v grep | grep "mydumper" | grep -q "$backup_path" ;then
            printLog "[$task_id] 备份中" "$normal_log"
            echo "update $t_mysql_fullbackup_result 
            set Fback_status='Backing',Fmodify_time=now(),Fbackup_info='检测还在备份中' 
            where Ftask_id='$task_id';" | $DBA_MYSQL

        else
            printLog "[$task_id] 备份Fail" "$normal_log"
            echo "update $t_mysql_fullbackup_result 
            set Fback_status='Fail',Fmodify_time=now(),Fbackup_info='metadata文件不存在'
            where Ftask_id='$task_id';" | $DBA_MYSQL
            echo "update $t_mysql_fullbackup_info set Fnice=Fnice+1,Fmodify_time=now() 
            where Ftype='$type_name' and Fstate='online';" | $DBA_MYSQL
        fi
    fi
}


function checkPhysicalBackStatus()
{
    # 检测逻辑,检测备份tar包下是否有xtrabackup_info文件,有则成功
    # 备份文件写死为backup.tar
    if tar -tf $backup_path/backup.tar xtrabackup_info >>$normal_log 2>&1 ;then
        # Tips:这里cd到另外一个目录了
        cd $backup_path && tar -xvf backup.tar xtrabackup_info

        f_start_time=$(cat xtrabackup_info | grep -w "start_time"| awk -F"= " '{print $2}')
        f_end_time=$(cat xtrabackup_info | grep -w "end_time"| awk -F"= " '{print $2}')
        f_slave_host=$(echo "$data_source" | awk -F":" '{print $1}')
        f_slave_port=$(echo "$data_source" | awk -F":" '{print $2}')
        f_slave_log_file=$(cat xtrabackup_info | grep -w "binlog_pos"| awk -F"= " '{print $2}'| awk -F"," '{print $1}'| awk '{print $2}'| sed "s/'//g")
        f_slave_log_pos=$(cat xtrabackup_info | grep -w "binlog_pos"| awk -F"= " '{print $2}'| awk -F"," '{print $2}'| awk '{print $2}'| sed "s/'//g")
        metadata_jason="{'start_time':'$f_start_time','end_time':'$f_end_time','slave_host':'$f_slave_host','slave_port':'$f_slave_port','slave_log_file':'$f_slave_log_file','slave_log_pos':'$f_slave_log_pos','slave_gtid':'','master_host':'','master_port':'','master_log_file':'','master_log_pos':'','master_gitd':''}"
        size=$(du -shm $backup_path | awk '{print $1}') 
        echo "update $t_mysql_fullbackup_result 
        set Fbackup_size='$size',Fbackup_start_time='$f_start_time',Fbackup_end_time='$f_end_time',
        Fbackup_metadata=\"$metadata_jason\",Fback_status='Succ',Fmodify_time=now(),Fbackup_info='备份完成'
        where Ftask_id='$task_id';" | $DBA_MYSQL
        # 刷新nice值为0
        echo "update $t_mysql_fullbackup_info set Fnice=0,Fmodify_time=now() 
        where Ftype='$type_name' and Fstate='online';" | $DBA_MYSQL

        # 压缩文件
        #tar zcvf backup.tar.gz backup.tar && rm -fv backup.tar
        
    else
        if [ -f "$backup_path/backup.tar" ];then
            printLog "[$task_id] 备份中" "$normal_log"
            echo "update $t_mysql_fullbackup_result
            set Fback_status='Backing',Fmodify_time=now(),Fbackup_info='检测存在backup.tar,正在备份中' 
            where Ftask_id='$task_id';" | $DBA_MYSQL
        else
            printLog "[$task_id] 备份Fail" "$normal_log"
            echo "update $t_mysql_fullbackup_result
            set Fback_status='Fail',Fmodify_time=now(),Fbackup_info='检测不存在backup.tar,备份失败' 
            where Ftask_id='$task_id';" | $DBA_MYSQL
            echo "update $t_mysql_fullbackup_info 
            set Fnice=Fnice+1,Fmodify_time=now() 
            where Ftype='$type_name' and Fstate='online';" | $DBA_MYSQL
        fi
    fi
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

        if [ ! -d "$backup_path" ];then
            printLog "[$task_id] 备份Fail" "$normal_log"
            echo "update $t_mysql_fullbackup_result
            set Fback_status='Fail',Fmodify_time=now(),Fbackup_info='数据目录不存在' 
            where Ftask_id='$task_id';" | $DBA_MYSQL
            # Tips:t_mysql_fullbackup_info表Ftype+Fstate构成唯一列
            echo "update $t_mysql_fullbackup_info set Fnice=Fnice+1,Fmodify_time=now() 
            where Ftype='$type_name' and Fstate='online';" | $DBA_MYSQL
        else
            tmp_bmode=$(echo "$backup_mode"| tr 'a-z' 'A-Z')
            if [ "$tmp_bmode" = "MYDUMPER" ];then
                #checkLogicBackStatus 
                mydumperResultCheck ""$backup_path/metadata""
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
            elif [ "$tmp_bmode" = "XTRABACKUP" ];then
                checkPhysicalBackStatus
            else
                continue
            fi
        fi
    done
}



function main()
{
    lockFile "$0" "$f_lock" "$$"

    while ((1))
    do
        curday=$(date +"%F")
        curweek=$(date +"%w") # 今天周几
        start_pos=$(date -d "$curday 00:00:00" +"%s") # 每天开始启动备份时间点
        end_pos=$(date -d "$curday 23:59:00" +"%s") # 每天结束备份时间点,但是已经在备份的事件不会退出
        #end_pos=$(date -d "$curday 10:00:00" +"%s") # 备份结束时间点
        sunday="$(date -d "$(($(date +%w)-6)) days ago" +"%Y-%m-%d")" # 本周周六日期
        monday="$(date -d "$(($(date +%w)-0)) days ago" +"%Y-%m-%d")" # 本周周日日期
        cur_pos=$(date +"%s")
                

        printLog "====================尝试进入备份逻辑主函数" "$normal_log" "green"
        if ((${cur_pos}>=${start_pos})) && ((${cur_pos}<=${end_pos})); then
            printLog "进入备份逻辑成功,此时不可以Ctrl+C" "$normal_log" "green"
            # 备份主函数
            # 今天需要备份的Ftype如下:
            # 1、今天需要备份的task_id(包括一周备份一次的和一天备份一次的):优先级最高
            # 2、本周之前备份失败的task_id(只包括一周备份一次的):优先级排后
            backupMain 
        else
            printLog "进入备份逻辑失败,当前事件点${cur_pos}不在备份时间点(${start_pos}-${end_pos})内,不进入今天的备份逻辑" "$normal_log" "green"
        fi
        sleep 10

        # 检测备份成功失败状态(只检测Backing状态的task_id)
        printLog "====================进入检测逻辑,可以ctrl+c" "$normal_log" "green"
        checkBackStatus

        printLog "====================开始sleep,进入下一次循环" "$normal_log"
        #sleep 60
        exit
    done
}


main "$@"

