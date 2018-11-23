#!/bin/bash

log_dir="$1"
local_ip="$2"
port="$3"
dba_user="$4"
dba_pass="$5"
mysql="$6"
h=$(echo "$local_ip"| sed 's/\./_/g')
local_name=$(basename $0)

file="$log_dir/${h}_${local_name}_${port}.log"

sql="show full processlist;"
echo "" >>$file
$mysql -u$dba_user -p$dba_pass -h$local_ip -P$port -A -e "$sql" >$file

