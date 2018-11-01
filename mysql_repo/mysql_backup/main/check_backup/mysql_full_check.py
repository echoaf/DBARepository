#!/usr/bin/env python
# coding=utf8

# description:MySQL全备数据集验证
# arthur 
# 2018-10-26

import sys
import os
import time,datetime
import argparse
import subprocess

github_dir = '/data/code/github/repository/mysql_repo/mysql_backup'
common_dir = '%s/common'%github_dir
sys.path.append(common_dir)
from python_cnf import *
script_dir = '%s/main/backup_script'%github_dir
sys.path.append(script_dir)
from mysql_restore_main import restoreMain

reload(sys)
sys.setdefaultencoding('utf8')
 

def parseArgs():

    parser = argparse.ArgumentParser(description='MySQL Restore Data', add_help=False)
    parser.add_argument('-i','--instance',dest='instance',type=str,help='实例类型',default='')
    return parser
   

def commandLineArgs(args):
    
    need_print_help = False if args else True
    parser = parseArgs()
    args = parser.parse_args(args)
    #if args.help or need_print_help:
    if need_print_help:
        parser.print_help()
        sys.exit(1)

    return args


def main():

    args = commandLineArgs(sys.argv[1:])
    instance = args.instance
    
    sql = ("""select Frestore_source,Fload_thread,Finnodb_buff from %s 
    where Ftype='%s' and Fstate='online' and 
    Frestore_address='%s' and Fcheck_info!='Restoring';"""%(t_mysql_check_info,instance,local_ip))
    info = connMySQL(sql)
    if not info:
        raise ValueError("不需要对实例进行还原")
        
    sql = """select Fdata_source,Fbackup_mode,Fbackup_address,Fbackup_path,Fbackup_metadata from %s
    where Fback_status='Succ' and Ftype='%s' and Fdate_time>date_sub(CURDATE(),interval 1 week) 
    order by Fdate_time desc limit 1"""%(t_mysql_fullbackup_result,args.instance)    
    result = connMySQL(sql)
    if not result:
        raise ValueError("找不到最近一周成功的备份集")
 
    info = info[0]
    dest = info['Frestore_source']
    load_thread = info['Fload_thread']
    innodb_buff = info['Finnodb_buff']
    dest_host = (dest).split(':',-1)[0]
    dest_port = (dest).split(':',-1)[1]

    result = result[0]
    data_source = result['Fdata_source']
    backup_mode = result['Fbackup_mode']
    backup_address = result['Fbackup_address']
    backup_path = result['Fbackup_path']
    source_host = data_source.split(':',-1)[0]
    source_port = data_source.split(':',-1)[1]


    if backup_mode.upper() == 'MYDUMPER':
        if not load_threads:
            load_threads = 8
        print('mydumper',backup_path,source_host,source_port,dest_host,dest_port,load_threads)
        restoreMain('mydumper',backup_path,source_host,source_port,dest_host,dest_port,load_threads)
    elif backup_mode.upper() == 'XTRABACKUP':
        if not innodb_buff:
            innodb_buff = "1G"
        print('xtrabackup',backup_path,source_host,source_port,dest_host,dest_port,innodb_buff)
        restoreMain('xtrabackup',backup_path,source_host,source_port,dest_host,dest_port,innodb_buff)
    else:
        raise ValueError("未知的backup_mode")


if __name__ == '__main__':

    main()



