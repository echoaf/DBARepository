#!/usr/bin/env python
#coding=utf8


import sys
import os
import time
import datetime
import calendar
import re
import pprint
import commands
import json

base_dir = '/data/DBARepository/mysql/mysql_backup'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)
from python_conf import *
from python_function import BaseFunction
from python_function import MySQLBackupFunction

reload(sys)
sys.setdefaultencoding('utf8')


def mysqlClearMain():

    BF = BaseFunction(t_conf_common=t_conf_common, t_conf_person=t_conf_person, 
                      conn_dbadb=conn_dbadb)
    dconf = BF.getKVDict() # 读取t_conf配置
    dconf['local_ip'] =  BF.runShell(ip_command)[1]
    dconf['conn_dbadb'] = conn_dbadb
    dconf['normal_log'] = normal_log

    MF = MySQLBackupFunction(BF=BF, dconf=dconf)

    BF.printLog('===MySQL CLEAR IS START.', normal_log, 'purple')
    mount = "/data"
    disk_percent = MF.getDiskPercent(mount=mount)
    BF.printLog("[%s]当前磁盘使用%s(阈值%s)"%(mount,disk_percent,dconf['clear_threshold']), normal_log, 'red')
    if disk_percent >= int(dconf['clear_threshold']):
        # Tips:进入清理逻辑
        MF.doClear()
    BF.printLog("[%s]当前磁盘使用%s(阈值%s)"%(mount,disk_percent,dconf['clear_threshold']), normal_log, 'red')
    BF.printLog('===MySQL CLEAR IS END.', normal_log, 'purple')



def main():

    mysqlClearMain()


if __name__ == '__main__':

    main()

