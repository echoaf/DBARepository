#!/bin/bash

function printLog()
{
    content="$1"
    normal_log="$2"
    color="$3"
    if [ -z "$color" ];then
        color="normal"
    fi      
    echo "[$(date +"%F %T")] $content" >>$normal_log 2>&1
    case "$color" in
        green) echo -e "[$(date +"%F %T")] \033[32m$content \033[0m";;
        red) echo -e "[$(date +"%F %T")] \033[31m$content \033[0m";;
        black) echo -e "[$(date +"%F %T")] \033[30m$content \033[0m";;
        blue) echo -e "[$(date +"%F %T")] \033[34m$content \033[0m";;
        cyan) echo -e "[$(date +"%F %T")] \033[36m$content \033[0m";;
        purple) echo -e "[$(date +"%F %T")] \033[35m$content \033[0m";;
        yellow) echo -e "[$(date +"%F %T")] \033[33m$content \033[0m";;
        normal) echo -e "[$(date +"%F %T")] $content";;
        *) echo -e "[$(date +"%F %T")] \033[32m$content \033[0m";;
    esac
}


function printLog()
{   
    content="$1"
    normal_log="$2"
    echo "[$(date +"%F %T")] $content" | tee -a $normal_log
}
