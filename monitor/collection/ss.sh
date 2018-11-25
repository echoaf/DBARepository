#!/bin/bash


log_dir="$1"
local_ip="$2"
h=$(echo "$local_ip"| sed 's/\./_/g')
local_name=$(basename $0)

file="$log_dir/${h}_${local_name}.log"
ss=$(which ss)

if [ ! -f "$ss" ];then
    echo "找不到ss命令,exit" >>$file
    exit 64
fi

echo "" >>$file
$ss -ipaoem >>$file &

