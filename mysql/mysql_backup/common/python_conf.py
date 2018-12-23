#!/usr/bin/env python
#coding=utf8

import sys
import os
import time
import datetime
import commands
import threading
from threading import Thread, Semaphore

base_dir = '/data/DBARepository/mysql/mysql_backup'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)

reload(sys)
sys.setdefaultencoding('utf8')

log_dir = '%s/log'%(base_dir)
tmp_dir = '%s/tmp'%(base_dir)
mysql = '%s/mysql'%(common_dir)
mysqlbinlog = '%s/mysqlbinlog'%(common_dir)
normal_log = '%s/python.log'%(log_dir)

conf_host = '172.16.112.12'
conf_port = 10000
conf_user = 'master_user'
conf_pass = 'redhat'
t_conf_common = 'conf_db.t_mysql_backup_conf_common'
t_conf_person = 'conf_db.t_mysql_backup_conf_person'
conn_dbadb = {'host': conf_host, 'port': conf_port, 'user': conf_user, 'passwd': conf_pass}

ip_command = "/sbin/ifconfig |grep 'inet '| awk '{print $2}'| grep -Ev '127.0.0.1|172.17'| head -1"

if not os.path.exists(log_dir):
    os.makedirs(log_dir)
if not os.path.exists(tmp_dir):
    os.makedirs(tmp_dir)

realtime_keys = (
    'dump_threads',
    'load_threads',
    'statement_size',
    'rows',
)
