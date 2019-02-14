#!/bin/bash

# description:使用xtrabackup从本地mysql机器备份到远程backup机器


ssh="/usr/bin/ssh"
sshpass="/usr/bin/sshpass"
innobackupex="/usr/bin/innobackupex"


cwd=$(cd $(dirname $0);pwd)
normal_log="$cwd/normal.log"

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


function usage()
{
echo "Usage:  sh $0 dump_host dump_port dump_user dump_pass backup_host backup_ssh_port backup_ssh_user backup_ssh_pass backup_path tmpdir"
echo "Example:sh $0 172.16.112.13 10000 dump_user redhat 172.16.112.12 22 root redhat /data/MySQL_BACKUP/FULLBACKUP/DBADB-20190213-XTRABACKUP /tmp/xtrabackup_tmpdir_22310_20190128114400"
exit 64
}


function checkArgs()
{
    for cmd in $ssh $sshpass $innobackupex
    do
        if [ ! -f $cmd ];then
            printLog "$cmd not find,exit" "$normal_log" "red"
            usage
        fi
    done
    
    if [ -z $dump_host ] || [ -z $dump_port ] || [ -z $dump_user ] || [ -z $dump_pass ] || [ -z $backup_host ] || [ -z $backup_ssh_port ] || [ -z $backup_ssh_user ] || [ -z $backup_ssh_pass ] || [ -z $backup_path ] || [ -z $tmpdir ] ;then
        printLog "args is miss,exit" "$normal_log" "red"
        usage
    fi
}



<<comment
dump_user="dump_user"
dump_pass="redhat"
dump_host="172.16.112.13"
dump_port=10000
backup_host="172.16.112.12"
backup_ssh_port="22"
backup_ssh_pass="redhat"
backup_ssh_user="root"
backup_path="/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190213-XTRABACKUP"
tmpdir="/tmp/xtrabackup_tmpdir_22310_20190128114400"
sh local_xtrabackup.sh dump_host dump_port dump_user dump_pass backup_host backup_ssh_port backup_ssh_user backup_ssh_pass backup_path tmpdir
sh local_xtrabackup.sh 172.16.112.13 10000 dump_user redhat 172.16.112.12 22 root redhat /data/MySQL_BACKUP/FULLBACKUP/DBADB-20190213-XTRABACKUP /tmp/xtrabackup_tmpdir_22310_20190128114400
comment
function main()
{
    dump_host="$1"
    dump_port="$2"
    dump_user="$3"
    dump_pass="$4"
    backup_host="$5"
    backup_ssh_port="$6"
    backup_ssh_user="$7"
    backup_ssh_pass="$8"
    backup_path="$9"
    tmpdir="${10}"
 
    checkArgs "$@"
   
    my_cnf=$(ps aux| grep mysqld_safe| grep $dump_port | awk -F"--defaults-file=" '{print $2}'| awk '{print $1}')
    if [ ! -f "$my_cnf" ];then
        printLog "not find my.cnf($my_cnf)" "$normal_log" "red"
        usage
    fi
    
    backup_tar_file="$backup_path/backup.tar.gz"
    mkdir -p $tmpdir
    cmd="$innobackupex \
        --defaults-file=$my_cnf \
        --tmpdir=$tmpdir \
        --stream=tar \
        --user=$dump_user --password=$dump_pass --host=$dump_host --port=$dump_port \
        --no-timestamp $tmpdir 2>$normal_log |  $sshpass -p \"$backup_ssh_pass\" \
            $ssh -o StrictHostKeyChecking=no -p $backup_ssh_port $backup_ssh_user@\"$backup_host\"  \
            \"gzip - > $backup_tar_file\" >>$normal_log 2>&1"
    printLog "backup commond is:$cmd" "$normal_log" "green"
    $innobackupex \
        --defaults-file=$my_cnf \
        --tmpdir=$tmpdir \
        --stream=tar \
        --user=$dump_user --password=$dump_pass --host=$dump_host --port=$dump_port \
        --no-timestamp $tmpdir 2>$normal_log |  $sshpass -p "$backup_ssh_pass" \
            $ssh -o StrictHostKeyChecking=no -p $backup_ssh_port $backup_ssh_user@"$backup_host"  \
            "gzip - > $backup_tar_file" >>$normal_log 2>&1 &
}


main "$@"
