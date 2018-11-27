#!/bin/bash

# description:慢日志收集
# BUGS:大文件慢日志使用工具分析瞬时吃很多CPU

base_dir="/data/repository/monitor"
common_dir="$base_dir/common"
source $common_dir/shell.cnf

f_name=$(basename "$0")
pt_query_digest="/usr/local/bin/pt-query-digest"
if (($?!=0));then
    printLog "[$f_name][$local_ip]找不到pt工具:$pt_query_digest" "$normal_log"
    exit 64
fi

slow_dir="$log_dir/mysql_slow"
mkdir -p $slow_dir

:<<comment
description:copy慢日志文件,并且清空日志
Globals:
    全局变量的使用和修改
Arguments:
    使用的参数说明
Returns:
    slow_log
comment
function getSlowLog()
{
	local port="$1"
	# slow_query_log_file可能是记录的绝对路径或者是基本路径
    sql="show global variables like 'slow_query_log_file'"
    value=$(connMySQL "$sql" "$port" "1")
    slow_query_log_file=$(echo "$value" |awk '{print $2}')
	if [ ! -f "$slow_query_log_file" ];then
        value=$(connMySQL "show global variables like 'datadir';" "$port" "1")
        datadir=$(echo "$value" | awk '{print $2}')
        slow_query_log_file="$datadir/$slow_query_log_file"
        if [ -f "$slow_query_log_file" ];then
            printLog "[$f_name][$local_ip:$port]找不到slow log($slow_query_log_file)"
            return 64
        fi
    fi 
    i=$(echo "$local_ip"| sed 's/\./_/g')
    t=$(date +"%Y%m%d")
	slow_log="$slow_dir/mysql_slow_${port}_${i}_${t}.log"
    #cat $slow_query_log_file | head -$max_slowlog_len >$slow_log # 优化慢日志太大perl脚本执行过长影响机器性能
    cat $slow_query_log_file > $slow_log && >$slow_query_log_file
    connMySQL "flush slow logs;" "$port" "0" "$local_ip" "$admin_user" "$admin_pass"
}


function reportSlowLog()
{
    local port="$1"
    local table="$2"
    local slow_log="$3"
    table_schema=$(echo "$table"| awk -F"." '{print $1}')
    table_name=$(echo "$table"| awk -F"." '{print $2}')

    /usr/bin/dos2unix $slow_log >/dev/null 2>&1  #dos2unix
    HOSTNAME=$(hostname)

    cmd="$pt_query_digest --user=$admin_user --password=$admin_pass \
--review h=$dba_host,P=$dba_port,D=$table_schema,t=$table_name \
--history h=$dba_host,P=$dba_port,D=$table_schema,t=${table_name}_history \
--no-report --limit=0%  \
--filter=' \$event->{Bytes} = length(\$event->{arg}) and \$event->{hostname}=\"$HOSTNAME\"' \
$slow_log"
    printLog "[$f_name][$local_ip:$port]开始分析上报慢日志($cmd)" "$normal_log"
    $pt_query_digest --user="$admin_user" --password="$admin_pass" \
--review h=$dba_host,P=$dba_port,D=$table_schema,t=$table_name \
--history h=$dba_host,P=$dba_port,D=$table_schema,t=${table_name}_history \
--no-report --limit=0%  \
--filter=" \$event->{Bytes} = length(\$event->{arg}) and \$event->{hostname}=\"$HOSTNAME\"" \
$slow_log
    #cd $log_dir && mv -f $slow_log $slow_dir
}


ports=$(getMySQLOnlinePort)
for port in $(echo "$ports")
do
    v=$(echo "${local_ip}_${port}"| sed 's/\./_/g')
    t_mysql_slow_ymd=$(getymdTable "$t_mysql_slow")
    t_mysql_slow_ymd=$(echo "$t_mysql_slow_ymd"|sed "s/t_mysql_slow/t_mysql_slow_${v}/g")
    printLog "[$f_name][$local_ip:$port]开始收集慢日志到$t_mysql_slow_ymd" "$normal_log"
    getSlowLog "$port"
    reportSlowLog "$port" "$t_mysql_slow_ymd" "$slow_log"
done
