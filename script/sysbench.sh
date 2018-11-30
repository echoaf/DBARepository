#!/bin/bash

# description:sysbench压测

cwd=$(cd $(dirname $0);pwd)
log="$cwd/log"
mkdir -p $log

normal_log="$log/normal_log"
base_dir="$log/result" # 结果基目录


sysbench="/usr/local/bin/sysbench"
oltp_lua="/mnt/source/sysbench-0.5/sysbench/tests/db/oltp.lua"
update_index_lua="/mnt/source/sysbench-0.5/sysbench/tests/db/update_index.lua"
db_host="10.2.36.39"
db_port="11306"
db_user="arthur"
db_password="arthur"
table_schema="sysbench_db" # 数据库,需要提前创建好
table_count="32" # prepare生成表数量
table_size="2000000" # 每个表大小
max_time="300" # run每次压测时间
num_threads=("12" "24" "32" "64" "128" "256" "484" "512" "768" "1024") # 压测线程数



function printLog()
{   
    content="$1"
    normal_log="$2"
    echo "[$(date +"%F %T")] $content"
    echo "[$(date +"%F %T")] $content" >> $normal_log 2>&1
}


function flushSystem()
{
    sync 
    echo 3 > /proc/sys/vm/drop_caches 
    swapoff -a && swapon -a 
    sleep 2
    sync 
    echo 3 > /proc/sys/vm/drop_caches 
    swapoff -a && swapon -a 
}



function prepareSysbench()
{
    exec_mode="Prepare"
    printLog "[info][$exec_mode] start......" "$normal_log"
    $sysbench \
        --test=$oltp_lua \
        --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password="$db_password" \
        --mysql-db=$table_schema --oltp-tables-count=$table_count --oltp-table-size=$table_size \
        --report-interval=10 --oltp-dist-type=uniform --rand-init=on --max-requests=0 \
        --oltp-test-mode=nontrx --oltp-nontrx-mode=select \
        --max-time=$max_time --num-threads=12 \
        --oltp-skip-trx=on \
        --oltp-read-only=on \
        prepare
    printLog "[info][$exec_mode] end......" "$normal_log"
}


function runReadandwriteSysbench()
{
    num_thread="$1"
    exec_mode="Read and Write"
    printLog "[info][$exec_mode] start......" "$normal_log"
    /usr/local/bin/sysbench \
        --test=$oltp_lua \
        --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password="$db_password" \
        --mysql-db=$table_schema --oltp-tables-count=$table_count --oltp-table-size=$table_size \
        --report-interval=10 \
        --rand-init=on --max-requests=0 \
        --oltp-test-mode=nontrx --oltp-nontrx-mode=select \
        --max-time=$max_time --num-threads=$num_thread \
        --oltp-read-only=off \
        run
    printLog "[info][$exec_mode] end......" "$normal_log"
}


function runReadonlySysbench()
{
    num_thread="$1"
    exec_mode="Read Only"
    printLog "[info][$exec_mode] start......" "$normal_log"
    $sysbench \
        --test=$oltp_lua \
        --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password="$db_password" \
        --mysql-db=$table_schema --oltp-tables-count=$table_count --oltp-table-size=$table_size \
        --report-interval=10 --oltp-dist-type=uniform --rand-init=on --max-requests=0 \
        --oltp-test-mode=nontrx --oltp-nontrx-mode=select \
        --max-time=$max_time --num-threads=$num_thread \
        --oltp-skip-trx=on \
        --oltp-read-only=on \
        run
    printLog "[info][$exec_mode] end......" "$normal_log"
}


function runUpdataonlySysbench()
{
    num_thread="$1"
    exec_mode="Update Only"
    printLog "[info][$exec_mode] start......" "$normal_log"
    # --mysql-ignore-errors=1062:跳过有可能的唯一键冲突错误
    $sysbench \
        --test=$update_index_lua \
        --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password="$db_password" \
        --mysql-db=$table_schema --oltp-tables-count=$table_count --oltp-table-size=$table_size \
        --report-interval=10 --rand-init=on --max-requests=0 \
        --max-time=20 --num-threads=$num_thread \
        --mysql-ignore-errors=1062 \
        --oltp-read-only=off \
        run
    printLog "[info][$exec_mode] end......" "$normal_log"
}



function sysbenchMain()
{
    flushSystem
    info="table_schema:$table_schema,table_count:$table_count,table_size:$table_size,max_time:$max_time"
    prepareSysbench
    flushSystem

    for t in ${num_threads[@]}
    do
        info="$info,num_thread:$t"
        runSysbench "$t"
        flushSystem
    done
}



function main()
{
    sysbenchMain
}


main "$@"

