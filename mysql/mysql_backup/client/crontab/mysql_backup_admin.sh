#!/bin/bash

# descripition:MySQL Backup管理脚本
# arthur
# 2018-11-02


main_dir="/data/DBARepository/mysql/mysql_backup"
resident="$main_dir/client/resident/"
normal_log="$main_dir/log/shell.log"

array=(mysql_binarybackup.py mysql_clear.py mysql_fullbackup.py)


function printLog()
{
    content="$1"
    normal_log="$2"
    color="$3"
    echo "[$(date +"%F %T")] $content" >>$normal_log 2>&1
    case "$color" in
        green) echo -e "[`date +"%F %T"`] \033[32m$content \033[0m";;
        red) echo -e "[`date +"%F %T"`] \033[31m$content \033[0m";;
        normal) echo -e "[`date +"%F %T"`] $content";;
        *) echo -e "[`date +"%F %T"`] \033[32m$content \033[0m";;
    esac
}


cd $resident
for p in ${array[@]};
do
    chmod a+x $p
    c=$(ps aux| grep $p | grep -v grep | wc -l)
    if ((${c}==0));then
        printLog "开始执行$p" "$normal_log" "green"
        ./$p >>$normal_log 2>&1
    fi
done
