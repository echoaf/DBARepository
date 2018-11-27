#!/bin/bash

# description:流水类分库分表DDL处理
# arthur
# 2018-11-27

dba_user="ddl_user" # ddl权限
dba_pass="ddl_user"
mysql="/usr/bin/dba/mysql" # mysql

if [ ! -f "$mysql" ];then
    echo "mysql命令不存在($mysql)"
    exit 64
fi

:<<comment
table struct example:
=========== yyyy.mmdd
CREATE TABLE test_#yyyy#_db.t_test_#mmdd# (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  Fip varchar(16) NOT NULL DEFAULT '' COMMENT '服务器IP',
  Fport int(11) NOT NULL DEFAULT '0' COMMENT '服务器PORT',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (Findex),
  KEY idx_Fmodify_time (Fmodify_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='TEST TABLE';
=========== yyyy.mm
CREATE TABLE test_#yyyy#_db.t_test_#mmdd# (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  Fip varchar(16) NOT NULL DEFAULT '' COMMENT '服务器IP',
  Fport int(11) NOT NULL DEFAULT '0' COMMENT '服务器PORT',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (Findex),
  KEY idx_Fmodify_time (Fmodify_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='TEST TABLE';
comment



# 打日志
function printLog()
{
    content="$1"
    normal_log="$2"
    color="$3"
    if [ -z "$normal_log" ];then
        normal_log="/tmp/shell.log"
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



function usage()
{
echo
echo "Usage  : sh $0 --data_source='' --table='' --file='' --exec_type='' --water_type='' --start_pos='' --end_pos=''"
echo "Example: sh $0 --data_source='172.16.112.10:10000' --table='test_#yyyy#_db.t_test_#mmdd#' --file='' --exec_type='create|alter' --water_type='yymmdd|yymm' --start_pos='2018-01-01' --end_pos='2019-01-01'"
echo
exit 64
}


function checkConnectionSouce()
{
    host="$1"
    port="$2"
    if [ -z "$host" ] || [ -z "$port" ];then
        echo "data source in not exists(host:$host,port:$port)"
        usage
    fi
    values=$($mysql -h$host -P$port -u$dba_user -p$dba_pass -N -e "select 1")
    if [ "$values" != "1" ];then
        echo "data source connect error:$values"
        usage
    fi
}


function checkTableFile()
{
    table="$1"
    file="$2"
    if [ -z "$table" ] || [ ! -f "$file" ];then
        echo "file in not exists(host:$host,port:$port)"
        usage
    fi

    if ! cat $file | grep -Ew "$table" -q ;then
        echo "file and table is not match"
        usage
    fi
    
    if cat $file| sed 's/ //g' | grep -i "ifnotexists" -q;then
        echo "file can't use 'if not exists'"
        usage
    fi
}


function checkType()
{
    exec_type="$1"
    water_type="$2"

    if [ "$exec_type" = "create" ] || [ "$exec_type" = "alter" ];then
        >/dev/null
    else
        echo "exec_type(create|alter)"
        usage
    fi

    if [ "$water_type" = "yymmdd" ] || [ "$water_type" = "yymm" ];then
        >/dev/null
    else
        echo "water_type(yymmdd|yymm)"
        usage
    fi
}


function checkDate()
{
    date_time="$1"
    value=$(date -d"$date_time" "+%Y%m%d" 2>&1)
    if (($?==0));then
        echo "$value"
    else
        echo "date time is error($date_time:$value)"
        usage
    fi
}


function parseArgs()
{
    ARGS=$(getopt -a -o d:t:f:s:e: -l data_source:,table:,file:,exec_type:,water_type:,start_pos:,end_pos:,help -- "$@")
    [ $? -ne 0 ] && usage

    eval set -- "${ARGS}"

    while true
    do
        case "$1" in
            -d|--data_source)
                data_source="$2"
                shift
                ;;
            -t|--table)
                table="$2"
                shift
                ;;
            -f|--file)
                file="$2"
                shift
                ;;
            --exec_type)
                exec_type="$2"
                shift
                ;;
            --water_type)
                water_type="$2"
                shift
                ;;
            --start_pos)
                start_pos="$2"
                shift
                ;;
            --end_pos)
                end_pos="$2"
                shift
                ;;
            --help)
                usage
                ;;
            --)
                shift
                break
                ;;
        esac
        shift
    done

}


