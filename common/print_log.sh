#!/bin/bash


function printLog()
{   
    info="$1"
    logname="$2"
    curtime=$(date +"%F %T")
    if [ ! -z "$logname" ];then
        echo "[$curtime]$info" >>$logname 2>&1
    fi
    echo "[$curtime]$info"
}



function printLogColor()
{
    info="$1"
    logname="$2"
    color="$3"
    curtime=$(date +"%F %T")
    if [ -z "$color" ];then
        color="green"
    fi
    if [ ! -z "$logname" ];then
        echo "[$curtime]$info" >>$logname 2>&1
    fi
    case "$color" in
        normal) echo -e "[$curtime]$info";;
        green) echo -e "[$curtime]\033[32m$info \033[0m";;
        red) echo -e "[$curtime]\033[31m$info \033[0m";;
        black) echo -e "[$curtime]\033[30m$info \033[0m";;
        blue) echo -e "[$curtime]\033[34m$info \033[0m";;
        cyan) echo -e "[$curtime]\033[36m$info \033[0m";;
        purple) echo -e "[$curtime]\033[35m$info \033[0m";;
        yellow) echo -e "[$curtime]\033[33m$info \033[0m";;
        *) echo -e "[$curtime]\033[32m$info \033[0m";;
    esac
}

#printLogColor "hello world" "hello" "red"
#printLog "hello world"

