#!/bin/bash

# description:MySQL备机搭建
# arthur
# 2018-12-06

base_dir="/data/repository/mysql_repo/mysql_backup"
common_dir="$base_dir/common"
shell_cnf="$common_dir/shell.cnf"
source $shell_cnf

f_name=$(basename "$0")


function usage()
{
echo "sh $0 --source_instance='' --dest_instance='' --backup_path='' --backup_mode='' --logic_threads='' --enable_binlog='' --innodb_buff=''
sh $0
  --source IP:PORT
  --dest IP:Port
  --backup_path must be a empty directory
  --backup_mode mydumper or xtrabackup
  --logic_threads default thread is 4,then load thread is 8
  --enable_binlog Y or N,crontral myloader write binlog
  --innodb_buff xtrabackup, innodb_buff, default is 1G
"
exit 64
}


function parseArgs()
{
    ARGS=$(getopt -a -o s:d: -l source_instance:,dest_instance:,backup_path:,backup_mode:,logic_threads:,innodb_buff:enable_binlog:,,help -- "$@")
    [ $? -ne 0 ] && usage

    eval set -- "${ARGS}"

    while true
    do
        case "$1" in
            -s|--source_instance)
                source_instance="$2"
                shift
                ;;
            -d|--dest_instance)
                dest_instance="$2"
                shift
                ;;
            --backup_path)
                backup_path="$2"
                shift
                ;;
            --backup_mode)
                backup_mode="$2"
                shift
                ;;
            --logic_threads)
                logic_threads="$2"
                shift
                ;;
            --enable_binlog)
                enable_binlog="$2"
                shift
                ;;
            --innodb_buff)
                innodb_buff="$2"
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

    source_host=$(echo "$source_instance"| awk -F":" '{print $1}')
    source_port=$(echo "$source_instance"| awk -F":" '{print $2}')
    dest_host=$(echo "$dest_instance"| awk -F":" '{print $1}')
    dest_port=$(echo "$dest_instance"| awk -F":" '{print $2}')
    for value in $source_host $source_port $dest_host $dest_port $backup_path $backup_mode
    do
        if [ -z "$value" ];then
            echo "args is missing, exit."
            usage
        fi
    done
    if [ -z "$logic_threads" ];then
        logic_threads=4
    fi
    if [ -z "$nnodb_buff" ];then
        innodb_buff="1G"
    fi
    if [ "$enable_binlog" = "Y" ];then
        enable_binlog="Y"
    else
        enable_binlog="N"
    fi
}


function bulidMydumper()
{
    source_host="$1"
    source_port="$2"
    dest_host="$3"
    dest_port="$4"
    backup_path="$5"
    logic_threads="$6"
    enable_binlog="$7"
    return_info=$(backupMydump "$source_host" "$source_port" "$backup_path" "Y" "$logic_threads")
    if (($?==0));then
        printLog "[$f_name][$task_id]$return_info" "$normal_log"
        metadata="$backup_path/metadata"
        json_info=$(checkMydumperResult "$metadata" "$source_host:$source_port")
        if (($value==0));then
        else
        fi
    else
        printLog ""
        return 1
    fi
    loadMydump "$dest_host" "$dest_port" "$backup_path" "$enable_binlog" "8"
}


function bulidMain()
{
    backup_path="$backup_path/$(pointToLineString "$source_host")_${source_port}_$(getIntToday)"
    up_backup_mode=$(upperString "$backup_mode")
    if [ "$up_backup_mode" = "MYDUMPER" ];then
        return_info=$(checkMydumper "$source_host" "$source_port" "$backup_path")
        if (($?!=0));then
            echo "$return_info"
            usage
        fi
        
        return_info=$(checkMyload $dest_host $dest_port)
        if (($?!=0));then
            echo "$return_info"
            usage
        fi
 
        bulidMydumper "$source_host" "$source_port" "$dest_host" "$dest_port" "$backup_path" "$logic_threads" "$enable_binlog"

    elif [ "$up_backup_mode" = "XTRABACKUP" ];then
        echo 1
    else
        usage
    fi
    
}



function main()
{
    parseArgs "$@"
    bulidMain
}


main "$@"
