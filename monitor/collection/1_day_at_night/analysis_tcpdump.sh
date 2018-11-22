#!/bin/bash
# description:抓取tcpdump包分析generl log
# arthur
# 2018-11-14

# 试用场景:
# 某段时间qps上涨,需要抓包分析那段时间跑了些什么sql

# Tips
# 脚本置于后台执行,可以放到screen里面,超时退出

bd=$(date +%s) # 脚本开始执行时间
local_ip=$(/sbin/ifconfig|grep "inet "|awk '{print $2}'|grep -Ev "127.0.0.1|172.17"|head -1) # centos-7
#local_ip=$(/sbin/ifconfig|grep "inet addr"|awk '{print $2}'|awk -F":" '{print $2}'|grep -Ev "127.0.0.1|172.17"|head -1) # centos-6
hostname=$(hostname)


# 修改以下变量
tcpdump="/usr/sbin/tcpdump"
pt_query="/usr/local/bin/pt-query-digest"
timeout="/usr/bin/timeout"

local_port="10000" # 抓取端口
normal_log="normal.log"

# 数据库连接信息
# Tips:库表不存在的话,会自动创建,前提是用户需要有权限
report_host="172.16.112.10"
report_port="10000"
report_user="arthur_master"
report_pass="arthur_master"
table_schema="sql_statistics_db"
table_name_pre="t_sql"
tmp_ip=$(echo "$local_ip"| sed 's/\./_/g')
cur_day=$(date +"%Y%m%d")
table_name="${table_name_pre}_${tmp_ip}_${local_port}_${cur_day}"
table_name_history="${table_name}_history"


# 抓包参数,两个参数满足其他退出抓包
# 抓包60s,然后休眠一段时间(在120-300s内),继续抓包,并且脚本执行172800s后退出
# Tips
# 1、sleep_min_time=sleep_max_time,可以设置每次sleep同样的时间
# 2、catch_time=maxr_second,可以一直抓包,适用于下线实例前的抓包
catch_time="60" # 每次抓包时长
catch_size="20000" # 每次抓包大小
sleep_min_time="120" # 休眠最小时长
sleep_max_time="300" # 休眠最大时长
maxr_second=172800 # 脚本执行时间,抓两天包


# 随机sleep
function randNum(){
    min=$1
    max=$(($2-$min+1))
    num=$(date +%s%N)
    echo $(($num%$max+$min))
}


# 超时退出
function lastExit()
{
    bd="$1"
    maxr_second="$2"
    if [ -z "$bd" ];then
        bd="0"
    fi
    if [ -z "$maxr_second" ];then
        maxr_second="1"
    fi
    ed=$(date +%s)
    vd=$(echo "$ed -$bd" | bc)
    if ((${vd}>=${maxr_second}));then #执行超过时间推出
        exit
    fi
}

# 打日志
function printLog()
{
    content="$1"
    normal_log="$2"
    color="$3"
    if [ -z "$normal_log" ];then
        normal_log="$log_dir/shell.log"
    fi
    if [ -z "$color" ];then
        color="green"
    fi
    echo "[$(date +"%F %T")] $content" >>$normal_log 2>&1
    case "$color" in
        green) echo -e "[$(date +"%F %T")] \033[32m$content \033[0m";;
        red) echo -e "[$(date +"%F %T")] \033[31m$content \033[0m";;
        normal) echo -e "[$(date +"%F %T")] $content";;
        *) echo -e "[$(date +"%F %T")] \033[32m$content \033[0m";;
    esac
}



function analysisTcpdump()
{
    # 上报库表
    printLog "开始抓包分析" "$normal_log"
    $timeout $catch_time $tcpdump -s 65535 -x -nn -q -tttt -i any -c $catch_size port $local_port | $pt_query \
        --charset=utf8 --type=tcpdump \
        --watch-server ${local_ip}:${local_port} \
        --review h=$report_host,P=$report_port,u=$report_user,p=$report_pass,D=$table_schema,t=$table_name \
        --history h=$report_host,P=$report_port,u=$report_user,p=$report_pass,D=$table_schema,t=$table_name_history \
        --no-report --limit=0%  \
        --filter=" \$event->{Bytes} = length(\$event->{arg}) and \$event->{hostname}=\"$hostname\""
    # 本地分析
    #$timeout $catch_time $tcpdump -s 65535 -x -nn -q -tttt -i any -c $catch_size port $local_port | $pt_query \
    #    --charset=utf8 --type=tcpdump \
    #    --watch-server ${local_ip}:${local_port} \
    printLog "抓包分析结束" "$normal_log"
}


function main()
{
    if [ ! -f "$timeout" ] || [ ! -f "$tcpdump" ] || [ ! -f "$pt_query" ];then
        echo "命令不存在,exit"
        exit 64
    fi

    deal_status="0" # 控制tcpdump开关,避免多个tcpdump同时跑
    while ((1))
    do
        if ((${deal_status}==0));then
            analysisTcpdump
            deal_status=1
        else
            range_time=$(randNum $sleep_min_time $sleep_max_time) #5分钟到10分钟内随机sleep
            printLog "休眠${range_time}s后再次执行抓包" "$normal_log"
            sleep $range_time
            deal_status=0
        fi
        lastExit $bd $maxr_second
    done
}


main
