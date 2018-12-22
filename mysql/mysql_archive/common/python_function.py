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


def connMySQL(sql=None, d=None, is_dict=1):
    """
    d = {'host': host, 'port': port, 'user': user, 'passwd': passwd}
    """
    # MySQLdb Warning升级为Error
    from warnings import filterwarnings
    filterwarnings('error', category = MySQLdb.Warning)
    try:
        if is_dict == 1:
            conn = MySQLdb.connect(host=d['host'], port=d['port'],
                    user=d['user'], passwd=d['passwd'],
                    db='information_schema', charset='utf8', 
                    cursorclass=MySQLdb.cursors.DictCursor)
        else:
            conn = MySQLdb.connect(host=d['host'], port=d['port'],
                    user=d['user'], passwd=d['passwd'],
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

def printLog(content=None, normal_log=None, color='normal'):
    if normal_log:
        try:
            logging.basicConfig(level = logging.DEBUG,
                    format = '[%(asctime)s %(filename)s]:%(message)s',
                    datefmt = '%Y-%m-%d %H:%M:%S',
                    filename = normal_log,
                    filemode = 'a'
            )
            logging.info(content)
            content = str(content)
        except Exception,e:
            pass
    codeCodes = {
            'black':'0;30',
            'green':'0;32',
            'cyan':'0;36',
            'red':'0;31',
            'purple':'0;35',
            'normal':'0'
    }
    print("\033["+codeCodes[color]+"m"+'[%s] %s'%(time.strftime('%F %T',time.localtime()),content)+"\033[0m")


