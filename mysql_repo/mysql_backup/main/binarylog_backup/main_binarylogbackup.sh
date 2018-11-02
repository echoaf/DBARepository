#!/bin/bash

# description:MySQL增备主函数
# arthur
# 2018-10-19

# 备份目录示例
# /data/MySQL_BACKUP/BINARYLOG_BACKUP/TESTDB/172.16.112.10_10001/REPORTED
# /data/MySQL_BACKUP/BINARYLOG_BACKUP/TESTDB/172.16.112.10_10001/FAIL
# /data/MySQL_BACKUP/BINARYLOG_BACKUP/TESTDB/172.16.112.10_10001/SUCC/20181017/ -- 时间为binlog执行时间，如果获取异常则放在最后一个日期目录


github_dir="/data/code/github/repository/mysql_repo/mysql_backup"
shell_function_cnf="$github_dir/main/shell_function.cnf"
if [ ! -f "$shell_function_cnf" ] ;then
    echo "$0:找不到配置文件"
    exit 64
else
    source $shell_function_cnf
fi  
f_lock="$tmp_dir/"$(basename "$0"| awk -F"." '{print $1}')".sock"


function pullProcess()
{
    instance="$1"
    source_host="$2"
    source_port="$3"   

    tmp_i=$(echo "$instance"| tr 'a-z' 'A-Z')
    tmp_h="${source_host}_${source_port}"
    report_dir="$binarylog_backup_dir/$tmp_i/$tmp_h/REPORTED"
    mkdir -p $report_dir
    # 不存在binary file:初始化逻辑
    # 存在binary file:从最后一个binlog file开始拉取,在此步骤不检测是否binlog拉取正确,留给检测函数
    # Tips:binlog name前缀写死,为binlog.
    if ls ${report_dir}/binlog.* >/dev/null 2>&1;then
        first_binlog=$(ls ${report_dir}/binlog.* -ht | head -1 | awk -F"/" '{print $NF}')
    else
        first_binlog=$(echo "show binary logs;"| $mysql -u$repl_user -p$repl_pass -h$source_host -P$source_port -N | awk '{print $1}'| head -1)
    fi

    # Tips
    # 命令之间不能有多余的空格,因为ps是一个空格
    # report_dir后面一定要加/,不然会变成文件
    printLog "开始打开mysqlbinlog" "$normal_log"
    printLog "$mysqlbinlog -h$source_host -P$source_port -u$repl_user -p$repl_pass $first_binlog --read-from-remote-server --raw --stop-never --result-file $report_dir/" "$normal_log" 
    $mysqlbinlog -h$source_host -P$source_port -u$repl_user -p$repl_pass $first_binlog --read-from-remote-server --raw --stop-never --result-file $report_dir/ >>$normal_log 2>&1 &
}


function monitorProcess()
{
    instance="$1"
    source_host="$2"
    source_port="$3"   
    
    info="$instance $source_host:$source_port"

    pid=$(ps aux| grep "$mysqlbinlog -h$source_host -P$source_port -u$repl_user"|grep -v grep| awk '{print $2}')
    if [ -z "$pid" ];then
        printLog "[$info] mysqlbinlog进程不存在,准备拉起" "$normal_log" "red"
        pullProcess "$instance" "$source_host" "$source_port"
    else
        netstat_status=$(netstat -antpl| grep $pid | awk '{print $4}')
        if echo "show processlist"| $mysql -u$repl_user -p$repl_pass -h$source_host -P$source_port | grep "$netstat_status" >/dev/null 2>&1;then
            printLog "[$info] mysqlbinlog进程正常" "$normal_log" "red"
        else
            printLog "[$info] mysqlbinlog进程假死,kill $pid,异常重启" "$normal_log" "red"
            kill $pid
            pullProcess "$instance" "$source_host" "$source_port"
        fi
    fi
}


