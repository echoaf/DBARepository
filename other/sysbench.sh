#!/bin/bash

# description:sysbench压测

cwd=$(cd $(dirname $0);pwd)
log="$cwd/log"
mkdir -p $log

normal_log="$log/normal_log"
base_dir="$log/result" # 结果目录
mkdir -p $base_dir

mysql="/usr/bin/dba/mysql"
sysbench="/usr/local/bin/sysbench"
oltp_lua="/mnt/source/sysbench-0.5/sysbench/tests/db/oltp.lua"
update_index_lua="/mnt/source/sysbench-0.5/sysbench/tests/db/update_index.lua"
db_host="10.2.36.39"
db_port="11306"
db_user="arthur"
db_password="arthur"
table_schema="sysbench_db" # 数据库,需要提前创建好
#table_count="32" # prepare生成表数量
#table_size="2000000" # 每个表大小
#max_time="300" # run每次压测时间
#num_threads=("12" "24" "32" "64" "128" "256" "484" "512" "768" "1024") # 压测线程数
table_count="32" # prepare生成表数量
table_size="10000" # 每个表大小
max_time="20" # run每次压测时间
num_threads=("12" "24")

for file in $mysql $sysbench_db $oltp_lua $update_index_lua
do
    if [ ! -f "$file" ];then
        echo "找不到文件$file,exit"
        exit 64
    fi
done


function printLog()
{   
    content="$1"
    normal_log="$2"
    echo "[$(date +"%F %T")] $content"
    echo "[$(date +"%F %T")] $content" >> $normal_log 2>&1
}


function restartMySQL()
{
    echo "restart mysqld"
}


function flushSystem()
{
    sync 
    echo 3 > /proc/sys/vm/drop_caches 
    swapoff -a && swapon -a 
    sleep 1
    sync 
    echo 3 > /proc/sys/vm/drop_caches 
    swapoff -a && swapon -a 
}



function prepareSysbench()
{
    info="$1"
    save_log="$base_dir/${db_host}_${db_port}_prepareSysbench_$(date +"%Y%m%d%H%M%S").log"
    exec_mode="Prepare"
    info="[$info][$exec_mode]"
    printLog "$info start..." "$save_log"
    $sysbench \
        --test=$oltp_lua \
        --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password="$db_password" \
        --mysql-db=$table_schema --oltp-tables-count=$table_count --oltp-table-size=$table_size \
        --report-interval=10 --oltp-dist-type=uniform --rand-init=on --max-requests=0 \
        --oltp-test-mode=nontrx --oltp-nontrx-mode=select \
        --max-time=$max_time --num-threads=12 \
        --oltp-skip-trx=on \
        --oltp-read-only=on \
        prepare >> $save_log 2>&1
    printLog "$info end..." "$save_log"
}


function cleanupSysbench()
{
    info="$1"
    save_log="$base_dir/${db_host}_${db_port}_cleanupSysbench_$(date +"%Y%m%d%H%M%S").log"
    exec_mode="cleanup"
    info="[$info][$exec_mode]"
    printLog "$info start..." "$save_log"
    $sysbench \
        --test=$oltp_lua \
        --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password="$db_password" \
        --mysql-db=$table_schema --oltp-tables-count=$table_count --oltp-table-size=$table_size \
        --report-interval=10 --oltp-dist-type=uniform --rand-init=on --max-requests=0 \
        --oltp-test-mode=nontrx --oltp-nontrx-mode=select \
        --max-time=$max_time --num-threads=12 \
        --oltp-skip-trx=on \
        --oltp-read-only=on \
        cleanup >> $save_log 2>&1
    printLog "$info end..." "$save_log"
}


function runReadandwriteSysbench()
{
    info="$1"
    num_thread="$2"
    exec_mode="Read and Write"
    info="[$info][$exec_mode][$num_thread]"
    save_log="$base_dir/${db_host}_${db_port}_runReadandwriteSysbench_${num_thread}_$(date +"%Y%m%d%H%M%S").log"
    printLog "$info start..." "$save_log"
    /usr/local/bin/sysbench \
        --test=$oltp_lua \
        --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password="$db_password" \
        --mysql-db=$table_schema --oltp-tables-count=$table_count --oltp-table-size=$table_size \
        --report-interval=10 \
        --rand-init=on --max-requests=0 \
        --oltp-test-mode=nontrx --oltp-nontrx-mode=select \
        --max-time=$max_time --num-threads=$num_thread \
        --oltp-read-only=off \
        run >>$save_log 2>&1
    printLog "$info end..." "$save_log"
}


function runReadonlySysbench()
{
    info="$1"
    num_thread="$2"
    exec_mode="Read Only"
    info="[$info][$exec_mode][$num_thread]"
    save_log="$base_dir/${db_host}_${db_port}_runReadonlySysbench_${num_thread}_$(date +"%Y%m%d%H%M%S").log"
    printLog "$info start..." "$save_log"
    $sysbench \
        --test=$oltp_lua \
        --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password="$db_password" \
        --mysql-db=$table_schema --oltp-tables-count=$table_count --oltp-table-size=$table_size \
        --report-interval=10 --oltp-dist-type=uniform --rand-init=on --max-requests=0 \
        --oltp-test-mode=nontrx --oltp-nontrx-mode=select \
        --max-time=$max_time --num-threads=$num_thread \
        --oltp-skip-trx=on \
        --oltp-read-only=on \
        run >>$save_log 2>&1
    printLog "$info end..." "$save_log"
}


function runUpdataonlySysbench()
{
    info="$1"
    num_thread="$2"
    exec_mode="Update Only"
    info="[$info][$exec_mode][$num_thread]"
    save_log="$base_dir/${db_host}_${db_port}_runUpdataonlySysbench_${num_thread}_$(date +"%Y%m%d%H%M%S").log"
    printLog "$info start..." "$save_log"
    # --mysql-ignore-errors=1062:跳过有可能的唯一键冲突错误
    $sysbench \
        --test=$update_index_lua \
        --mysql-host=$db_host --mysql-port=$db_port --mysql-user=$db_user --mysql-password="$db_password" \
        --mysql-db=$table_schema --oltp-tables-count=$table_count --oltp-table-size=$table_size \
        --report-interval=10 --rand-init=on --max-requests=0 \
        --max-time=20 --num-threads=$num_thread \
        --mysql-ignore-errors=1062 \
        --oltp-read-only=off \
        run >>$save_log 2>&1
    printLog "$info end..." "$save_log"
}


function sysbenchMain()
{
    flushSystem

    info_ori="table_schema:$table_schema,table_count:$table_count,table_size:$table_size,max_time:$max_time"

    sql="create database if not exists ${table_schema};"
    value=$($mysql -u$db_user -p$db_password -h$db_host -P$db_port -e "$sql" 2>&1)
    if (($?!=0));then
        echo "执行SQL失败($sql):$value,exit"
        exit 64
    fi

    prepareSysbench "$info_ori"
    flushSystem

    for t in ${num_threads[@]}
    do
        info_ori="${info_ori},num_thread:$t"

        runReadandwriteSysbench "$info_ori" "$t"
        flushSystem

        runReadonlySysbench "$info_ori" "$t"
        flushSystem

        runUpdataonlySysbench "$info_ori" "$t"
        flushSystem

    done

    info_ori="table_schema:$table_schema,table_count:$table_count,table_size:$table_size,max_time:$max_time"
    cleanupSysbench "$info_ori"
}



function main()
{
    sysbenchMain
}


main "$@"

