#!/usr/bin/env python
# coding=utf8

# description:MySQL备机搭建 
# arthur 
# 2018-10-17 

import sys
import os
import time,datetime
import linecache
import argparse
import subprocess
github_dir = '/data/code/github/repository/mysql_repo/mysql_backup'
#common_dir = '%s/common'%github_dir
#sys.path.append(common_dir)
#from python_cnf import *
script_dir = '%s/main/backup_script'%github_dir
sys.path.append(script_dir)
from backup_function import *

reload(sys)
sys.setdefaultencoding('utf8')

 
def parseArgs():

    parser = argparse.ArgumentParser(description='MySQL Backup Build', add_help=False)
    parser.add_argument('-s','--source',dest='source',type=str,help='IP:Port',default='')
    parser.add_argument('-d','--dest',dest='dest',type=str,help='IP:Port',default='')
    parser.add_argument('--backup_path',dest='backup_path',type=str,help='must be a empty directory',default='')
    parser.add_argument('--backup_mode',dest='backup_mode',type=str,help='mydumper or xtrabackup',default=['mydumper','xtrabackup'])
    parser.add_argument('-t','--logic_threads',dest='logic_threads',type=int,help='default thread is 4,then load thread is 8',default=4)
    parser.add_argument('--innodb_buff',dest='innodb_buff',type=str,help='xtrabackup, innodb_buff, default is 1G',default='1G')

    return parser
   

def commandLineArgs(args):
    
    need_print_help = False if args else True
    parser = parseArgs()
    args = parser.parse_args(args)
    #if args.help or need_print_help:
    if need_print_help:
        parser.print_help()
        sys.exit(1)

    try:
        args.source_host = (args.source).split(':',-1)[0]   
        args.source_port = int((args.source).split(':',-1)[1])
    except IndexError,e:
        raise ValueError(e)

    try:
        args.dest_host = (args.dest).split(':',-1)[0]   
        args.dest_port = int((args.dest).split(':',-1)[1])
    except IndexError,e:
        raise ValueError(e)

    if args.backup_mode.upper() not in ('MYDUMPER','XTRABACKUP'):
        raise ValueError("backupmode im ('MYDUMPER','XTRABACKUP')")
    else:
        args.backup_mode = args.backup_mode.upper()

    args.load_threads = args.logic_threads*2 # load线程是dump线程的2倍

    if os.path.isdir(args.backup_path):
        if os.listdir(args.backup_path):
            raise ValueError('%s不是空目录'%args.backup_path)
        else:
            pass
    else:
        tmp_cmd = "mkdir -p %s"%(args.backup_path)
        subprocess.Popen(tmp_cmd,stdout=subprocess.PIPE,shell=True) 

    return args


def doMydumperSlave(source_host,source_port,dest_host,dest_port,logic_threads,load_threads,backup_path,normal_log):

    E_VALUE = True

    tmp = checkBackupAgain(source_host,source_port,dest_host,dest_port,backup_path,normal_log)
    if not tmp:
        E_VALUE = False
        return E_VALUE
    metadata = doBackupMydumper(source_host,source_port,logic_threads,backup_path,normal_log)
    if not metadata:
        E_VALUE = False
        return E_VALUE
    doRestoreMydumper(dest_host,dest_port,load_threads,backup_path,normal_log)
    (master_log_file,master_log_pos,master_host,master_port) = parsePosFile(metadata,source_host,source_port)
    changeMaster(master_host,master_port,master_log_file,master_log_pos,dest_host,dest_port)

    return E_VALUE


def doSlave(backup_mode,
        source_host,source_port,source_ssh_port,
        dest_host,dest_port,dest_ssh_port,
        logic_threads,load_threads,innodb_buff,
        backup_path,
        normal_log):

    E_VALUE = True
    backup_mode = backup_mode.upper()

    if backup_mode == 'MYDUMPER':
        tmp = doMydumperSlave(source_host,source_port,dest_host,dest_port,
            logic_threads,load_threads,backup_path,normal_log)
        if not tmp:
            E_VALUE = False

    elif backup_mode == 'XTRABACKUP':

        backupXtrabackup_dir = '%s/main/full_backup/backupXtrabackup'%github_dir
        if not os.path.exists(backupXtrabackup_dir):
            printLog("找不到备份脚本所在路径",normal_log)
            E_VALUE = False
        try:        
            cmd = """scp -P %s -o "StrictHostKeyChecking no" -r %s root@%s:/tmp/ """%(dest_ssh_port,backupXtrabackup_dir,dest_host)
            subprocess.call(cmd,stdout=subprocess.PIPE,shell=True) # 等待命令执行完
        except Exception,e:
            printLog("scp执行错误(%s)"%(e),normal_log)
            E_VALUE = False

        doXtrabackup(source_host,source_port,source_ssh_port,dest_host,dest_port,dest_ssh_port,
        backup_path,innodb_buff,"YES")       

    else:
        printLog("未知的backup_mode",normal_log)
        E_VALUE = False

    return E_VALUE


def main():

    args = commandLineArgs(sys.argv[1:])

    # bug:写死了
    source_ssh_port = "22"
    dest_ssh_port = "22"

    doSlave(args.backup_mode,
        args.source_host,args.source_port,source_ssh_port,
        args.dest_host,args.dest_port,dest_ssh_port,
        args.logic_threads,args.load_threads,args.innodb_buff,
        args.backup_path,
        normal_log)    



if __name__ == '__main__':

    main()



