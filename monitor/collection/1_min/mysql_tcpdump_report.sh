#!/bin/bash

# description:使用pt工具分析tcpdump包
# arthur
# 2018-11-14

base_dir="/data/repository/monitor"
common_dir="$base_dir/common"
source $common_dir/shell.cnf

f_name=$(basename "$0")

pt_query_digest=$(which pt-query-digest 2>&1)
tcpdump=$(which tcpdump 2>&1)
timeout=$(which timeout 2>&1)
if [ ! -f $pt_query_digest ] || [ ! -f "$tcpdump" ] || [ ! -f "$timeout" ];then
    printLog "[$f_name][$local_ip]找不到工具,exit" "$normal_log"
    exit 64
fi


function reportPackages()
{
    port="$1"
    table="$2"
    package_file="$3"
    table_schema=$(echo "$table"| awk -F"." '{print $1}')
    table_name=$(echo "$table"| awk -F"." '{print $2}')

    cmd="$tcpdump -x -nn -q -tttt -r $package_file | $pt_query_digest \
        --charset=utf8 --type=tcpdump \
        --watch-server $local_ip:$port \
        --review h=$dba_host,P=$dba_port,u=$admin_user,p=$admin_pass,D=$table_schema,t=$table_name \
        --history h=$dba_host,P=$dba_port,u=$admin_user,p=$admin_pass,D=$table_schema,t=${table_name}_history \
        --no-report --limit=0% \
        --filter=' \$event->{Bytes} = length(\$event->{arg}) and \$event->{hostname}=\"$HOSTNAME\"'"

    printLog "[$f_name][$local_ip:$port]开始分析tcpdump($cmd)" "$normal_log"

    $tcpdump -x -nn -q -tttt -r $package_file | $pt_query_digest \
        --charset=utf8 --type=tcpdump \
        --watch-server $local_ip:$port \
        --review h=$dba_host,P=$dba_port,u=$admin_user,p=$admin_pass,D=$table_schema,t=$table_name \
        --history h=$dba_host,P=$dba_port,u=$admin_user,p=$admin_pass,D=$table_schema,t=${table_name}_history \
        --no-report --limit=0%  \
        --filter=" \$event->{Bytes} = length(\$event->{arg}) and \$event->{hostname}=\"$HOSTNAME\""

    #$timeout $catch_tcpdump_time $tcpdump -s 65535 -x -nn -q -tttt -i any -c $catch_tcpdump_size port $local_port | $pt_query \
    #    --charset=utf8 --type=tcpdump \
    #    --watch-server ${local_ip}:${local_port} \
    #    --review h=$dba_host,P=$dba_port,u=$dba_user,p=$dba_pass,D=$table_schema,t=$table_name \
    #    --history h=$dba_host,P=$dba_port,u=$dba_user,p=$dba_pass,D=$table_schema,t=$table_name_history \
    #    --no-report --limit=0%  \
    #    --filter=" \$event->{Bytes} = length(\$event->{arg}) and \$event->{hostname}=\"$hostname\""
}



function catchPackages()
{
    ports="$1"
    dump_file="$2"
    cmd="$timeout $catch_tcpdump_time $tcpdump -s 65535 -x -nn -q -tttt -i any -c $catch_tcpdump_size \("
    for port in $(echo "$ports")
    do
        cmd="$cmd port $port or"
    done
    cmd="$cmd \) -w $dump_file"
    cmd=$(echo "$cmd"| sed 's|or \\) -w|\\) -w|g')
    printLog "[$f_name][$local_ip]开始抓包($cmd)" "$normal_log"
    echo "$cmd" > /tmp/mysql_tcpdump_catch.sh
    sh /tmp/mysql_tcpdump_catch.sh
}



function main()
{
    sleep_time=$(randNum 1 $tcpdump_gaplock_time) 
    #sleep $sleep_time # 每次开始抓包前sleep一段时间,避免每次都在同一分钟同一个点抓包
    
    sock_file="$tmp_dir/$f_name.sock"
    lookSockFile "$sock_file"
    if (($?==1));then
        printLog "[$f_name][$local_ip]当前有相同脚本正在执行,exit" "$normal_log"
        exit 64
    else
        updateSockFile "$sock_file" "1"
    fi
    
    #$timeout $catch_tcpdump_time $tcpdump -s 65535 -x -nn -q -tttt -i any -c $catch_tcpdump_size \(port 10000 or port 11000\) -w dump_file    
    h=$(echo "$local_ip"| sed 's/\./_/g')
    t=$(date +"%Y%m%d_%H%M%S")
    dump_file="$tmp_dir/mysql_tcpdump_${h}_${t}.log"
    ports=$(getMySQLOnlinePort)

    catchPackages "$ports" "$dump_file"
    HOSTNAME=$(hostname)
    for port in $(echo "$ports")
    do
        v=$(echo "${local_ip}_${port}"| sed 's/\./_/g')
        t_mysql_tcpdump_ymd=$(getymdTable "$t_mysql_tcpdump")
        t_mysql_tcpdump_ymd=$(echo "$t_mysql_tcpdump_ymd"|sed "s/t_mysql_tcpdump/t_mysql_tcpdump_${v}/g")
        printLog "[$f_name][$local_ip:$port]开始收集tcpdump到$t_mysql_tcpdump_ymd" "$normal_log"
        reportPackages "$port" "$t_mysql_tcpdump_ymd" "$dump_file"
    done

    updateSockFile "$sock_file" "0"
}


main
