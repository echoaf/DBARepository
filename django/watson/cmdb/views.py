# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.shortcuts import render
from django.http import HttpResponse
#from .models import Question


import time,datetime
import MySQLdb,MySQLdb.cursors

# Create your views here.


def index_view(request):
    #return HttpResponse("Welcome,this is my cloud.")
    #return render(request,'index.html')
    now = time.strftime('%F %H:%M:%S',time.localtime())
    word = "hello, now is " + now
    #word = db_table_query(request)
    #table = fileTable(fileModel.objects.all())
    return render(request,'index.html',{'baoshi':word})


def detail(request, question_id):
    return HttpResponse("You're looking at question %s." % question_id)

def results(request, question_id):
    response = "You're looking at the results of question %s."
    return HttpResponse(response % question_id)

def vote(request, question_id):
    return HttpResponse("You're voting on question %s." % question_id)












#####################################
def db_table_query(request):

    header_title, path1 ,path2 = ('Mysql', '库表容量查询','')
    date_start = (datetime.datetime.now() - datetime.timedelta(days=30)).strftime("%Y-%m-%d")
    date_end = datetime.datetime.now().strftime("%Y-%m-%d")
    instance = request.GET.get('Ftype')
    server_host = request.GET.get('Fserver_host')
    server_port = request.GET.get('Fserver_port')
    #return render_to_response('templates/db_table_query.html', locals(), context_instance=RequestContext(request))


def showMachineInfo(request):

    # 读取数据库数据
    sql = "select Findex,Ftype,Fserver_host,Fserver_port,Fstate,Fcreate_time,Fmodify_time from machine_info_db.t_machine_info;"
    #sql = "select * from machine_info_db.t_machine_info;"
    machine_info = connMySQL(sql)
    if machine_info:
        return machine_info
    else:
        return False



def connMySQL(exec_sql,dict_status=1,db_host='172.16.112.11',db_port=10000,db_user='dba_master',db_pass='dba_master'):
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


#index_view("1")
