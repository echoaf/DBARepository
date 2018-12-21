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


def connMySQL(sql,conn_setting,is_dict=1):
    """
    conn_setting = {'host': host, 'port': port, 'user': user, 'passwd': passwd,}
    """
    try:
        if is_dict == 1:
            conn = MySQLdb.connect(host=conn_setting['host'], port=conn_setting['port'],
                                  user=conn_setting['user'], passwd=conn_setting['passwd'],
                                  db='information_schema', charset='utf8', 
                                  cursorclass=MySQLdb.cursors.DictCursor)
        else:
            conn = MySQLdb.connect(host=conn_setting['host'], port=conn_setting['port'],
                                  user=conn_setting['user'], passwd=conn_setting['passwd'],
                                  db='information_schema', charset='utf8')
        cur = conn.cursor()
        cur.execute(sql)
        values = cur.fetchall()
        conn.commit()
        cur.close()
        conn.close()
        return values
    except Exception,e:
        raise Exception("sql is running error:%s..."%e)


conn_instance = {
        'host' : '172.16.112.12',
        'port' : 10000,
        'user' : 'master_user',
        'passwd' : 'redhat'
}


def getUniqueKeyName(column):
    sql = "SELECT INDEX_NAME FROM INFORMATION_SCHEMA.STATISTICS where table_schema='test_db' and table_name='t_pt_uuid' and COLUMN_NAME='%s';"%column
    name = connMySQL(sql, conn_instance)
    name = name[0]['INDEX_NAME']
    return name


def getUniqueKeyColumn():
    sql = "select COLUMN_NAME from information_schema.COLUMNS where table_schema='test_db' and table_name='t_pt_uuid' and COLUMN_KEY='PRI'"
    cs1 = connMySQL(sql, conn_instance)
    sql = "select COLUMN_NAME from information_schema.COLUMNS where table_schema='test_db' and table_name='t_pt_uuid' and COLUMN_KEY='UNI'"
    cs2 = connMySQL(sql, conn_instance)
    if cs1:
        c = cs1[0]
    else:
        c = cs2[0]
    if c:
        if len(c) > 1:
            return False
        else:
            return c['COLUMN_NAME']
    else:
        return False


def getColumns():
    sql = "select COLUMN_NAME from information_schema.COLUMNS where table_schema='test_db' and table_name='t_pt_uuid'"
    cs = connMySQL(sql, conn_instance)
    l = []
    for c in cs:
        c = c['COLUMN_NAME']   
        l.append(c)
    return l

def getSelectModule(columns):
    s = ""
    for column in columns:
        if s:
            s = s + "," + column
        else:
            s = column
    return s



def getLast(table, column, unique_name, first_value, num):

    sql = ("""select %s
            from %s 
            FORCE INDEX(%s) 
            where Fmodify_time<'2018-12-17' 
            and %s > '%s'
            order by %s limit %s,2;"""
            %(column, table, unique_name, unique_column, first_value, unique_column, num))
    v = connMySQL(sql, conn_instance, 0)
    if v:
        return v[0][0], v[1][0]
    else:
        return False
    

def getData(select_module, table, unique_name, unique_column, f1, f2, num):
    if f2:
        sql = ("""select %s 
                from %s 
                FORCE INDEX(%s) 
                where Fmodify_time<'2018-12-17' 
                and %s>='%s' and %s<'%s'
                order by %s limit %s;"""
                %(select_module, table, unique_name, unique_column, f1, unique_column, f2, unique_column, num))
    else:
        sql = ("""select %s 
                from %s 
                FORCE INDEX(%s) 
                where Fmodify_time<'2018-12-17' 
                and %s>='%s'
                order by %s limit %s;"""
                %(select_module, table, unique_name, unique_column, f1, unique_column, num))
    print sql
    value = connMySQL(sql, conn_instance)
    if not value:
        return
    v = getLast(table, unique_column, unique_name, f2, num-1)
    if not v:
        return
    f1 , f2 = v
    getData(select_module, table, unique_name, unique_column, f1, f2, num)



def getFL(select_module, table, unique_name, unique_column, f0, f_max, num):

    sql = ("""select %s
            from %s 
            FORCE INDEX(%s) 
            where Fmodify_time<'2018-12-17' 
            and %s > '%s'
            and %s <= '%s'
            order by %s limit %s,2;"""
           %(unique_column, table, unique_name, unique_column, f0, unique_column, f_max, unique_column, num-2))
    info = connMySQL(sql, conn_instance, 0)
    if not info:
        sql = ("""select %s
                from %s 
                FORCE INDEX(%s) 
                where Fmodify_time<'2018-12-17' 
                and %s > '%s'
                and %s <= '%s'
                order by %s limit 1;"""
               %(unique_column, table, unique_name, unique_column, f0, unique_column, f_max, unique_column))
        info = connMySQL(sql, conn_instance, 0)
        f1 = info[0][0]
        f2 = f_max
        r = False
    else:
        f1 = info[0][0]
        f2 = info[1][0]
        r = True
    print f0,f1,f2
    if r:
        return f0,f1,f2
        #getFL(select_module, table, unique_name, unique_column, f2, f_max, num)
    else:
        return False

table = "test_db.t_pt_uuid"
unique_column = getUniqueKeyColumn()
unique_name = getUniqueKeyName(unique_column)
columns = getColumns()
num = 2000
select_module = getSelectModule(columns)

sql = ("""select %s 
        from %s 
        FORCE INDEX(%s) 
        where Fmodify_time<'2018-12-17' 
        order by %s limit 1;"""
        %(select_module, "test_db.t_pt_uuid", unique_name, unique_column))
v_info = connMySQL(sql, conn_instance)
f_min = v_info[0][unique_column]

sql = ("""select %s 
        from %s 
        FORCE INDEX(%s) 
        where Fmodify_time<'2018-12-17' 
        order by %s desc limit 1;"""
        %(select_module, "test_db.t_pt_uuid", unique_name, unique_column))
v_info = connMySQL(sql, conn_instance)
f_max = v_info[0][unique_column]


