#!/usr/bin/env python
#coding=utf8


import sys
import os
import time
import datetime
import commands

base_dir = '/data/DBARepository/mysql/mysql_archive'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)
from python_common import Pulic

reload(sys)
sys.setdefaultencoding('utf8')


log_dir = '%s/log'%(base_dir)
tmp_dir = '%s/tmp'%(base_dir)
backup_parent_dir = '%s/backup'%base_dir
mysql = '%s/mysql'%(common_dir)
normal_log = '%s/python.log'%(log_dir)

conf_host = '172.16.112.12'
conf_port = 10000
conf_user = 'master_user'
conf_pass = 'redhat'
t_conf_common = 'conf_db.t_archive_conf_common'
t_conf_person = 'conf_db.t_archive_conf_person'

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
}


class ArchivePartitions(object):

    def __init__ (self):
        pass
    

def archivePartion(conn_mysql,table,column,keep_days):
    table_schema,table_name  = pc.splitPoint(table)
    sql = ("""select 
                TABLE_SCHEMA,
                TABLE_NAME,
                PARTITION_NAME,
                PARTITION_EXPRESSION,
                PARTITION_DESCRIPTION,
                DATA_LENGTH,
                INDEX_LENGTH,
                TABLE_ROWS
             from information_schema.PARTITIONS
             where 
                TABLE_NAME IS NOT NULL
                and table_schema='%s' 
                and table_name='%s' 
                and PARTITION_EXPRESSION='`%s`' 
                and PARTITION_DESCRIPTION<'%s';
         """%(table_schema,table_name,column,keep_days)
         )


