#!/usr/bin/env python
# coding=utf-8


import sys
import os
import time
import logging
import MySQLdb,MySQLdb.cursors
import subprocess


######################## 基本变量 ##############################
tmp_cmd = "/sbin/ifconfig|grep 'inet '|awk '{print $2}'|grep -Ev '127.0.0.1|172.17'|head -1"
value = subprocess.Popen(tmp_cmd,stdout=subprocess.PIPE,shell=True) 
local_ip = (value.stdout.read()).replace('\n','')
mydumper = '/usr/local/bin/mydumper'
myloader = '/usr/local/bin/myloader'
innobackupex = '/usr/local/xtrabackup/bin/innobackupex'

#present_dir = os.getcwd()
#parent_dir = os.path.abspath(os.path.dirname(os.getcwd()))
github_dir = '/data/code/github/repository/mysql_repo/mysql_backup'
common_dir = '%s/common'%github_dir
mysql = '%s/mysql'%(common_dir)
mysqlbinlog = '%s/mysqlbinlog'%(common_dir)
log_dir = '%s/log_dir'%(github_dir)
tmp_dir = '%s/tmp_dir'%(github_dir)
normal_log = '%s/python.log'%(log_dir)

if not os.path.exists(log_dir):
    os.makedirs(log_dir)
if not os.path.exists(tmp_dir):
    os.makedirs(tmp_dir)

backup_parent_dir = '/data/MySQL_BACKUP'
full_backup_dir = '%s/FULL_BACKUP'%(backup_parent_dir)
binarylog_backup_dir = '%s/BINARYLOG_BACKUP'%(backup_parent_dir)
dump_dir = '%s/DUMP'%(backup_parent_dir)


######################## MySQL相关权限 ##############################
dba_host = '172.16.112.10'
dba_port = 10000
dba_user = 'dba_master' # DML权限
dba_pass = 'dba_master'
check_user = 'read_user' # 只读权限
check_pass = 'read_user'
admin_user = 'remote_root' # surper权限
admin_pass = 'remote_root'
repl_user = 'repl_user' # 复制用户
repl_pass = 'repl_user'
dump_user = 'dump_user' # 备份用户
dump_pass = 'dump_user'


############## 基础信息表 #######################
t_mysql_info = 'mysql_info_db.t_mysql_info' # MySQL信息表
t_mysql_fullbackup_info = 'mysql_backup_db.t_mysql_fullbackup_info' # 全备信息表
t_mysql_fullbackup_result = 'mysql_backup_db.t_mysql_fullbackup_result' # 全备结果表
t_mysql_binarylog_info = 'mysql_backup_db.t_mysql_binarylog_info' # 增备信息表
t_mysql_binarylog_result = 'mysql_backup_db.t_mysql_binarylog_result' # 增备结果表
t_mysql_check_info = 'mysql_backup_db.t_mysql_check_info' # 校验信息表
t_mysql_check_result = 'mysql_backup_db.t_mysql_check_result' # 校验结果表



############## 基础函数 #######################

def connMySQL(exec_sql,db_host=dba_host,db_port=dba_port,db_user=dba_user,db_pass=dba_pass):
    conn = MySQLdb.connect(host=db_host,port=db_port,user=db_user,passwd=db_pass,
        db='information_schema',charset='utf8', 
        cursorclass=MySQLdb.cursors.DictCursor)
    cur = conn.cursor()

    try:
        cur.execute(exec_sql)
        values = cur.fetchall()
        conn.commit()
    except MySQLdb.error,e:
        print(e)
        print("MySQL Error [%d]: %s" %(e.args[0],e.args[1]))

    cur.close()
    conn.close()

    return values


def printLog(content,normal_log,color='normal'):

    # Tips:可能没有权限写日志
    try:
        logging.basicConfig(
                    level = logging.DEBUG,
                    format = '[%(asctime)s %(filename)s]:%(message)s',
                    datefmt = '%Y-%m-%d %H:%M:%S',
                    filename = normal_log,
                    filemode = 'a')
        logging.info(content)
        content = str(content)
    except Exception,e:
        pass

    codeCodes = {'black':'0;30', 'green':'0;32', 'cyan':'0;36', 'red':'0;31', 'purple':'0;35', 'normal':'0'}
    print("\033["+codeCodes[color]+"m"+'[%s] %s'%(time.strftime('%F %T',time.localtime()),content)+"\033[0m")