function reportBinaryLog()
{
    # 只负责上报REPORT目录下的binary log
    # 已REPORT目录为准
    report_dir="$1"
    binlogs=$(ls ${report_dir}/binlog.* -lht | sed 1d | awk '{print $NF}'| sort)
    for binlog in $(echo "$binlogs")
    do
        base_name=$(basename "$binlog")
        dir_name=$(dirname "$binlog")
        is_cnt=$(echo "select count(*) from $t_mysql_binarylog_result 
        where Fdata_source='${source_host}:${source_port}' and Fbinarylog_name='$base_name'"| $DBA_MYSQL)
        if ((${is_cnt}==0));then
            sql="insert into $t_mysql_binarylog_result 
            (Ftype,Fbinarylog_name,Fdate_time,Fdata_source,Fbackup_address,Fbackup_path,Fback_status,Fbackup_info,Fcreate_time,Fmodify_time) values
            ('$instance','$base_name','$today','${source_host}:${source_port}',
            '$local_ip','$dir_name','Reported','第一次report数据',now(),now());"
        else
            sql="update $t_mysql_binarylog_result 
            set Ftype='$instance',Fbinarylog_name='$base_name',Fdate_time='$today',Fbackup_address='$local_ip',
            Fback_status='Reported',Fbackup_info='再次上报数据,等待脚本更新状态',
            Fmodify_time=now()
            where Fdata_source='${source_host}:${source_port}' and Fbinarylog_name='$base_name'"
        fi
        #echo "$sql"
        echo "$sql"| $DBA_MYSQL
    done
}


function updateBinaryLog()
{
    # 更新信息表Reported状态的数据
    # 以信息表为准
    # 记得加索引
    report_dir="$1"
    succ_parent_dir="$2"
    fail_dir="$3"
    
    
    indexs=$(echo "select Findex from $t_mysql_binarylog_result 
    where Ftype='$instance' and Fback_status='Reported' 
    and Fdata_source='${source_host}:$source_port' and Fbackup_address='$local_ip' order by Findex;"| $DBA_MYSQL)
    slave_sizes=$(echo "show binary logs"| $mysql -u$repl_user -p$repl_pass -h$source_host -P$source_port) # 查一次就够了
    for index in $(echo "$indexs")
    do
        binarylog_name=$(echo "select Fbinarylog_name from $t_mysql_binarylog_result where Findex='$index';"| $DBA_MYSQL)    
        backup_path=$(echo "select Fbackup_path from $t_mysql_binarylog_result where Findex='$index';"| $DBA_MYSQL)    
        dir_size=$(ls $backup_path/$binarylog_name -l | awk '{print $5}')
        slave_size=$(echo "$slave_sizes" | grep "$binarylog_name" -w | awk '{print $2}')
        printLog "dir_size:$dir_size,slave_size:$slave_size" "$normal_log"
        # 判断文件大小
        if [ "$dir_size" = "$slave_size" ];then
            start_time=$($mysqlbinlog -vv $backup_path/$binarylog_name 2>&1 | grep "server id "| head -1 | awk -F"server id" '{print $1}'| sed 's/#//g')
            start_time=$(date -d "$start_time" +"%F %T")

            # 优化succ_dir,不存放到today,存放到binlog实际执行时间
            # 比如今天是2018-10-20,但是binlog实际执行时间是2018-01-01,则succ_dir为SUCC/20180101/
            succ_base_dir=$(date -d "$start_time" +"%Y%m%d")
            if [ -z "$succ_base_dir" ];then
                succ_base_dir="$today"
            fi
            succ_dir="${succ_parent_dir}/$succ_base_dir"
            mkdir -p $succ_dir

            back_status="Succ"
            backup_info="检测备份数据大小一致,成功"
            sql="update $t_mysql_binarylog_result 
            set Fbackup_size='$dir_size',Fstart_time='$start_time',Fback_status='$back_status',Fbackup_info='$backup_info',
            Fbackup_path='$succ_dir',
            Fmodify_time=now()
            where Findex='$index';"
            echo "$sql"| $DBA_MYSQL && mv -vf $backup_path/$binarylog_name $succ_dir/ >>$normal_log 2>&1 # 原子操作
        else
            back_status="Fail"
            backup_info="检测备份数据大小不一致,失败"
            sql="update $t_mysql_binarylog_result 
            set Fbackup_size='$dir_size',Fstart_time='$start_time',Fback_status='$back_status',Fbackup_info='$backup_info',
            Fbackup_path='$fail_dir',
            Fmodify_time=now()
            where Findex='$index';"
            echo "$sql"| $DBA_MYSQL && mv -vf $backup_path/$binarylog_name $fail_dir  >>$normal_log 2>&1
        fi
    done
}


function dealFailBinayLog()
{
    report_dir="$1"
    fail_dir="$2"
    indexs=$(echo "select Findex from $t_mysql_binarylog_result 
    where Ftype='$instance' and Fback_status='Fail' 
    and Fdata_source='${source_host}:$source_port' and Fbackup_address='$local_ip' order by Findex;"| $DBA_MYSQL)
    
    slave_sizes=$(echo "show binary logs"| $mysql -u$repl_user -p$repl_pass -h$source_host -P$source_port) # 查一次就够了,但是可能在短时间被清理了
    for index in $(echo "$indexs")
    do
        binarylog_name=$(echo "select Fbinarylog_name from $t_mysql_binarylog_result where Findex='$index';"| $DBA_MYSQL)    
        if echo "$slave_sizes"| grep -w "$binarylog_name" >/dev/null 2>&1;then
            printLog "开始单独拉失败的binlog:$binarylog_name" "$normal_log"
            # --stop-never:一直等待更多的binlog,不加此参数,只拉一个binlog
            printLog "$mysqlbinlog -h$source_host -P$source_port -u$repl_user -p$repl_pass $binarylog_name --read-from-remote-server --raw --result-file $report_dir/"
            $mysqlbinlog -h$source_host -P$source_port -u$repl_user -p$repl_pass $binarylog_name --read-from-remote-server --raw --result-file $report_dir/ >>$normal_log 2>&1
            sleep 10
            if (($?==0));then
                printLog "单独拉取binlog成功:$binarylog_name" "$normal_log"
                backup_path="$report_dir"
                back_status="Reported"
                backup_info="重新单独拉取binlog,等待更新状态"
            else
                backup_path=""
                printLog "单独拉取binlog失败:$binarylog_name" "$normal_log"
                back_status="Failagain"
                backup_info="单独拉取binlog失败,请检查失败原因"
            fi
        else
            backup_path=""
            printLog "binlog已消逝:$binarylog_name" "$normal_log"
            back_status="Deleted"
            backup_info="主库已经不存在binlog,数据已丢失,请备份其他实例的binary Log"
        fi

        sql="update $t_mysql_binarylog_result 
        set Fbackup_path='$backup_path',Fback_status='$back_status',Fbackup_info='$backup_info',
        Fmodify_time=now()
        where Findex='$index';"
        echo "$sql"| $DBA_MYSQL
       
    done
}


function checkBinaryLog()
{

    instance="$1"
    source_host="$2"
    source_port="$3"   
    #/data/MySQL_BACKUP/BINARYLOG_BACKUP/TESTDB/172.16.112.10_10001/REPORTED
    #/data/MySQL_BACKUP/BINARYLOG_BACKUP/TESTDB/172.16.112.10_10001/FAIL
    #/data/MySQL_BACKUP/BINARYLOG_BACKUP/TESTDB/172.16.112.10_10001/SUCC/20181017/ 

    tmp_i=$(echo "$instance"| tr 'a-z' 'A-Z')
    tmp_h="${source_host}_${source_port}"
    today="$(date +"%Y%m%d")"
    report_dir="$binarylog_backup_dir/$tmp_i/$tmp_h/REPORTED"
    fail_dir="$binarylog_backup_dir/$tmp_i/$tmp_h/FAIL"
    succ_parent_dir="$binarylog_backup_dir/$tmp_i/$tmp_h/SUCC"
    
    reportBinaryLog "$report_dir"
    mkdir -p $fail_dir $succ_parent_dir
    updateBinaryLog "$report_dir" "$succ_parent_dir" "$fail_dir"
    dealFailBinayLog "$report_dir" "$fail_dir"
    
}


function main()
{
    lockFile "$0" "$f_lock" "$$"

    while ((1))
    do
        indexs=$(echo "select Findex from $t_mysql_binarylog_info where Fbackup_address='$local_ip' and Fstate='online';"| $DBA_MYSQL)

        printLog "======进入mysqlbinlog监控逻辑" "$normal_log" 
        for index in $(echo "$indexs")
        do
            instance=$(echo "select Ftype from $t_mysql_binarylog_info where Findex='$index'"| $DBA_MYSQL)
            data_source=$(echo "select Fdata_source from $t_mysql_binarylog_info where Findex='$index'"| $DBA_MYSQL)
            source_host=$(echo "$data_source"| awk -F":" '{print $1}')
            source_port=$(echo "$data_source"| awk -F":" '{print $2}')
            printLog "[$instance-$source_host:$source_port] 进入mysqlbinlog监控逻辑" "$normal_log" 
            monitorProcess "$instance" "$source_host" "$source_port"
        done

        printLog "======进入binlog上报逻辑,不能使用ctrl+c" "$normal_log" 
        for index in $(echo "$indexs")
        do
            instance=$(echo "select Ftype from $t_mysql_binarylog_info where Findex='$index'"| $DBA_MYSQL)
            data_source=$(echo "select Fdata_source from $t_mysql_binarylog_info where Findex='$index'"| $DBA_MYSQL)
            source_host=$(echo "$data_source"| awk -F":" '{print $1}')
            source_port=$(echo "$data_source"| awk -F":" '{print $2}')
            printLog "[$instance-$source_host:$source_port] 进入binlog上报逻辑" "$normal_log" 
            checkBinaryLog "$instance" "$source_host" "$source_port"
        done

        printLog "======开始sleep,进入下一次循环" "$normal_log"
        sleep 60
    done
}


main "$@"


