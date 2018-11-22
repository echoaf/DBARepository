#!/usr/bin/env python
#coding=utf8

"""
description:MySQL系统信息上报
arthur
2018-11-20
"""

import sys
import commands
import psutil

base_dir = '/data/repository/monitor'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)
from python_cnf import *

reload(sys)
sys.setdefaultencoding('utf8')


def reportMySQLCPU(cpu_info,db_host,db_port,cur_time=getAcceptOrReject()):

    sql = ("""
            replace into %s
            (Fip,Fport,Fdate_time,Fuser,Fsystem,
            Fchildren_user,Fchildren_system,Fmodify_time)
            values
            ('%s','%s','%s','%s','%s','%s','%s',now())
            """%
            (t_mysql_cpu_info,
            db_host,db_port,cur_time,cpu_info.user,cpu_info.system,
            cpu_info.children_user,cpu_info.children_system)
          )
    connMySQL(sql)
    

def reportMySQLIO(io_info,db_host,db_port,cur_time):

    #pio(read_count=88523, write_count=3281, read_bytes=1653076480, write_bytes=67633152, read_chars=761958977, write_chars=65303589)
    sql = ("""
            replace into %s
            (Fip,Fport,Fdate_time,Fread_count,Fwrite_count,
             Fread_bytes,Fwrite_bytes,Fread_char,Fwrite_chars,Fmodify_time)
            values 
            ('%s','%s','%s','%s','%s','%s','%s','%s','%s',now())
           """%
            (t_mysql_disk_io_counters_info,
            db_host,db_port,cur_time,
            io_info.read_count,io_info.write_count,
            io_info.read_bytes,io_info.write_bytes,
            io_info.read_chars,io_info.write_chars,)
          )
    connMySQL(sql)


def reportMySQLMem(mem_info,memory_percent,db_host,db_port,cur_time):

    sql = ("""
            replace into %s
            (Fip,Fport,Fdate_time,Frss,Fvms,Fshared,Ftext,
            Flib,Fdata,Fdirty,Fpercent,Fmodify_time)
            values
            ('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s',now())
           """%
            (t_mysql_memory_info,
            db_host,db_port,cur_time,
            mem_info.rss,mem_info.vms,mem_info.shared,mem_info.text,
            mem_info.lib,mem_info.data,mem_info.dirty,memory_percent)
          )
    connMySQL(sql)


def reportMySQLSystemInfo(db_host,db_port,cur_time):

    cmd = """ps aux| grep -w mysqld | grep "/data/mysql/%s/my.cnf"| grep -v grep | awk '{print $2}'"""%(db_port)
    pid = int(commands.getstatusoutput(cmd)[1])

    p = psutil.Process(pid)
    #cur_time = getAcceptOrReject()
    cpu_info = p.cpu_times()
    mem_info = p.memory_info()
    memory_percent = p.memory_percent()
    io_info = p.io_counters()

    reportMySQLCPU(cpu_info,db_host,db_port,cur_time)
    reportMySQLIO(io_info,db_host,db_port,cur_time)
    reportMySQLMem(mem_info,memory_percent,db_host,db_port,cur_time)


cur_time = getAcceptOrReject()
ports = getMySQLAllPort()
for port in ports:
    printLog("[%s:%s]开始上报mysql system info"%(local_ip,port),normal_log,'green')
    reportMySQLSystemInfo(local_ip,port,cur_time)

