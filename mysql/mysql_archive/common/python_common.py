#!/usr/bin/env python
#coding=utf8

import sys
import os
import time
import datetime
import commands
import logging
import MySQLdb
import MySQLdb.cursors


class Pulic(object):

    def __init__(self,conf_host=None,conf_port=None,conf_user=None,conf_pass=None,
                t_conf_common=None,t_conf_person=None):

        self.conf_host = conf_host
        self.conf_port = conf_port
        self.conf_user = conf_user
        self.conf_pass = conf_pass
        self.t_conf_common = t_conf_common
        self.t_conf_person = t_conf_person

    def getKV(self,key,ip=None,port=None):

        conn_conf = {'host':self.conf_host, 'port':self.conf_port, 'user':self.conf_user, 'passwd':self.conf_pass,} 
        w_generl = "Fstate='online' and Fkey='%s'"%(key)
        s1 = "select Fvalue from %s where %s;"%(self.t_conf_common,w_generl) 
        s2 = "select Fvalue from %s where %s and Fserver_host='%s' and Fserver_port='65536';"%(self.t_conf_person,w_generl,ip)
        s3 = "select Fvalue from %s where %s and Fserver_host='%s' and Fserver_port='%s';"%(self.t_conf_person,w_generl,ip,port)
        v1 = self.connMySQL(s1,conn_conf,)
        v2 = self.connMySQL(s2,conn_conf,)
        v3 = self.connMySQL(s3,conn_conf,)
        v = v2 if v2 else v1
        v = v3 if v3 else v
        v = v[0]['Fvalue'] if v else False
        return v

    
    def connMySQL(self,sql,conn_setting,is_dict=1):
        """
        conn_setting = {'host': host, 'port': port, 'user': user, 'passwd': passwd,}
        """
        try:
            if is_dict == 1:
                conn = MySQLdb.connect(host=conn_setting['host'],port=conn_setting['port'],
                                      user=conn_setting['user'],passwd=conn_setting['passwd'],
                                      db='information_schema',charset='utf8', 
                                      cursorclass=MySQLdb.cursors.DictCursor)
            else:
                conn = MySQLdb.connect(host=conn_setting['host'],port=conn_setting['port'],
                                      user=conn_setting['user'],passwd=conn_setting['passwd'],
                                      db='information_schema',charset='utf8',)
            cur = conn.cursor()
            cur.execute(sql)
            values = cur.fetchall()
            conn.commit()
            cur.close()
            conn.close()
            return values
        except Exception,e:
            raise Exception("sql is running error:%s..."%e)


    def printLog(self,content,normal_log=None,color='normal'):
        if normal_log:
            try:
                logging.basicConfig(level = logging.DEBUG,
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


    def ChangedatetimeToTimestamp(self,d):
         time.strptime(d,'%Y-%m-%d %H:%M:%S')
         s = time.mktime(time.strptime(d,'%Y-%m-%d %H:%M:%S'))
         return int(s)
    

    def deletePoint(self,v):
        return str(v.replace('.',''))
    

    def runShell(delf,c):
        v = commands.getoutput(c)
        return v
 

    def splitPoint(self,v):
        return v.split('.',-1)[0], v.split('.',-1)[1]


    def checkRunning(self,conn_setting):
        sql = "SHOW GLOBAL STATUS LIKE 'Threads_running';"
        r = self.connMySQL(sql,conn_setting)
        return int(r[0]['Value'])


    def getHorizondate(self,days):
        today = datetime.datetime.now()
        d = (today + datetime.timedelta(days=int("-%s"%int(days)))).strftime("%Y-%m-%d")
        return d


    def showMasterStatus(self,conn_setting):
        sql = "SHOW MASTER STATUS;"
        v = self.connMySQL(sql,conn_setting)
        v = dict(v[0]) if v else False
        return v


    def createTable(self,sql,table,conn_setting):
        table_schema,table_name  = self.splitPoint(table)
        check_sql = ("""select count(*) from information_schema.tables 
                    where table_schema='%s' and table_name='%s' """%(table_schema,table_name))
        v = self.connMySQL(check_sql,conn_setting)
        if v:
            if v[0]['count(*)'] == 0:
                self.connMySQL(sql,conn_setting)
        else:
            self.connMySQL(sql,conn_setting)


    def getDelayTime(self,conn_setting):
        delay_time = self.showSlaveStatus(conn_setting)
        if delay_time:
            delay_time = delay_time['Seconds_Behind_Master']
            try:
                delay_time = int(delay_time)
            except Exception,e:
                delay_time = 8640000
        else:
            delay_time = 0
        return delay_time


    def showSlaveStatus(self,conn_setting):
        sql = "SHOW SLAVE STATUS;"
        slave_status = self.connMySQL(sql,conn_setting)
        if slave_status:
            Slave_IO_Running = slave_status[0]['Slave_IO_Running']
            Slave_SQL_Running = slave_status[0]['Slave_SQL_Running']
            Seconds_Behind_Master = slave_status[0]['Seconds_Behind_Master']
            d = ({'Seconds_Behind_Master':Seconds_Behind_Master, 'Slave_IO_Running':Slave_IO_Running,
                'Slave_SQL_Running':Slave_SQL_Running,})
        else:
            d = False
        return d


    def checkReadonly(self,conn_setting):
        sql = "SHOW GLOBAL VARIABLES LIKE 'read_only';"
        v = self.connMySQL(sql,conn_setting)
        v = v[0]['Value']
        return v


    def getUinqueColumn(self,conn_setting,table):
        table_schema,table_name  = self.splitPoint(table)
        sql = ("""select COLUMN_NAME from information_schema.COLUMNS 
              where COLUMN_KEY='PRI' and table_schema='%s' and table_name='%s'; """%(table_schema,table_name))
        v = self.connMySQL(sql,conn_setting,0)
        if v:
            v = v[0]
            if len(v) > 1:
                v = False
            else:
                v = v[0]
        else:
            v = False
        return v


    def checkColumnType(self,conn_setting,table,column):
        table_schema,table_name  = self.splitPoint(table)
        sql = ("""select DATA_TYPE from information_schema.COLUMNS where table_schema='%s' and table_name='%s'
              and COLUMN_NAME='%s'; """%(table_schema,table_name,column))
        v = self.connMySQL(sql,conn_setting)
        if v:
            v = v[0]['DATA_TYPE']
            if v == "int":
                r = "int"
            elif v == "datetime" or v == "date" or v == "timestamp":
                r = "char"
            else:
                r = False
        else:
            r = False
        return r


