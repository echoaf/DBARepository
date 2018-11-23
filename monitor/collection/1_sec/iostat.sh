#!/bin/bash

log_dir="$1"
local_ip="$2"
h=$(echo "$local_ip"| sed 's/\./_/g')
local_name=$(basename $0)

file="$log_dir/${h}_${local_name}.log"

echo "" >>$file
iostat -c -d -p -t -x 1 1 >>$file &

