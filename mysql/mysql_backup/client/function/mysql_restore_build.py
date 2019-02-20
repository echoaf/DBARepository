#!/usr/bin/env python
# coding=utf8

# description:MySQL备机搭建(从已有数据集恢复)


import sys
import os
import time,datetime
import linecache
import subprocess
import commands
import MySQLdb
import MySQLdb.cursors
import logging
import argparse

#sys.path.append(common_dir)
from mysql_backup_build import *
reload(sys)
sys.setdefaultencoding('utf8')
 

dba_host = "172.16.112.12"
dba_port = 10000
dba_user = "arthur"
dba_pass = "redhat"
dump_user = "arthur"
dump_pass = "redhat"
load_user = "arthur"
load_pass = "redhat"
repl_user = "arthur"
repl_pass = "redhat"
normal_log = "normal.log"
mydumper = "/usr/bin/dba/mydumper"
myloader = "/usr/bin/dba/myloader"

t_mysql_backup_result = "mysql_backup_db.t_mysql_backup_result"
d_dbadb = {'host': dba_host, 'port': dba_port, 'user': dba_user, 'passwd': dba_pass}



def parseArgs():

    parser = argparse.ArgumentParser(description='MySQL Restore Data', add_help=False)
    parser.add_argument('-i', '--instance', dest='instance', type=str, help='instance', default='')
    parser.add_argument('-d', '--dest', dest='dest', type=str, help='IP:Port', default='')
    parser.add_argument('-t', '--load_threads', dest='load_threads', type=int, 
                        help='default thread is 4,then load thread is 8', default=4)
    parser.add_argument('--innodb_buff', dest='innodb_buff', type=str,
                        help='xtrabackup, innodb_buff, default is 1G', default='1G')
    parser.add_argument('--remote_backup_path', dest='remote_backup_path', type=str, 
                        help='remote_backup_path', default='')

    return parser
   

def commandLineArgs(args):
    
    need_print_help = False if args else True
    parser = parseArgs()
    args = parser.parse_args(args)
    if need_print_help:
        parser.print_help()
        sys.exit(1)

    try:
        args.dest_host = (args.dest).split(':',-1)[0]
        args.dest_port = int((args.dest).split(':',-1)[1])
    except IndexError,e:
        raise ValueError(e)

    return args



def doSlaveByRestore(d=None):

    E = True

    if d['backup_mode'].upper() == 'MYDUMPER':
        tmp = checkBackupAgain(d=d)
        if not tmp:
            E = False
            return E
        metadata = "%s/metadata"%(d['backup_path'])
        if not metadata:
            E = False
            return E
        doRestoreMydumper(d=d)
        (master_log_file, master_log_pos, master_host, master_port) = parsePosFile(metadata, d=d)
        changeMaster(master_host, master_port, master_log_file, master_log_pos, d=d)

    elif d['backup_mode'].upper() == 'XTRABACKUP':
        print "不支持物理备份"
        #remote_backup_path:back_path下的backup.tar丢到远程的路径
        #restoreXtrabackupSlave(d=d)
        E = False
    else:
        E = False

    return E


def main():

    args = commandLineArgs(sys.argv[1:])

    sql = ("""select Fsource_host as source_host,
                     Fsource_port as source_port,
                     Fpath as backup_path,
                     Fmode as backup_mode,
                     Fmetadata as d_metadata
              from {t_mysql_backup_result}
              where Ftype='{instance}'
                    and Fbackup_status='Succ' 
                    and Fclear_status='todo' 
                    and Fmode='mydumper' 
                    and Faddress='172.16.112.12'
              order by Fdate desc limit 1;"""
              .format(t_mysql_backup_result = t_mysql_backup_result,
                      instance = args.instance))

    v = connMySQL(sql=sql, d=d_dbadb)
    if not v:
        printLog("[%s]找不到有效恢复集"%args.instance, normal_log, 'green')
        exit()

    d = {
        'backup_mode' : v[0]['backup_mode'],
        'backup_path' : v[0]['backup_path'],
        'source_host' : v[0]['source_host'],
        'source_port' : v[0]['source_port'],
        'dest_host' : args.dest_host,
        'dest_port' : args.dest_port,
        'load_threads' : args.load_threads,
        'innodb_buff' : args.innodb_buff,
    }

    tmp = doSlaveByRestore(d=d)


if __name__ == '__main__':

    main()



