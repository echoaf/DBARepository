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
base_dir = '/home/repo/dba_repo/repo_admin/mysql_repo/mysql_backup'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)
from python_conf import *
from python_function import BaseFunction
from python_function import MySQLBackupFunction

reload(sys)
sys.setdefaultencoding('utf8')


def mysqlBackupMain():

    BF = BaseFunction(t_conf_common=t_conf_common, t_conf_person=t_conf_person, 
                      conn_dbadb=conn_dbadb)
    BF.printLog('===MySQL FULLBACKUP IS START.', full_log, 'purple')
    #f_sock = BF.getSockFile(__file__, tmp_dir)
    #BF.runApplication(f=f_sock, times=run_times)
    #print run_times
    dconf = BF.getKVDict() # 读取t_conf配置
    dconf['run_times'] = int(dconf['run_times'])
    dconf['local_ip'] =  BF.runShell(ip_command)[1]
    dconf['conn_dbadb'] = conn_dbadb
    dconf['normal_log'] = normal_log
    dconf['full_log'] = full_log
    #dconf['binary_log'] = binary_log
    #dconf['clear_log'] = clear_log
    dconf['local_xtrabackup_sh'] = local_xtrabackup_sh
    MF = MySQLBackupFunction(BF=BF, dconf=dconf)

    f_infos = MF.getOnlineFullbackupInfo()
    for f_info in f_infos:
        MF.dconf['f_info'] = f_info 
        MF.dconf['xtrabackup_task_id'] = MF.getFullbackupTaskID(backup_mode='xtrabackup')
        MF.dconf['mydumper_task_id'] = MF.getFullbackupTaskID(backup_mode='mydumper')
        MF.dconf['mysqldump_task_id'] = MF.getFullbackupTaskID(backup_mode='mysqldump')
        # Tips:rconf,实时参数
        MF.dconf['rconf'] = BF.getKVDict(ip=f_info['source_host'],
                                         port=f_info['source_port'], 
                                         real=1)
        #BF.printLog('MF.dconf(%s)'%(MF.dconf), full_log, 'purple')
        l = [MF.dconf['xtrabackup_task_id'], 
             MF.dconf['mydumper_task_id'], 
             MF.dconf['mysqldump_task_id']]
        for task_id in l:
            if not task_id:
                continue
            backup_mode = task_id.split('-',-1)[2].lower()
            backup_path = "%s/FULLBACKUP/%s"%(MF.dconf['backup_pdir'], task_id.upper())
            BF.mkdirPath(backup_path)
            # 初始化检测字典
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
            backup_status = MF.checkFullbackupTaskID(task_id=task_id)

            """
            备份流程
                doBackup:全备
                doCheck:检测
                updateFullbackup:更新信息表
            """
            if backup_status:
                backup_status = backup_status[0]['backup_status'].upper()
                if backup_status == 'BACKING':
                    BF.printLog("[%s]backup status is %s, enter checking"%(task_id,backup_status), full_log)
                    check_info = MF.doCheck(backup_mode=backup_mode, backup_path=backup_path, check_info=check_info)
                    MF.updateFullbackup(check_info, task_id, backup_mode, backup_path)
                elif backup_status == 'SUCC': 
                    BF.printLog("[%s]backup status is %s, exit"%(task_id,backup_status), full_log)
                else:
                    BF.printLog("[%s]backup status is %s, enter backuping"%(task_id,backup_status), full_log)
                    if MF.doBackup(backup_mode=backup_mode, backup_path=backup_path):
                        check_info['check_status'] = 'Backing'
                        check_info['memo'] = '尝试备份成功'
                    else:
                        check_info['check_status'] = 'Fail'
                        check_info['memo'] = '第一次尝试备份失败'
                    MF.updateFullbackup(check_info, task_id, backup_mode, backup_path)
            else:
                BF.printLog("[%s]init status, enter backuping"%(task_id), full_log)
                if MF.doBackup(backup_mode=backup_mode, backup_path=backup_path):
                    check_info['check_status'] = 'Backing'
                    check_info['memo'] = '尝试备份成功'
                else:
                    check_info['check_status'] = 'Fail'
                    check_info['memo'] = '第一次尝试备份失败'
                MF.updateFullbackup(check_info, task_id, backup_mode, backup_path)

    BF.printLog('===MySQL FULLBACKUP IS END.', full_log, 'purple')


def main():

    mysqlBackupMain()


if __name__ == '__main__':

    main()
