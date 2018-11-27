#!/usr/bin/env python
#coding=utf8


import sys

base_dir = '/data/repository/monitor'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)
from python_cnf import *

reload(sys)
sys.setdefaultencoding('utf8')


curtime,curtime_before_1_min = getDiff1minTime()
ports = getMySQLOnlinePort()
for port in ports:
    printLog("[%s:%s]开始监控mysql slow_queries"%(local_ip,port),normal_log,'green')
    mysql_slow_queries = int(getKV('mysql_slow_queries',local_ip,port,'mysql'))
    value = getValueDiff1min('Fslow_queries',t_mysql_status,local_ip,port,curtime,curtime_before_1_min)
    if value == 'NO_RESULT': # 进入标记没有值逻辑
        pass
    else:
        content = "[%s:%s]平均每秒慢查询:%s(阈值%s),时间范围:[%s-%s]"%(local_ip,port,value,mysql_slow_queries,curtime_before_1_min,curtime)
        if int(value) > mysql_slow_queries:
            alarmLog('110',content,normal_log)
        else:
            printLog('110',content,normal_log)
            

