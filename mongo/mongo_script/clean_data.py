#!/usr/bin/env python
# coding:utf-8

# description: clean rk_log

import sys
import re
import logging
import commands
import time
from pymongo import MongoClient
from urllib import quote_plus

reload(sys)
sys.setdefaultencoding('utf8')

normal_log = "normal.log"

table_schema = "rk_log"
table_name_regex = "rk"
max_percent = 71
mount_name = "/"
keep_days = 30

user = "super_mongo"
passwd = "QXf9CP6OXzIcUQBK1teNaErl"
instance = "10.1.61.73:27027/admin"


def printLog(content=None, normal_log=None, color='normal'):
    if normal_log:
        try:
            logging.basicConfig(level = logging.DEBUG,
                    format = '[%(asctime)s %(filename)s]:%(message)s',
                    datefmt = '%Y-%m-%d %H:%M:%S',
                    filename = normal_log,
                    filemode = 'a'
            )
            logging.info(content)
            content = str(content)
        except Exception,e:
            pass
    codeCodes = {
            'black':'0;30',
            'green':'0;32',
            'cyan':'0;36',
            'red':'0;31',
            'purple':'0;35',
            'normal':'0'
    }
    print("\033["+codeCodes[color]+"m"+'[%s] %s'%(time.strftime('%F %T',time.localtime()),content)+"\033[0m")


def runShell(c):
    status, text = commands.getstatusoutput(c)
    return status, text


def getMount(mount=None):
    
    p = runShell("df -hP %s | tail -1| awk '{print $5}'| sed 's/%%//g'"%(mount))
    if p[0] != 0:
        return False
    else:
        printLog("[%s]mount percent is %s%%(阈值%s%%)"%(mount,p[1],max_percent),normal_log,"cyan")
        if int(p[1]) > max_percent:
            return True
        else:
            return False


def checkTable(table_name=None):
    if re.compile('%s_[0-9]{10}'%(table_name_regex)).match(table_name):
        d = re.sub('%s_'%(table_name_regex),'',table_name)
        dtime = runShell(""" date -d "%s" +"%%s" """%(d[0:8]))[1]
        befortime = runShell(""" date -d "%s days ago" +"%%s" """%(keep_days))[1]
        if int(dtime) < int(befortime):
            printLog("[%s]to be clean"%(table_name),normal_log,"red")
            return True
        else:
            #printLog("[%s]not clean"%(table_name),normal_log,"cyan")
            return False
    else:
        printLog("not match table:%s"%(table_name),normal_log,"red")
        return False


def dropMain():

    r = getMount(mount=mount_name)
    if not r:
        return # trip

    conn = MongoClient("mongodb://%s:%s@%s"%(quote_plus(user),quote_plus(passwd),instance))
    table_names = conn[table_schema].list_collection_names()
    for table_name in table_names:
        if not getMount(mount=mount_name):
            break # Tips:break logic
        if not checkTable(table_name=table_name): 
            continue # Tips:continue logic

        #conn[db][table_name].drop()


def main():

    dropMain()


if __name__ == '__main__':

    main()
