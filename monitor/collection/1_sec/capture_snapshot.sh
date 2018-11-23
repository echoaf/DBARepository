#!/bin/bash

# description:捕捉快照

base_dir="/data/repository/monitor"
common_dir="$base_dir/common"
sec_dir="$base_dir/collection/1_sec"
source $common_dir/shell.cnf

f_lock="$tmp_dir/"$(basename "$0"| awk -F"." '{print $1}')".sock"
f_name=$(basename "$0")

bd=$(date +%s) # 脚本开始执行时间
maxr_second=3600 # 脚本执行时间


function captureSnapshot()
{   
    snapshot_log_dir="$1"
    printLog "[$f_name]开始执行1sec快照捕捉脚本" "$normal_log"
    cd $collection_path_1_sec
    for s in ${collection_sh_system_1_sec[@]}
    do
    	printLog "[$f_name]start $s" $normal_log
    	sh $s "$snapshot_log_dir" "$local_ip" #&
    done
}


function captureMySQLSnapshot()
{   
    snapshot_log_dir="$1"
    port="$2"
    printLog "[$f_name]开始执行1sec快照捕捉脚本" "$normal_log"
    cd $collection_path_1_sec
    for s in ${collection_sh_mysql_1_sec[@]}
    do
    	printLog "[$f_name]start $s" $normal_log
        # 使用管理员账号
    	sh $s "$snapshot_log_dir" "$local_ip" "$port" "$admin_user" "$admin_pass" "$mysql"
    done
}


function main()
{
    debug="$1"
    if [ -z "$debug" ];then
        sleep_time=60
        debug=0
    else
        sleep_time=1
        debug=1
    fi
    
    lockFile "$0" "$f_lock" "$$"
 
    while ((1))
    do
        curtimestamp=$(getCurtimestamp)
        snapshot_log_dir="$log_dir/snapshot/$curtimestamp" && mkdir -p $snapshot_log_dir

        printLog "[$f_name]=======开始捕捉快照,日志目录$snapshot_log_dir" "$normal_log" "green"
        for ((i=0;i<3;i++))
        do
            printLog "[$f_name]第${i}次捕捉" "$normal_log" "green"
            captureSnapshot "$snapshot_log_dir" 
            ports=$(getMySQLOnlinePort)
            for port in $(echo "$ports")
            do
                captureMySQLSnapshot "$snapshot_log_dir" "$port"
            done
            sleep 0.1
        done

        if [ "$debug" == "1" ];then
            printLog "[$f_name]调试状态,退出" "$normal_log" "green"
            exit
        fi
    done
    
    lastExit $bd $maxr_second
}

main "$@"
