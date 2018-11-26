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
    printLog "[$f_name]开始执行System-1sec快照捕捉脚本" "$normal_log"
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
    printLog "[$f_name]开始执行MySQL-1sec快照捕捉脚本" "$normal_log"
    cd $collection_path
    for s in ${collection_sh_mysql_1_sec[@]}
    do
    	printLog "[$f_name]start $s" $normal_log
        # 使用管理员账号
    	sh $s "$snapshot_log_dir" "$local_ip" "$port" "$admin_user" "$admin_pass" "$mysql"
    done
}


function captureSnapshotMain()
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
        sleep 1
    done
}


function checkSystemLoad()
{
    loadavg_1_min=$(cat /proc/loadavg | awk '{print $1}')
    loadavg_1_min=$(echo "$loadavg_percent_max" 1 | awk '{printf "%0.2f\n" ,$1+$2}')

    loadavg_max=$(getKV "loadavg_max" "$local_ip" "0" "system")   

    loadavg_percent=$(getKV "loadavg_percent" "$local_ip" "0" "system")   
    cpu_num=$(cat /proc/cpuinfo |grep "processor"|wc -l) # 逻辑CPU个数
    loadavg_percent_max=$(echo "$cpu_num" "$loadavg_percent" 100 | awk '{printf "%0.2f\n" ,$1*$2/$3}')

    printLog "当前1min平均负载:$loadavg_1_min(阈值:loadavg_percent_max:$loadavg_percent_max,loadavg_max:$loadavg_max)" "$normal_log"
    if [ "$(echo "$loadavg_1_min > $loadavg_percent_max" | bc)" = "1" ] || [ "$(echo "$loadavg_1_min > $loadavg_max" | bc)" = "1" ];then
        E="0"
    else
        E="1"
    fi
    return $E
}


function checkSystemCPU()
{
    cpu_percent=$(getKV "cpu_percent" "$local_ip" "0" "system")   
    # CPU利用率=100*(user+nice+system)/(user+nice+system+idle)
    # 每一个cpu快照均为( user、nice、system、idle、iowait、irq、softirq、stealstolen、guest )的9元组;
    # Example:
    # cat /proc/stat | head -1
    # cpu  19770 37 19106 24779304 2258 0 570 0 0 0
    cur_cpu_percent=$(cat /proc/stat | head -1| awk '{print ($2+$3+$4+$6+$7+$8)*100/($2+$3+$4+$5+$6+$7+$8)}')
    printLog "当前CPU使用率:$cur_cpu_percent(阈值:$cpu_percent)" "$normal_log"
    if [ "$(echo "$cur_cpu_percent > $cpu_percent" | bc)" = "1" ];then
        E="0"
    else
        E="1"
    fi
    return $E
}


function checkSystem()
{   
    checkSystemLoad   
    if (($?==0));then
        E=0
        return "$E"
    fi

    checkSystemCPU
    if (($?==0));then
        E=0
        return "$E"
    fi
    E="1"
    return "$E"
}


function main()
{
    checkSystem
    if (($?==0));then
        captureSnapshotMain
    fi
}


main "$@"

