#!/usr/bin/env python
#coding=utf8


import sys
import threading
from threading import Thread, Semaphore
base_dir = '/data/repository/monitor'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)
from python_cnf import *

reload(sys)
sys.setdefaultencoding('utf8')

mysql_table_infos_keys=sorted(mysql_table_infos_keys)

def getTableSchemaInfo(host,port,user,password):

    sql = """SELECT SCHEMA_NAME FROM information_schema.schemata
             WHERE SCHEMA_NAME NOT IN ('performance_schema', 'information_schema', 'sys');"""
    status =  connMySQL(sql,1,host,port,user,password)
    return status


def getStatusNeed(status):
    
    need_status_dict = {}
    for k,v in status.items():
        k = k.lower()
        if k in mysql_table_infos_keys:
            need_status_dict[k] = v
    return need_status_dict


def getTableInfo(table_schema,host,port,user,password):

    sql=("""SELECT             
            ifnull(TABLE_SCHEMA, '') as TABLE_SCHEMA,
            ifnull(TABLE_NAME, '') as TABLE_NAME,
            ifnull(TABLE_TYPE, '') as TABLE_TYPE,
            ifnull(ENGINE, '') as ENGINE,
            ifnull(VERSION, '0') as VERSION,
            ifnull(ROW_FORMAT, '0') as ROW_FORMAT,
            ifnull(TABLE_ROWS, '0') as TABLE_ROWS,
            ifnull(DATA_LENGTH, '0') as DATA_LENGTH,
            ifnull(INDEX_LENGTH, '0') as INDEX_LENGTH,
            ifnull(DATA_FREE, '0') as DATA_FREE,
            ifnull(AUTO_INCREMENT, '0') as AUTO_INCREMENT,
            ifnull(CREATE_OPTIONS, '') as CREATE_OPTIONS,
            ifnull(TABLE_COMMENT, '') as TABLE_COMMENT
            FROM information_schema.tables
            WHERE TABLE_SCHEMA='%s';
        """%(table_schema))
    table_info = connMySQL(sql,1,host,port,user,password)
    return table_info


def reportSchema(table_schema,db_host,db_port,db_user,db_pass,sem):

    table_infos = getTableInfo(table_schema,db_host,db_port,db_user,db_pass)
    if table_infos:
        for table_info in table_infos:
            sql = ("""replace into %s set Fip='%s',Fport='%s',Fdate='%s',Fmodify_time=now()"""%
                (t_mysql_table_info,db_host,db_port,cur_time))
            needStatus = getStatusNeed(table_info)
            for k,v in needStatus.items():
                k_name = "F%s"%(k.lower())
                sql = "%s ,%s='%s'"%(sql,k_name,v)
            sql = "%s;"%sql
            connMySQL(str(sql),1,dba_host,dba_port,dba_user,dba_pass)
    sem.release() # 释放 semaphore


"""
使用多线程上报
"""
def reportSQL(db_host,db_port,db_user,db_pass,cur_time):

    # Tips:使用管理员账号
    table_schemas = getTableSchemaInfo(db_host,db_port,db_user,db_pass)
    thread_num = 10 # 同时跑的线程数
    sem = Semaphore(thread_num) # 设置计数器的值为
    threads = []
    printLog('starting report %s:%s'%(db_host,db_port),normal_log)
    for table_schema in table_schemas:
        table_schema = table_schema['SCHEMA_NAME']
        # ID:2018112601
        #reportSchema(table_schema,db_host,db_port,db_user,db_pass)
        t = threading.Thread(target=reportSchema,args=(table_schema,db_host,db_port,db_user,db_pass,sem))
        threads.append(t)

    length = len(threads)
    for i in range(length): # start threads
        sem.acquire() # 获取一个semaphore
        threads[i].start()
                 
    for i in range(length): # wait for all
        threads[i].join() # threads to finish
                     
    printLog('all DONE %s:%s'%(db_host,db_port),normal_log)


"""
单线程上报
"""
#def reportSQL(db_host,db_port,db_user,db_pass,cur_time):
#
#    # Tips:使用管理员账号
#    table_schemas = getTableSchemaInfo(db_host,db_port,db_user,db_pass)
#    for table_schema in table_schemas:
#        table_schema = table_schema['SCHEMA_NAME']
#        # ID:2018112601
#        table_infos = getTableInfo(table_schema,db_host,db_port,db_user,db_pass)
#        if table_infos:
#            for table_info in table_infos:
#                sql = ("""replace into %s set Fip='%s',Fport='%s',Fdate='%s',Fmodify_time=now()"""%
#                    (t_mysql_table_info,db_host,db_port,cur_time))
#                needStatus = getStatusNeed(table_info)
#                for k,v in needStatus.items():
#                    k_name = "F%s"%(k.lower())
#                    sql = "%s ,%s='%s'"%(sql,k_name,v)
#                sql = "%s;"%sql
#                connMySQL(str(sql),1,dba_host,dba_port,dba_user,dba_pass)
#

cur_time = getTodayTime()
ports = getMySQLOnlinePort()
for port in ports:
    printLog("[%s:%s]======start report mysql table info"%(local_ip,port),normal_log,'green')
    reportSQL(local_ip,int(port),dba_user,dba_pass,cur_time)


