# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.shortcuts import render
from django.http import HttpResponse


import time
import MySQLdb,MySQLdb.cursors

# Create your views here.


def index_view(request):
    #return HttpResponse("Welcome,this is my cloud.")
    #return render(request,'index.html')
    now = time.strftime('%F %H:%M:%S',time.localtime())
    word = "hello, now is " + now
    #table = fileTable(fileModel.objects.all())
    return render(request,'index.html',{'baoshi':word})


def showMachineInfo(request):

    # 读取数据库数据
    sql = "select Findex,Ftype,Fserver_host,Fserver_port,Fstate,Fcreate_time,Fmodify_time from machine_info_db.t_machine_info;"
    #sql = "select * from machine_info_db.t_machine_info;"
    machine_info = connMySQL(sql)
    if machine_info:
        return machine_info
    else:
        return False



def connMySQL(exec_sql,dict_status=1,db_host='172.16.112.10',db_port=10000,db_user='dba_master',db_pass='dba_master'):
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



