#!/usr/bin/env python
#coding=utf8


import sys

base_dir = '/data/repository/monitor'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)
from python_cnf import *

reload(sys)
sys.setdefaultencoding('utf8')

mysql_status_keys=sorted(mysql_status_keys)


def getStatusALL(host,port,user,password):

    status =  connMySQL('show global status',1,host,port,user,password)
    status_dict = {}
    for i in status:
        status_dict[i['Variable_name']] = i['Value']
    return status_dict


def getStatusNeed(status):
    
    need_status_dict = {}
    for k,v in status.items():
        if k in mysql_status_keys:
            need_status_dict[k] = v
    return need_status_dict


def getKeys(keys):

    k_list = []
    for k in keys:
        k = "F%s"%(str(k).lower())
        k_list.append(k)
    return k_list


def reportStatusSQL(db_host,db_port,db_user,db_pass,cur_time):

    status = getStatusALL(db_host,db_port,db_user,db_pass)
    needStatus = getStatusNeed(status)

    #cur_time = getAcceptOrReject()
    sql=("""replace into %s set Fip='%s',Fport='%s',Fdatetime='%s',Fmodify_time=now()"""%
        (t_mysql_status,dba_host,dba_port,cur_time))
    for k,v in needStatus.items():
        k_name = "F%s"%(k.lower())
        sql = "%s ,%s='%s'"%(sql,k_name,v)
    
    sql = "%s;"%sql
    connMySQL(str(sql),1,dba_host,dba_port,dba_user,dba_pass)


cur_time = getAcceptOrReject()
ports = getMySQLOnlinePort()
for port in ports:
    printLog("[%s:%s]开始上报global status"%(local_ip,port),normal_log,'green')
    reportStatusSQL(local_ip,port,dba_user,dba_pass,cur_time)


