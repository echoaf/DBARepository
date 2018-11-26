#!/bin/bash

log_dir="$1"
local_ip="$2"
h=$(echo "$local_ip"| sed 's/\./_/g')
local_name=$(basename $0)

file="$log_dir/${h}_${local_name}.log"

# Tips:top加-b参数置于&后台
echo "" >>$file
top -b -c -d 1 -n 1 >>$file 

