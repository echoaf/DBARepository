#!/bin/bash


host="10.1.141.41"
port="3308"
limit_num="1000"
select_sql="select count(*) from stt_profit_1.sub_transaction_event where insert_time > '1542902400' and insert_time <'1543507200' and status=1;"
delete_sql="begin;
select * from stt_profit_1.sub_transaction_event where insert_time > '1542902400' and insert_time <'1543507200' and status=1 limit $limit_num;
delete from stt_profit_1.sub_transaction_event where insert_time > '1542902400' and insert_time <'1543507200' and status=1 limit $limit_num;
commit;
"


mysql="/home/arthur/bin/mysql"
MYSQL_CONNECTION="$mysql -udba_testuser -pdbatestuser123 -h$host -P$port"
normal_log="normal_log"
backup_log="backup.log"


function printLog()
{
    content="$1"
    normal_log="$2"
    color="$3"
    if [ -z "$normal_log" ];then
        normal_log="/tmp/print_colorlog.log"
    fi
    if [ -z "$color" ];then
        color="normal"
    fi      
    echo "[$(date +"%F %T")] $content" >>$normal_log 2>&1
    case "$color" in
        green) echo -e "[`date +"%F %T"`] \033[32m$content \033[0m";;
        red) echo -e "[`date +"%F %T"`] \033[31m$content \033[0m";;
        normal) echo -e "[`date +"%F %T"`] $content";;
        *) echo -e "[`date +"%F %T"`] \033[32m$content \033[0m";;
    esac
}


function deleteMain()
{

    printLog "count data start..." "$normal_log" "green"
    count=$($MYSQL_CONNECTION -N -e "$select_sql" 2>&1)
    printLog "count data end..." "$normal_log" "green"

    if ((${count}==0));then
        return 64
    fi
    
    i=1

    while ((1))
    do
        value=$($MYSQL_CONNECTION -N -e "$delete_sql" 2>&1)
        if (($?==0));then
            printLog "$delete_sql[$i][Succ]" "$normal_log" "green"
            echo "$value" >>backup_log 2>&1
        else
            printLog "$delete_sql[$i][Fail]($value)" "$normal_log" "red"
            exit 64
        fi

        if ((${i}>$count));then
            deleteMain
            break
        else
            i=$((${i}+${limit_num})) 
        fi
        sleep 0.1
    done
}


function main()
{
    count=$($MYSQL_CONNECTION -N -e "select 1" 2>&1)
    if (($?!=0));then
        printLog "connect mysql is failure:$count" "$normal_log" "red"
        exit 64
    fi

    printLog "delete is start..." "$normal_log" "green"
    deleteMain 
    printLog "delete is end." "$normal_log" "green"
}




main