function checkArgs()
{
    host="$1"
    port="$2"
    table="$3"
    file="$4"
    exec_type="$5"
    water_type="$6"
    start_pos="$7"
    end_pos="$8"
    checkConnectionSouce "$host" "$port"
    checkTableFile "$table" "$file"
    checkType "$exec_type" "$water_type"
    start_pos=$(checkDate "$start_pos")
    end_pos=$(checkDate "$end_pos")

}


function createTableSchema()
{
    host="$1"
    port="$2"
    table_schema="$3"
    E="0"
    MYSQL_CONNECTION="$mysql -u$dba_user -p$dba_pass -h$host -P$port -N"
    check_sql="show databases like '$table_schema'"
    value=$($MYSQL_CONNECTION -N -e "$check_sql")
    if [ -z "$value" ];then
        values=$($MYSQL_CONNECTION -e "create database $table_schema;" 2>&1)
        if (($?==0));then
            printLog "create database $table_schema:success" "$normal_log"
        else
            printLog "create database $table_schema:failure($values)" "$normal_log"
            E=1
        fi
    fi
    return $E
}


function createYYMMDD()
{
    host="$1"
    port="$2"
    table="$3"
    file="$4"
    start_datetime="$5"
    end_datetime="$6"

    E="0"
    cur_datetime="$start_datetime" # 初始化值
    last_datetime=$(date -d "$end_datetime 1 days" "+%Y%m%d") # 最后一个时间,不执行
    sql=$(cat $file)

    cnt_success="0"
    fail_success="0"

    MYSQL_CONNECTION="$mysql -u$dba_user -p$dba_pass -h$host -P$port -N"
    printLog "start create table" "$normal_log"
    while ((1))
    do
        cur_yyyy=$(date -d "$cur_datetime" "+%Y")
        cur_mmdd=$(date -d "$cur_datetime" "+%m%d")
        cur_table=$(echo "$table"| sed -e "s/#yyyy#/$cur_yyyy/g" -e "s/#mmdd#/$cur_mmdd/g")
        cur_table_schema=$(echo "$cur_table"| awk -F"." '{print $1}')
        createTableSchema "$host" "$port" "$cur_table_schema"
        if (($?!=0));then
            break
        fi
        cur_sql=$(echo "$sql"| sed -e "s/$table/$cur_table/g")
        value=$($MYSQL_CONNECTION -e "$cur_sql" 2>&1)
        if (($?==0));then
            printLog "[$cur_table] exec success." "$normal_log"
            cnt_success=$((${cnt_success}+1))
        else
            printLog "[$cur_table] exec failure($value)." "$normal_log"
            fail_success=$((${fail_success}+1))
            E="1"
        fi
        echo "$cur_sql" >>$normal_log 2>&1
        cur_datetime=$(date -d "$cur_datetime 1 days" "+%Y%m%d")   
        if [ "$cur_datetime" = "$last_datetime" ];then
            break
        fi
    done
    printLog "all Done,create table succ:$cnt_success,create table failure:$fail_success" "$normal_log"
    return $E
}



function createYYMM()
{
    host="$1"
    port="$2"
    table="$3"
    file="$4"
    start_datetime="$5"
    end_datetime="$6"

    E="0"

    # 只保留到月份
    start_datetime=$(date -d "$start_datetime" "+%Y%m")
    end_datetime=$(date -d "$end_datetime" "+%Y%m")
    cur_datetime="$start_datetime" # 初始化值
    last_datetime=$(date -d "${end_datetime}01 1 months" "+%Y%m")

    sql=$(cat $file)

    cnt_success="0"
    fail_success="0"

    MYSQL_CONNECTION="$mysql -u$dba_user -p$dba_pass -h$host -P$port -N"
    printLog "start create table" "$normal_log"
    while ((1))
    do
        cur_yyyy=$(date -d "${cur_datetime}01" "+%Y")
        cur_mm=$(date -d "${cur_datetime}01" "+%m")
        cur_table=$(echo "$table"| sed -e "s/#yyyy#/$cur_yyyy/g" -e "s/#mm#/$cur_mm/g")
        cur_table_schema=$(echo "$cur_table"| awk -F"." '{print $1}')
        createTableSchema "$host" "$port" "$cur_table_schema"
        if (($?!=0));then
            break
        fi
        cur_sql=$(echo "$sql"| sed -e "s/$table/$cur_table/g")
        value=$($MYSQL_CONNECTION -e "$cur_sql" 2>&1)
        if (($?==0));then
            printLog "[$cur_table] exec success." "$normal_log"
            cnt_success=$((${cnt_success}+1))
        else
            printLog "[$cur_table] exec failure($value)." "$normal_log"
            fail_success=$((${fail_success}+1))
            E="1"
        fi
        echo "$cur_sql" >>$normal_log 2>&1
        cur_datetime=$(date -d "${cur_datetime}01 1 months" "+%Y%m")   
        if [ "$cur_datetime" = "$last_datetime" ];then
            break
        fi
    done
    printLog "all Done,create table succ:$cnt_success,create table failure:$fail_success" "$normal_log"
    return $E
}



