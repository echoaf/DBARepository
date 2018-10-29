#!/bin/bash


:<<comment
函数的描述
全局变量的使用和修改
使用的参数说明
返回值，而不是上一条命令运行后默认的退出状态
# Cleanup files from the backup dir
# Globals:
#   BACKUP_DIR
#   ORACLE_SID
# Arguments:
#   None
# Returns:
#   None
#######################################
function cleanup() {
  ...
}
comment


#############################################
:<<comment
打印日志
Globals:
    None
Arguments:
    content
Returns:
    None
comment
function printLog()
{
    content="$1"
    normal_log="$2"
    color="$3"
    if [ -z "$normal_log" ];then
        normal_log="/tmp/printLog.log"
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




