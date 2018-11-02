#!/bin/bash

# 清理日志

github_dir="/data/code/github/repository/mysql_repo/mysql_backup"
log_dir="$github_dir/log_dir" # 待处理的日志目录
normal_log="${log_dir}/log_ratate.log"
log_large=30 # 保留30天的备份日志


function logRatate()
{

    yesterday=$(date +%Y%m%d --date="-1 day") 
    today=$(date +%Y%m%d) 
    backup_path="$log_dir/backup/$yesterday"

    cd $log_dir/backup
    if [ -d "$backup_path" ] || [ -f "${backup_path}.tar.gz" ];then
        echo "已经存在了需要备份到的日志目录${yesterday},请先清理,exit"
        exit
    else
        mkdir -p $backup_path
    fi

    logs=$(find $log_dir/ -maxdepth 1 -name "*.log") # 日志都是.log后缀
    
    for log in $logs
    do
        base_log=$(basename $log)
        /bin/cp -avf $log ${backup_path}/${base_log}_${yesterday}_${today} >>$normal_log 2>&1
        echo "" > $log # 情况日志,不能使用rm
    done
    
    # --remove-files:压缩后删除源文件
    cd $log_dir/backup && tar -zcvf ${yesterday}.tar.gz $yesterday --remove-files 

    #cd $log_dir/backup && find $log_dir/backup -type d | xargs -i rm -rfv {} # 可能是解压查看日志忘记删除
    cd $log_dir/backup && find $log_dir/backup -type f -name "*.tar.gz" -atime +${log_large} | xargs -i rm -rfv {} # 删除log_large之前的压缩包

}


function main()
{
    logRatate
}

main
