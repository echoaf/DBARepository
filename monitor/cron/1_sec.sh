#!/bin/bash

base_dir="/data/repository/monitor"
common_dir="$base_dir/common"
shell_cnf="$common_dir/shell.cnf"
source $shell_cnf

f_lock="$tmp_dir/"$(basename "$0"| awk -F"." '{print $1}')".sock"
f_name=$(basename "$0")
bd=$(date +%s) # 脚本开始执行时间
maxr_second=$(getKV "maxr_second" "$local_ip" "0" "mysql") 


function dealScript1Sec()
{
    printLog "[$f_name]start deal 1_sec======" "$normal_log"
    values=$(getCommonScript "1_sec" "$local_ip")
    for value in $(echo "$values")
    do
        person_value=$(getPersonScript "$value" "1_sec" "$local_ip")
        basename=$(echo "$person_value"| awk -F":" '{print $1}')
        running_state=$(echo "$person_value"| awk -F":" '{print $2}')
        script_file="$collection_path/$basename"
    	printLog "[$running_state $basename]start deal" $normal_log
        dealScript "$script_file" "$running_state"
        if (($?==0));then
            updateDealStatus "$local_ip" "$basename" "1"
        fi
    done
}


function main()
{
    debug="$1"
    lockFile "$0" "$f_lock" "$$"
    while ((1))
    do
        dealScript1Sec
        if [ -z "$debug" ];then
            printLog "[$f_name]调试状态,退出" "$normal_log" "green"
            exit
        fi
        sleep 1
        lastExit $bd $maxr_second
    done
}


main "$@"
    

