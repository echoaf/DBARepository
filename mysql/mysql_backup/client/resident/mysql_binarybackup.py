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
import shutil
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
        if not d['f_info']['name'] or d['f_info']['name']=='empty': 
            name = MF.findFirstBinaryLogName() # 从目前source上第一个开始拉取
        else:
            name = d['f_info']['name'] # 从配置表里面拉取
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
        sql = "update %s set Fbinary_name='empty' where Ftype='%s'"%(d['t_mysql_backup_info'],d['f_info']['instance'])
        BF.connMySQL(sql, d['conn_dbadb']) # Todo:需要判断本次是否拉取成功,更新配置表


def checkMain(MF=None):

    d = MF.dconf
    BF = MF.BF
    
    fs = [i for i in os.listdir(d['report_path'])]
    t_binary = BF.connMySQL("SHOW BINARY LOGS", d['conn_instance'], 0)
    l_binary = list(t_binary)
    l_binary.pop() # 最后一个binlog不做比较

    for b in l_binary:

        d_result = {
            'instance' : d['f_info']['instance'],
            'name' : b[0],
            'host' : d['f_info']['source_host'],
            'port' : d['f_info']['source_port'],
            'address' : d['local_ip'],
            'path' : '',
            'size' : '0',
            'start_time' : '',
            'backup_status' : '',
            'backup_info' : '',
        }

        if b[0] in fs:
            print b[0]
            s1 = os.path.getsize("%s/%s"%(d['report_path'],b[0]))
            s2 = b[1]      
            if s1 == s2: # 通过对比file size判断binlog是否拉取succ
                BF.runShell("mv -vf %s/%s %s"%(d['report_path'],b[0],d['succ_path']))
                d_result['start_time'] = MF.getBinarylogTime("%s/%s"%(d['report_path'],b[0]), mysqlbinlog)
                d_result['path'] = "%s/%s"%(d['report_path'],b[0])
                d_result['size'] = int(s1)
                d_result['backup_status'] = "Succ"
                d_result['backup_info'] = "备份成功"
            else:
                d_result['start_time'] = "1970-01-01"
                d_result['path'] = ""
                d_result['size'] = "0"
                d_result['backup_status'] = "Fai;"
                d_result['backup_info'] = "备份失败(找不到文件)"
            MF.updateBinarybackup(d_result)
        else:
            pass
    

def mysqlBinaryBackupMain():
    
    BF = BaseFunction(t_conf_common=t_conf_common, 
                      t_conf_person=t_conf_person, 
                      conn_dbadb=conn_dbadb)
    f_sock = BF.getSockFile(__file__, tmp_dir)
    dconf = BF.getKVDict()
    dconf['run_times'] = int(dconf['run_times'])
    dconf['local_ip'] =  BF.runShell(ip_command)[1]
    dconf['conn_dbadb'] = conn_dbadb
    dconf['normal_log'] = normal_log
    dconf['binary_log'] = binary_log
    MF = MySQLBackupFunction(BF=BF, dconf=dconf)

    BF.printLog('===MySQL BINARYBACKUP IS START.', binary_log, 'purple')

    f_infos = MF.getOnlineBinarybackupInfo()
    for f_info in f_infos:
        MF.dconf['f_info'] = f_info 
        p = ("""%s/BINARYBACKUP/%s/%s_%s"""%(MF.dconf['backup_pdir'], 
                f_info['instance'].upper(), f_info['source_host'], f_info['source_port']))
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

    BF.printLog('===MySQL BINARYBACKUP IS END.', binary_log, 'purple')


def main():

    mysqlBinaryBackupMain()

if __name__ == '__main__':

    main()

