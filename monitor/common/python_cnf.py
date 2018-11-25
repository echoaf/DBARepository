#!/usr/bin/env python
# coding=utf-8


import sys
import os
import time
import commands
import logging
import MySQLdb,MySQLdb.cursors
import subprocess

base_dir = '/data/repository/monitor'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)


######################## 基本变量 ##############################
tmp_cmd = "/sbin/ifconfig|grep 'inet '|awk '{print $2}'|grep -Ev '127.0.0.1|172.17'|head -1"
value = subprocess.Popen(tmp_cmd,stdout=subprocess.PIPE,shell=True) 
local_ip = (value.stdout.read()).replace('\n','')

base_dir = '/data/repository/monitor'
common_dir = '%s/common'%base_dir
mysql = '%s/mysql'%(common_dir)
log_dir = '%s/log'%(base_dir)
tmp_dir = '%s/tmp'%(base_dir)
normal_log = '%s/python.log'%(log_dir)

if not os.path.exists(log_dir):
    os.makedirs(log_dir)
if not os.path.exists(tmp_dir):
    os.makedirs(tmp_dir)


mysql_table_infos_keys=(
    'table_schema',
    'table_name',
    'table_type',
    'engine',
    'version',
    'row_format',
    'table_rows',
    'data_length',
    'index_length',
    'data_free',
    'auto_increment',
    'create_options',
    'table_comment',
)


mysql_slave_status_keys=(
    'Master_Host',
    'Master_User',
    'Master_Port',
    'Master_Log_File',
    'Read_Master_Log_Pos',
    'Relay_Log_File',
    'Relay_Log_Pos',
    'Relay_Master_Log_File',
    'Slave_IO_Running',
    'Slave_SQL_Running',
    'Replicate_Do_DB',
    'Replicate_Ignore_DB',
    'Replicate_Do_Table',
    'Replicate_Ignore_Table',
    'Replicate_Wild_Do_Table',
    'Replicate_Wild_Ignore_Table',
    'Exec_Master_Log_Pos',
    'Relay_Log_Space',
    'Seconds_Behind_Master',
    'Master_Server_Id',
    'Master_UUID',
    'Slave_SQL_Running_State',
    'Executed_Gtid_Set',
    'Auto_Position',
    'Channel_Name',
)


mysql_status_keys=(
    'Aborted_clients',
    'Aborted_connects',
    'Bytes_received',
    'Bytes_sent',
    'Com_delete',
    'Com_grant',
    'Com_insert',
    'Com_insert_select',
    'Com_load',
    'Com_replace',
    'Com_replace_select',
    'Com_rollback',
    'Com_rollback_to_savepoint',
    'Com_select',
    'Com_slave_start',
    'Com_slave_stop',
    'Com_truncate',
    'Com_update',
    'Connections',
    'Created_tmp_disk_tables',
    'Created_tmp_files',
    'Created_tmp_tables',
    'Innodb_buffer_pool_reads',
    'Innodb_buffer_pool_read_ahead',
    'Innodb_buffer_pool_read_requests',
    'Innodb_data_fsyncs',
    'Key_read_requests ',
    'Key_reads',
    'Key_write_requests',
    'Key_writes',
    'Open_files',
    'Open_table_definitions',
    'Open_tables',
    'Opened_files',
    'Opened_table_definitions',
    'Opened_tables',
    'Queries',
    'Questions',
    'Select_full_join',
    'Select_full_range_join',
    'Select_range',
    'Select_range_check',
    'Select_scan',
    'Slave_open_temp_tables',
    'Slow_launch_threads',
    'Slow_queries',
    'Table_open_cache_hits',
    'Table_open_cache_misses',
    'Table_open_cache_overflows',
    'Threads_cached',
    'Threads_connected',
    'Threads_created',
    'Threads_running',
)


######################## MySQL相关权限 ##############################
#dba_host = '172.16.112.10'
dba_host = '172.16.112.11'
dba_port = 10000
dba_user = 'dba_master' # DML权限
dba_pass = 'dba_master'
read_user = 'read_user' # 实例读用户
read_pass = 'read_user'
admin_user = 'admin_user' # 管理员账号,远程
admin_pass = 'admin_user'


############## 基础信息表 #######################
t_mysql_info = 'mysql_info_db.t_mysql_info' # MySQL信息表
t_mysql_status = 'monitor_db.t_mysql_status' # global status上报表
t_machine_cpu_info = 'monitor_db.t_machine_cpu_info'
t_machine_disk_io_counters_info = 'monitor_db.t_machine_disk_io_counters_info'
t_machine_disk_usage_info = 'monitor_db.t_machine_disk_usage_info'
t_machine_memory_info = 'monitor_db.t_machine_memory_info'
t_machine_net_io_counters_info = 'monitor_db.t_machine_net_io_counters_info'
t_mysql_cpu_info = 'monitor_db.t_mysql_cpu_info'
t_mysql_disk_io_counters_info = 'monitor_db.t_mysql_disk_io_counters_info'
t_mysql_memory_info = 'monitor_db.t_mysql_memory_info'
t_mysql_slave_info = 'monitor_db.t_mysql_slave_info'
t_mysql_table_info = 'monitor_db.t_mysql_table_info'


def connMySQL(exec_sql,dict_status=1,db_host=dba_host,db_port=dba_port,db_user=dba_user,db_pass=dba_pass):
    if dict_status == 1:
        conn = MySQLdb.connect(host=db_host,port=db_port,user=db_user,passwd=db_pass,
            db='information_schema',charset='utf8', 
            cursorclass=MySQLdb.cursors.DictCursor)
    else:
        conn = MySQLdb.connect(host=db_host,port=db_port,user=db_user,passwd=db_pass,
            db='information_schema',charset='utf8')

    cur = conn.cursor()
    try:
        cur.execute(exec_sql)
        values = cur.fetchall()
        conn.commit()
        cur.close()
        conn.close()
        return values
    except Exception,e:
        raise ValueError(e)

    #return values


def printLog(content,normal_log,color='normal'):

    try:
        logging.basicConfig(
                    level = logging.DEBUG,
                    format='[%(asctime)s] [%(filename)s] [%(process)d-%(threadName)s] [%(levelname)s] [%(message)s]',
                    datefmt='%Y-%m-%d %H:%M:%S',
                    filename = normal_log,
                    filemode = 'a')
        logging.info(content)
        content = str(content)
    except Exception,e:
        pass

    codeCodes = {'black':'0;30', 'green':'0;32', 'cyan':'0;36', 'red':'0;31', 'purple':'0;35', 'normal':'0'}
    print("\033["+codeCodes[color]+"m"+'[%s] %s'%(time.strftime('%F %T',time.localtime()),content)+"\033[0m")


def getAcceptOrReject():
    return time.strftime('%F %H:%M:00',time.localtime())

def getTodayTime():
    return time.strftime('%F',time.localtime())


def getMySQLAllPort():

    cmd="""netstat -ntpl| grep mysqld| awk '{print $4}'| awk -F":" '{print $NF}'"""
    ports = commands.getstatusoutput(cmd)[1]
    ports = ports.split('\n',-1)
    return ports


def getMySQLOnlinePort():

    l = []
    sql = "select Fserver_port from %s where Fstate='online' and Fserver_host='%s';"%(t_mysql_info,local_ip)
    ports = connMySQL(sql)
    for port in ports:
        l.append(port['Fserver_port'])
    return l
        
#ports = getMySQLAllPort()
#ports = getMySQLOnlinePort()    


