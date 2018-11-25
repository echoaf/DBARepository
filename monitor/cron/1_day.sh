#!/bin/bash

base_dir="/data/repository/monitor"
common_dir="$base_dir/common"
shell_cnf="$common_dir/shell.cnf"
source $shell_cnf

f_name=$(basename $0)


printLog "[$f_name]======begin deal 1_day======" "$normal_log"
values=$(getCommonScript "1_day" "$local_ip")

for value in $(echo "$values")
do
    person_value=$(getPersonScript "$value" "1_day" "$local_ip")
    basename=$(echo "$person_value"| awk -F":" '{print $1}')
    running_state=$(echo "$person_value"| awk -F":" '{print $2}')
    script_file="$collection_path/$basename"

    getDealStatusDay "$local_ip" "$basename" 
    if (($?==0));then
	    printLog "[$running_state $basename]start deal" $normal_log
        dealScript "$script_file" "$running_state"
        if (($?==0));then
           # deal_status更新为1
            updateDealStatus "$local_ip" "$basename" "1"
        fi
    else
	    printLog "[$running_state $basename]is not deal time" $normal_log
        # deal_status保持原样
        updateDealStatus "$local_ip" "$basename"
    fi
done


