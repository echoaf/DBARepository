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
import threading
from threading import Thread, Semaphore

base_dir = '/data/DBARepository/mysql/mysql_backup'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)
from python_conf import *
from python_function import BaseFunction
from python_function import MySQLBackupFunction

reload(sys)
sys.setdefaultencoding('utf8')



def main():
    
    BF = BaseFunction(t_conf_common=t_conf_common, t_conf_person=t_conf_person, 
            conn_dbadb=conn_dbadb)
    f_sock = BF.getSockFile(__file__, tmp_dir)
    dconf = BF.getKVDict()
    dconf['run_times'] = int(dconf['run_times'])
    dconf['local_ip'] =  BF.runShell(ip_command)[1]
    dconf['conn_dbadb'] = conn_dbadb
    dconf['normal_log'] = normal_log
    #BF.runApplication(f=f_sock, times=run_times)
    #print run_times
    MF = MySQLBackupFunction(BF=BF, dconf=dconf)

    BF.printLog('===MySQL FULLBACKUP IS START.', normal_log, 'purple')

    while True:

        f_infos = MF.getOnlineFullbackupInfo()
        for f_info in f_infos:
            MF.dconf['f_info'] = f_info 
            MF.dconf['task_id'] = MF.getFullbackupTaskID()
            if not MF.dconf['task_id']:
                BF.printLog("[%s]非我良时"%(f_info['instance']), normal_log)
                continue # 生命之死亡跳转
            rconf = BF.getKVDict(ip=f_info['source_host'], port=f_info['source_port'], real=1)
            MF.dconf['rconf'] = rconf
            backup_status = MF.checkFullbackupTaskID()
            MF.dconf['backup_path'] = "%s/FULLBACKUP/%s"%(MF.dconf['backup_pdir'], MF.dconf['task_id'])
            BF.mkdirPath(MF.dconf['backup_path'])

            result_info = {
                'backup_status' : '',
                'd_metadata' : '',
                'size' : '',
                'backup_info' : '',
            }

            if backup_status:
                backup_status = backup_status[0]['backup_status'].upper()
                if backup_status == 'BACKING':
                    BF.printLog("[%s]全备状态:%s,进入check逻辑"%(MF.dconf['task_id'],backup_status), normal_log)
                    check_info = MF.doCheck()
                    if check_info:
                        result_info['backup_status'] = check_info[0]
                        result_info['d_metadata'] = check_info[1]
                        result_info['size'] = check_info[2]
                        result_info['backup_info'] = check_info[3]
                        MF.updateFullbackup(result_info)
                elif backup_status == 'SUCC':
                    BF.printLog("[%s]全备状态:%s"%(MF.dconf['task_id'],backup_status), normal_log)
                else:
                    BF.printLog("[%s]全备状态:%s,进入备份逻辑"%(MF.dconf['task_id'],backup_status), normal_log)
            else:
                BF.printLog("[%s]进入全备逻辑"%(MF.dconf['task_id']), normal_log)
                #v_dob = MF.doBackup()
                if v_dob:
                    result_info['backup_status'] = 'Backing'
                else:
                    result_info['backup_status'] = 'Fail'
                MF.updateFullbackup(result_info)
        break

    BF.printLog('===MySQL FULLBACKUP IS END.', normal_log, 'purple')


if __name__ == '__main__':

    main()

