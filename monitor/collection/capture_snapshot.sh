#!/bin/bash

# description:捕捉快照

base_dir="/data/repository/monitor"
common_dir="$base_dir/common"
sec_dir="$base_dir/collection/1_sec"
source $common_dir/shell.cnf

f_name=$(basename "$0")

curtimestamp=$(getCurtimestamp)
snapshot_log_dir="$log_dir/snapshot/$curtimestamp" && mkdir -p $snapshot_log_dir

function captureSnapshot()
{   
    snapshot_log_dir="$1"
    printLog "[$f_name]开始执行1sec快照捕捉脚本" "$normal_log"
    cd $collection_path
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
    cd $collection_path
    for s in ${collection_sh_mysql_1_sec[@]}
    do
    	printLog "[$f_name]start $s" $normal_log
        # 使用管理员账号
    	sh $s "$snapshot_log_dir" "$local_ip" "$port" "$admin_user" "$admin_pass" "$mysql"
    done
}

function main
{
    printLog "[$f_name]=======开始捕捉快照,日志目录$snapshot_log_dir" "$normal_log" "green"
    for ((i=1;i<=3;i++))
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
}

main "$@"

