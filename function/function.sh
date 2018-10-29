

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

