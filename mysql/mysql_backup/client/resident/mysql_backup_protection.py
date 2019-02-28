#!/usr/bin/env python
#coding=utf8

# description:MySQL备份自我保护

import sys
import os
import time
import datetime
import calendar
import re
import pprint
import commands
import json

base_dir = '/home/repo/dba_repo/repo_admin/mysql_repo/mysql_backup'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)
from python_conf import *
from python_function import BaseFunction
from python_function import MySQLBackupFunction

reload(sys)
sys.setdefaultencoding('utf8')


def mysqlProtectionMain():

    BF = BaseFunction(t_conf_common=t_conf_common, t_conf_person=t_conf_person, 
                      conn_dbadb=conn_dbadb)
    dconf = BF.getKVDict() # 读取t_conf配置
    dconf['run_times'] = int(dconf['run_times'])
    dconf['local_ip'] =  BF.runShell(ip_command)[1]
    dconf['conn_dbadb'] = conn_dbadb
    dconf['normal_log'] = normal_log

    MF = MySQLBackupFunction(BF=BF, dconf=dconf)

    BF.printLog('===MySQL Protection CHECK IS START.', normal_log, 'purple')

    f_infos = MF.getOnlineFullbackupInfo()
    for f_info in f_infos:
        MF.dconf['f_info'] = f_info 
        MF.doProtect()

    BF.printLog('===MySQL Protection CHECK IS END.', normal_log, 'purple')


def main():

    mysqlProtectionMain()

if __name__ == '__main__':

    main()

