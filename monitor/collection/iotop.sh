#!/bin/bash


log_dir="$1"
local_ip="$2"
h=$(echo "$local_ip"| sed 's/\./_/g')
local_name=$(basename $0)

file="$log_dir/${h}_${local_name}.log"
iotop=$(which iotop)

if [ ! -f "$iotop" ];then
    echo "找不到iotop命令,exit" >>$file
    exit 64
fi

echo "" >>$file
$iotop -b -t -d 1 -n 1 >>$file &

