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

    f_infos = MF.getOnlineFullbackupInfo()
    for f_info in f_infos:
        MF.dconf['f_info'] = f_info 
        MF.dconf['task_id'] = MF.getFullbackupTaskID()
        if not MF.dconf['task_id']:
            BF.printLog("[%s]非我良时"%(f_info['instance']), normal_log)
            continue # Notice

        # rconf:real time conf
        MF.dconf['rconf'] = BF.getKVDict(ip=f_info['source_host'], port=f_info['source_port'], real=1)
        backup_status = MF.checkFullbackupTaskID()
        MF.dconf['backup_path'] = "%s/FULLBACKUP/%s"%(MF.dconf['backup_pdir'], MF.dconf['task_id'])
        BF.mkdirPath(MF.dconf['backup_path'])

        check_info = {
            'check_status' : '',
            'metadata' : {
                    'start_time' : '1970-01-01',
                    'end_time' : '1970-01-01',
                    'master_log_file' : '',
                    'master_log_pos' : '',
                    'master_gtid' : '',
                    'master_host' : '',
                    'master_port' : ''},
            'size' : '0',
            'memo' : '初始化字典',
        }

        if backup_status:
            backup_status = backup_status[0]['backup_status'].upper()
            if backup_status == 'BACKING':
                BF.printLog("[%s]backup status is %s, enter checking"%(MF.dconf['task_id'],backup_status), normal_log)
                check_info = MF.doCheck()
                MF.updateFullbackup(check_info)
            elif backup_status == 'SUCC': 
                BF.printLog("[%s]backup status is %s, exit"%(MF.dconf['task_id'],backup_status), normal_log)
            else:
                BF.printLog("[%s]backup status is %s, enter backuping"%(MF.dconf['task_id'],backup_status), normal_log)
                if MF.doBackup():
                    check_info['check_status'] = 'Backing'
                    check_info['memo'] = '尝试备份成功'
                else:
                    check_info['check_status'] = 'Fail'
                    check_info['memo'] = '第一次尝试备份失败'
                MF.updateFullbackup(check_info)
        else:
            BF.printLog("[%s]init status, enter backuping"%(MF.dconf['task_id']), normal_log)
            if MF.doBackup():
                check_info['check_status'] = 'Backing'
                check_info['memo'] = '尝试备份成功'
            else:
                check_info['check_status'] = 'Fail'
                check_info['memo'] = '第一次尝试备份失败'
            MF.updateFullbackup(check_info)

    BF.printLog('===MySQL FULLBACKUP IS END.', normal_log, 'purple')


if __name__ == '__main__':

    main()

