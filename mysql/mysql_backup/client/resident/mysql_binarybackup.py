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
import subprocess
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



def monitorProcess(MF=None):

    d = MF.dconf
    BF = MF.BF
    ps_cmd = ("""ps aux"""
              """ | grep '{mysqlbinlog} -h{host} -P{port} -u{user}'"""
              """ | grep -v grep"""
              """ | awk '{{print $2}}'"""
                .format(mysqlbinlog = mysqlbinlog,
                    host = d['f_info']['source_host'],
                    port = d['f_info']['source_port'],
                    user = d['repl_user']
                )
    )
    if not BF.runShell(ps_cmd)[1]:
        name = MF.findFirstBinaryLogName()
        pull_cmd = ("""{mysqlbinlog} -h{host} -P{port} -u{user} -p{passwd}"""
                    """ {binlog_name}"""
                    """ --read-from-remote-server --raw --stop-never --result-file"""
                    """ {report_dir}/""" # Notice:不能缺少"/"
                    """ >>{normal_log} 2>&1 &"""
                    .format(mysqlbinlog = mysqlbinlog,
                        host = d['f_info']['source_host'],
                        port = d['f_info']['source_port'],
                        user = d['repl_user'],
                        passwd = d['repl_pass'],
                        binlog_name = name,
                        report_dir = d['report_path'],
                        normal_log = d['normal_log']
                    )
        )
        BF.printLog('[%s]pull mysqlbinlog process.'%(d['task_id']), normal_log)
        BF.printLog(pull_cmd, normal_log)
        subprocess.Popen(pull_cmd, stdout=subprocess.PIPE, shell=True)
    

def checkMain(MF=None):

    d = MF.dconf
    BF = MF.BF
    
    fs = [(i, os.stat('%s/%s'%(d['report_path'],i)).st_mtime) for i in os.listdir(d['report_path'])]
    l = [i for i in sorted(fs, key=lambda x: x[1])] # 按时间排序
    l.pop() # 删除最后一个元素
    for f in l:
        print f[0]

    

def main():
    
    BF = BaseFunction(t_conf_common=t_conf_common, t_conf_person=t_conf_person, 
            conn_dbadb=conn_dbadb)
    f_sock = BF.getSockFile(__file__, tmp_dir)
    dconf = BF.getKVDict()
    dconf['run_times'] = int(dconf['run_times'])
    dconf['local_ip'] =  BF.runShell(ip_command)[1]
    dconf['conn_dbadb'] = conn_dbadb
    dconf['normal_log'] = normal_log
    MF = MySQLBackupFunction(BF=BF, dconf=dconf)

    BF.printLog('===MySQL BINARYBACKUP IS START.', normal_log, 'purple')

    f_infos = MF.getOnlineBinarybackupInfo()
    for f_info in f_infos:
        MF.dconf['f_info'] = f_info 
        p = "%s/BINARYBACKUP/%s/%s_%s"%(MF.dconf['backup_pdir'], f_info['instance'].upper(), f_info['source_host'], f_info['source_port'])
        MF.dconf['succ_path'] = "%s/SUCC"%(p)
        MF.dconf['report_path'] = "%s/REPORTED"%(p)
        MF.dconf['fail_path'] = "%s/FAIL"%(p)
        BF.mkdirPath(MF.dconf['succ_path'])
        BF.mkdirPath(MF.dconf['report_path'])
        BF.mkdirPath(MF.dconf['fail_path'])
        MF.dconf['task_id'] = "%s:%s"%(f_info['source_host'], f_info['source_port'])
        
        MF.dconf['conn_instance'] = {
            'host': f_info['source_host'],
            'port': int(f_info['source_port']),
            'user': dconf['repl_user'],
            'passwd': dconf['repl_pass']
        }
        monitorProcess(MF=MF)
        checkMain(MF=MF)
        #check_info = {
        #    'check_status' : '',
        #    'metadata' : {
        #            'start_time' : '1970-01-01',
        #            'end_time' : '1970-01-01',
        #            'master_log_file' : '',
        #            'master_log_pos' : '',
        #            'master_gtid' : '',
        #            'master_host' : '',
        #            'master_port' : ''},
        #    'size' : '0',
        #    'memo' : '初始化字典',
        #}

        #if backup_status:
        #    backup_status = backup_status[0]['backup_status'].upper()
        #    if backup_status == 'BACKING':
        #        BF.printLog("[%s]backup status is %s, enter checking"%(MF.dconf['task_id'],backup_status), normal_log)
        #        check_info = MF.doCheck()
        #        MF.updateFullbackup(check_info)
        #    elif backup_status == 'SUCC': 
        #        BF.printLog("[%s]backup status is %s, exit"%(MF.dconf['task_id'],backup_status), normal_log)
        #    else:
        #        BF.printLog("[%s]backup status is %s, enter backuping"%(MF.dconf['task_id'],backup_status), normal_log)
        #        if MF.doBackup():
        #            check_info['check_status'] = 'Backing'
        #            check_info['memo'] = '尝试备份成功'
        #        else:
        #            check_info['check_status'] = 'Fail'
        #            check_info['memo'] = '第一次尝试备份失败'
        #        MF.updateFullbackup(check_info)
        #else:
        #    BF.printLog("[%s]init status, enter backuping"%(MF.dconf['task_id']), normal_log)
        #    if MF.doBackup():
        #        check_info['check_status'] = 'Backing'
        #        check_info['memo'] = '尝试备份成功'
        #    else:
        #        check_info['check_status'] = 'Fail'
        #        check_info['memo'] = '第一次尝试备份失败'
        #    MF.updateFullbackup(check_info)

    BF.printLog('===MySQL BINARYBACKUP IS END.', normal_log, 'purple')


if __name__ == '__main__':

    main()

