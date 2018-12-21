#!/usr/bin/env python
#coding=utf8

import sys
import os
import time
import datetime
import commands
import threading
from threading import Thread, Semaphore

base_dir = '/data/DBARepository/mysql/mysql_archive'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)

reload(sys)
sys.setdefaultencoding('utf8')

log_dir = '%s/log'%(base_dir)
tmp_dir = '%s/tmp'%(base_dir)
backup_parent_dir = '%s/backup'%base_dir
mysql = '%s/mysql'%(common_dir)
normal_log = '%s/python.log'%(log_dir)

conf_host = '172.16.112.12'
conf_port = 10000
conf_user = 'ddl_user'
conf_pass = 'redhat'
t_conf_common = 'conf_db.t_archive_conf_common'
t_conf_person = 'conf_db.t_archive_conf_person'
conn_dbadb = {'host': conf_host, 'port': conf_port, 'user': conf_user, 'passwd': conf_pass}

if not os.path.exists(log_dir):
    os.makedirs(log_dir)
if not os.path.exists(tmp_dir):
    os.makedirs(tmp_dir)
if not os.path.exists(backup_parent_dir):
    os.makedirs(backup_parent_dir)

conf_keys = (
    'archive_count',
    'dba_host',
    'dba_pass',
    'dba_port',
    'dba_user',
    'master_pass',
    'master_user',
    'repl_pass',
    'repl_user',
    'threads_running',
    't_mysql_archive_info',
    't_mysql_archive_result',
    't_mysql_info',
    'ddl_user',
    'ddl_pass',
    'repl_time',
    'backup_host',
    'backup_port',
    'backup_user',
    'backup_pass',
)

realtime_keys = (
    'archive_count',
    'threads_running',
    'repl_time',
)

example_sql = (
  "CREATE TABLE table_schema.table_name ("
  "Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',"
  "Ftask_id varchar(64) NOT NULL DEFAULT '' COMMENT '任务ID',"
  "Fbegin_unique varchar(64) NOT NULL DEFAULT '' COMMENT '开始值',"
  "Fend_unique varchar(64) NOT NULL DEFAULT '' COMMENT '结束值',"
  "Fstart_pos varchar(2048) NOT NULL DEFAULT '' COMMENT '执行前位点',"
  "Fend_pos varchar(2048) NOT NULL DEFAULT '' COMMENT '执行结束位点',"
  "Fexec_status varchar(12) NOT NULL DEFAULT '' COMMENT '执行状态(Succ|Fail)',"
  "Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',"
  "PRIMARY KEY (Findex),"
  "UNIQUE KEY Ftask_unique_id(Ftask_id,Fbegin_unique,Fend_unique),"
  "KEY idx_Fmodify_time (Fmodify_time),"
  "KEY idx_Fexec_status (Fexec_status)"
") ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='MySQL归档结果流水表';")