function alterSharding()
{
    host="$1"
    port="$2"
    table="$3"
    file="$4"
    E="0"

    sql=$(cat $file)

    cnt_success="0"
    fail_success="0"

    MYSQL_CONNECTION="$mysql -u$dba_user -p$dba_pass -h$host -P$port -N"

    printLog "start alter table" "$normal_log"

    sharding_table=$(echo "$table"| sed -e 's/#yyyy#/[0-9]{4}/g' -e 's/#mmdd#/[0-9]{4}/g' -e 's/#mm#/[0-9]{2}/g')
    sharding_table_schema=$(echo "$sharding_table"| awk -F"." '{print $1}')
    sharding_table_name=$(echo "$sharding_table"| awk -F"." '{print $2}')
    
    table_schemas_sql="SELECT SCHEMA_NAME FROM information_schema.schemata where SCHEMA_NAME rlike '^$sharding_table_schema$';"
    table_schemas=$($MYSQL_CONNECTION -N -e "$table_schemas_sql" 2>&1)
    if (($?==0));then
        for table_schema in $(echo "$table_schemas")
        do
            table_names_sql="SELECT TABLE_NAME FROM information_schema.tables 
                where table_schema='$table_schema' and table_name rlike '^$sharding_table_name$';"
            table_names=$($MYSQL_CONNECTION -N -e "$table_names_sql" 2>&1)
            if (($?==0));then
                for table_name in $(echo "$table_names")
                do
                    cur_table="${table_schema}.${table_name}"
                    cur_sql=$(echo "$sql"| sed -e "s/$table/$cur_table/g")
                    value=$($MYSQL_CONNECTION -e "$cur_sql" 2>&1)
                    if (($?==0));then
                        printLog "[$cur_table] exec success." "$normal_log"
                        cnt_success=$((${cnt_success}+1))
                    else
                        printLog "[$cur_table] exec failure($value)." "$normal_log"
                        fail_success=$((${fail_success}+1))
                        E="1"
                    fi
                    echo "$cur_sql" >>$normal_log 2>&1
                done
            fi
        done
    fi

    printLog "all Done,create table succ:$cnt_success,create table failure:$fail_success" "$normal_log"
    return $E
}


function execArgs()
{
    host="$1"
    port="$2"
    table="$3"
    file="$4"
    exec_type="$5"
    water_type="$6"
    start_pos="$7"
    end_pos="$8"

    if [ "$exec_type" = "create" ];then
        if [ "$water_type" = "yymmdd" ];then
            createYYMMDD "$host" "$port" "$table" "$file" "$start_pos" "$end_pos"
        elif [ "$water_type" = "yymm" ];then
            createYYMM "$host" "$port" "$table" "$file" "$start_pos" "$end_pos"
        else
            return
        fi
    elif [ "$exec_type" == "alter" ];then
        # Tips:alter table不支持选择开始和结束位点
        alterSharding "$host" "$port" "$table" "$file"
    else
        return
    fi
}

function main()
{
    parseArgs "$@"
    host=$(echo "$data_source"| awk -F":" '{print $1}')
    port=$(echo "$data_source"| awk -F":" '{print $2}')
    exec_type=$(echo "$exec_type"| tr 'A-Z' 'a-z')
    water_type=$(echo "$water_type"| tr 'A-Z' 'a-z')
    if [ -z "$start_pos" ];then
        start_pos=$(date +"%F")
    fi
    if [ -z "$end_pos" ];then
        end_pos="$(date -d'1 years' +"%Y")-12-31"
    fi
    checkArgs "$host" "$port" "$table" "$file" "$exec_type" "$water_type" "$start_pos" "$end_pos"
    execArgs "$host" "$port" "$table" "$file" "$exec_type" "$water_type" "$start_pos" "$end_pos"
}


main "$@"
