#!/bin/bash

# descripition:MySQL Backup管理脚本
# arthur
# 2018-11-02


github_dir="/data/code/github/repository/mysql_repo/mysql_backup"
shell_cnf="$github_dir/common/shell.cnf"
if [ ! -f "$shell_cnf" ] ;then
    echo "$0:找不到配置文件"
    exit 64
else
    source $shell_cnf
fi
f_lock="$tmp_dir/"$(basename "$0"| awk -F"." '{print $1}')".sock"
bd=$(date +%s) # 脚本开始执行时间
maxr_second=3600 # 脚本执行时间


main_fullbackup_sh="$github_dir/main/full_backup/main_fullbackup.sh"
main_binarylogbackup_sh="$github_dir/main/binarylog_backup/main_binarylogbackup.sh"


function main()
{
    #lockFile "$0" "$f_lock" "$$"
    #sh $main_fullbackup_sh &
    #sh $main_binarylogbackup_sh &
    sleep 60
    #while ((1))
    #do
        #sh $main_fullbackup_sh &
        #sh $main_binarylogbackup_sh &
        #sleep 60
        #lastExit $bd $maxr_second
    #done
}


main "$@"





