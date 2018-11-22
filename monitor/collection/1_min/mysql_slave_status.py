#!/usr/bin/env python
#coding=utf8


import sys

base_dir = '/data/repository/monitor'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)
from python_cnf import *

reload(sys)
sys.setdefaultencoding('utf8')

mysql_slave_status_keys=sorted(mysql_slave_status_keys)


def getStatusALL(host,port,user,password):

    status =  connMySQL('show slave status',1,host,port,user,password)
    if status:
        status = status[0]
    else:
        status = False
    return status


def getStatusNeed(status):
    
    need_status_dict = {}
    for k,v in status.items():
        if k in mysql_slave_status_keys:
            need_status_dict[k] = v
    return need_status_dict


def getKeys(keys):

    k_list = []
    for k in keys:
        k = "F%s"%(str(k).lower())
        k_list.append(k)
    return k_list


def getVariables(variable_name,db_host,db_port,db_user,db_pass,status="variables"):

    sql="show global %s where variable_name='%s';"%(status,variable_name)
    value = connMySQL(sql,1,db_host,db_port,db_user,db_pass)
    if value:
        value = value[0]['Value']
    else:
        value = ''
    return value   


def reportSlaveStatusSQL(db_host,db_port,db_user,db_pass,cur_time):

    # Tips:使用管理员账号
    server_id = getVariables('server_id',db_host,db_port,db_user,db_pass,status="variables")
    server_uuid = getVariables('server_uuid',db_host,db_port,db_user,db_pass,status="variables")
    slave_status = getStatusALL(db_host,db_port,admin_user,admin_pass)
   
    sql = ("""replace into %s set Fip='%s',Fport='%s',Fdate_time='%s',Fserver_id='%s',Fserver_uuid='%s',Fmodify_time=now()"""%
        (t_mysql_slave_info,db_host,db_port,cur_time,server_id,server_uuid))
    if slave_status:
        needStatus = getStatusNeed(slave_status)
        for k,v in needStatus.items():
            k_name = "F%s"%(k.lower())
            sql = "%s ,%s='%s'"%(sql,k_name,v)
    sql = "%s;"%sql
    connMySQL(str(sql),1,dba_host,dba_port,dba_user,dba_pass)


cur_time = getAcceptOrReject()
ports = getMySQLOnlinePort()
for port in ports:
    printLog("[%s:%s]开始上报mysql slave status"%(local_ip,port),normal_log,'green')
    reportSlaveStatusSQL(local_ip,int(port),dba_user,dba_pass,cur_time)


