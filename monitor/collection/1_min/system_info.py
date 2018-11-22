#!/usr/bin/env python
#coding=utf8

"""
description:系统信息上报
arthur
2018-11-19
"""

import sys
import psutil

base_dir = '/data/repo/repository/monitor'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)
from python_cnf import *

reload(sys)
sys.setdefaultencoding('utf8')



def reportCPU(cpu_info,db_host,cur_time=getAcceptOrReject()):

    sql = ("""replace into %s 
            (Fip,Fdate_time,Fuser,Fnice,Fsystem,Fidle,Fiowait,Firq,Fsoftirq,Fsteal,Fmodify_time) 
            values 
            ('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s',now());"""%
            (t_machine_cpu_info,
            db_host,cur_time,cpu_info.user,cpu_info.nice,cpu_info.system,cpu_info.idle,
            cpu_info.iowait,cpu_info.irq,cpu_info.softirq,cpu_info.steal)
          )
    connMySQL(sql)


def reportMem(mem_info,db_host,cur_time=getAcceptOrReject()):
    
    sql = ("""replace into %s
            (Fip,Fdate_time,Ftotal,Favailable,Fpercent,Fused,Ffree,
            Factive,Finactive,Fbuffers,Fcached,Fshared,Fslab,Fmodify_time)
            values
            ('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s',now())"""%
            (t_machine_memory_info,
            db_host,cur_time,mem_info.total,mem_info.available,
            mem_info.percent,mem_info.used,mem_info.free,
            mem_info.active,mem_info.inactive,
            mem_info.buffers,mem_info.cached,mem_info.shared,mem_info.slab)
          )
    connMySQL(sql)


def reportDiskUsage(device,db_host,mountpoint,usage_info,cur_time):
    #sdiskusage(total=498405376, used=0, free=498405376, percent=0.0)
    sql = ("""replace into %s
            (Fip,Fdate_time,Fdevice,Fmountpoint,Ftotal,Fused,Ffree,Fpercent,Fmodify_time)
            values
            ('%s',
            '%s','%s','%s','%s','%s','%s','%s',now())"""%
            (t_machine_disk_usage_info,
            db_host,cur_time,device,mountpoint,usage_info.total,usage_info.used,
            usage_info.free,usage_info.percent)
          )
    connMySQL(sql)


def reportDiskIO(device,db_host,io_info,cur_time):

    """
    sdiskio(read_count=18, write_count=0, read_bytes=1052672, write_bytes=0, read_time=1129, write_time=0, read_merged_count=0, write_merged_count=0, busy_time=949)
    """

    sql = ("""replace into %s
            (Fip,Fdate_time,Fdevice,Fread_count,Fwrite_count,
            Fread_bytes,Fwrite_bytes,Fread_time,Fwrite_time,
            Fread_merged_count,Fwrite_merged_count,Fbusy_time,Fmodify_time)
            values
            ('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s',
            now())  
           """%
            (t_machine_disk_io_counters_info,
            db_host,cur_time,device,io_info.read_count,io_info.write_count,
            io_info.read_bytes,io_info.write_bytes,io_info.read_time,io_info.write_time,
            io_info.read_merged_count,io_info.write_merged_count,io_info.busy_time)
          )
    connMySQL(sql)


def reportNetIO(device,db_host,net_info,cur_time):

    """
    {'lo': snetio(bytes_sent=5388, bytes_recv=5388, packets_sent=50, packets_recv=50, errin=0, errout=0, dropin=0, dropout=0), 'ens33': snetio(bytes_sent=207466, bytes_recv=183897, packets_sent=1687, packets_recv=2405, errin=0, errout=0, dropin=0, dropout=0)}
    """

    sql = ("""replace into %s
            (Fip,Fdate_time,Fdevice,Fbytes_sent,Fbytes_recv,
            Fpackets_sent,Fpackets_recv,Ferrin,Ferrout,
            Fdropin,Fdropout,Fmodify_time)
            values 
            ('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s',now())
           """%
            (t_machine_net_io_counters_info,
            db_host,cur_time,device,net_info.bytes_sent,net_info.bytes_recv,
            net_info.packets_sent,net_info.packets_recv,net_info.errin,net_info.errout,
            net_info.dropin,net_info.dropout)
          )
    connMySQL(sql)


def reportSystemInfo(db_host,cur_time):

    #cur_time = getAcceptOrReject()
    cpu_info = psutil.cpu_times()
    mem_info = psutil.virtual_memory()
    disk_infos = psutil.disk_partitions()
    io_infos = psutil.disk_io_counters(perdisk=True)
    net_infos = psutil.net_io_counters(pernic=True)
    

    reportCPU(cpu_info,db_host,cur_time)
    reportMem(mem_info,db_host,cur_time)

    for disk_info in disk_infos:
        device = disk_info.device
        mountpoint = disk_info.mountpoint
        usage_info = psutil.disk_usage(device)
        reportDiskUsage(device,db_host,mountpoint,usage_info,cur_time)

    for device in io_infos:
        io_info = io_infos[device]
        reportDiskIO(device,db_host,io_info,cur_time)
    
    for device in net_infos:
        net_info = net_infos[device]
        reportNetIO(device,db_host,net_info,cur_time)


cur_time = getAcceptOrReject()
printLog("[%s]开始上报system info"%(local_ip),normal_log,'green')
reportSystemInfo(local_ip,cur_time)

