#!/usr/bin/env python
# coding=utf8

import sys
import linecache

base_dir = '/data/repository/mysql_repo/mysql_backup'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)
from python_cnf import *
reload(sys)
sys.setdefaultencoding('utf8')


def checkBackupAgain(source_host,source_port,dest_host,dest_port,backup_path,normal_log):
    """检测备份是否能运行
    Args:
        backup_path:待备份路径,必须是一个空目录
    Returns:
        True|False
    Raises:
        None
    """
    E_VALUE = True
 
    sql = ("""select count(*) from information_schema.tables 
        where table_schema not in ('test','mysql','performance_schema','information_schema','sys');""")  
    value = connMySQL(sql,dest_host,int(dest_port),check_user,check_pass)
    if value:
        if value[0]['count(*)'] != 0:
            printLog('目标数据库不是空实例,需要先手动清理数据,或者更改数据源',normal_log)
            E_VALUE = False
    else:
        E_VALUE = False

    return E_VALUE


def doBackupMydumper(source_host,source_port,logic_threads,backup_path,normal_log):
    """做mydumper备份
    Args:
        source_host,source_port:备份数据源
    Returns:
        metadata:位点信息文件
    """
    
    # TIPS:
    # -s,-r:分块,锁表时间会变长
    tmp_cmd = ("""%s --user='%s' --password='%s' --host='%s' --port='%s' \
        --threads='%s' --outputdir='%s' --verbose=3 -s 1000000 -r 1000000 >>%s 2>&1"""%
        (mydumper,dump_user,dump_pass,source_host,source_port,logic_threads,backup_path,normal_log))
    printLog("=================开始dump",normal_log,'green')   
    printLog(tmp_cmd,normal_log,'green')   
    subprocess.call(tmp_cmd,stdout=subprocess.PIPE,shell=True) # 等待命令执行完
    metadata = '%s/metadata'%(backup_path)
    if os.path.exists(metadata):
        printLog("结束dump,dump成功",normal_log,'green')
    else:
        printLog ('结束dump,dump失败,找不到metadata,exit',normal_log)
        return False
    
    return metadata



def doRestoreMydumper(dest_host,dest_port,load_threads,backup_path,normal_log):
    """使用myload恢复
    Args:
    Returns:
        None
    """
    # TODO:
    # --overwrite-tables:不覆盖,mysql.user表导不过去
    # --enable-binlog:不写binary log,如果dest是主库的话，下有从库会有问题
    tmp_cmd = ("""%s --user='%s' --password='%s' --host='%s' --port='%s' \
        --threads='%s' --verbose=3 --directory='%s' >>%s 2>&1"""%
        (myloader,admin_user,admin_pass,dest_host,dest_port,load_threads,backup_path,normal_log))
    
    printLog("====开始load",normal_log,'green')   
    printLog(tmp_cmd,normal_log,'green')   
    connMySQL("set global slow_query_log='off';",dest_host,int(dest_port),admin_user,admin_pass) # 关闭慢日志
    subprocess.call(tmp_cmd,stdout=subprocess.PIPE,shell=True) # 等待命令执行完
    connMySQL("set global slow_query_log='on';",dest_host,int(dest_port),admin_user,admin_pass) # 关闭慢日志
    printLog("====结束load",normal_log,'green')


def parsePosFile(metadata,source_host,source_port):
    """解析metadata
    Returns:
        master位点信息:master_log_file,master_log_pos,master_host,master_port
    """

    f = open(metadata, 'r')
    i = 1
    master_line = 0
    slave_line = 0
    for line in f.readlines():
        line = str(line.replace('\n', ''))
        if line == 'SHOW MASTER STATUS:':
            master_line = i
        if line == 'SHOW SLAVE STATUS:':
            slave_line = i
        i = i + 1
    f.close()

    # 即使metadata存在show slave status,有可能slave状态不是Yes,这种情况下master是source
    slave_status = connMySQL("show slave status;",source_host,int(source_port),repl_user,repl_pass)
    if not slave_status:
        master_host = source_host
        master_port = source_port
        log_file = linecache.getline(metadata, master_line+1).replace('\n', '').split('Log: ', -1)[1]
        log_pos = int(linecache.getline(metadata, master_line+2).replace('\n', '').split('Pos: ', -1)[1])
    else:
        Slave_IO_Running = slave_status[0]['Slave_IO_Running']
        Slave_SQL_Running = slave_status[0]['Slave_SQL_Running']
        if Slave_IO_Running == "Yes" and Slave_SQL_Running == "Yes":
            master_host = slave_status[0]['Master_Host']
            master_port= slave_status[0]['Master_Port']
            log_file = linecache.getline(metadata, slave_line+2).replace('\n', '').split('Log: ', -1)[1]
            log_pos = int(linecache.getline(metadata, slave_line+3).replace('\n', '').split('Pos: ', -1)[1])
        else:
            master_host = source_host
            master_port = source_port
            log_file = linecache.getline(metadata, master_line+1).replace('\n', '').split('Log: ', -1)[1]
            log_pos = int(linecache.getline(metadata, master_line+2).replace('\n', '').split('Pos: ', -1)[1])

    return (log_file,log_pos,master_host,master_port)


def changeMaster(master_host,master_port,master_log_file,master_log_pos,slave_host,slave_port):
    """change master"""

    sql = ("""change master to master_host='%s',master_port=%s,master_user='%s',master_password='%s', 
        master_log_file='%s',master_log_pos=%s;""" % 
        (master_host,master_port,repl_user,repl_pass,master_log_file,master_log_pos))

    printLog("====打开主从,请检测延迟",normal_log,'green')
    printLog(sql,normal_log,'green')
    printLog("start slave;",normal_log,'green')
    
    connMySQL(sql,slave_host,int(slave_port),admin_user,admin_pass)
    connMySQL("start slave;",slave_host,int(slave_port),admin_user,admin_pass)


def doXtrabackup(master_host,master_port,master_ssh_port,
        local_host,local_port,local_ssh_port,
        backupdir,innodb_buff,is_backup='YES'):
    """物理备份
    Args:
        master_ssh_port:远程机器ssh port
        local_ssh_port:本地机器ssh port,远程机器要使用innobackupex传回文件到本地
        backupdir:本地存放备份文件的目录
        is_backup:是否需要备份
            YES:需要备份,需要使用xtrabackup获取最新的备份数据
            NO:不需要备份,local_host已存在备份的文件
    """

    # local_host实际上是slave,这里是把整个脚本丢到slave执行,所以Slave变成了local
    # xtrabackup.sh master_host master_port master_ssh_port local_host local_port local_ssh_port backupdir innodb_buff
    cmd = ("""cd /tmp/backupXtrabackup && sh xtrabackup.sh %s %s %s %s %s %s %s %s %s"""%
            (master_host,master_port,master_ssh_port,local_host,local_port,local_ssh_port,backupdir,innodb_buff,is_backup))
    printLog("开始做备库,远程执行%s"%(cmd),normal_log)
    p = subprocess.Popen(['ssh','-p',local_ssh_port,'root@%s'%local_host,cmd],stdin=subprocess.PIPE,stdout=subprocess.PIPE)
    while True:
        r = p.stdout.readline().strip().decode('utf-8')
        if r:
            print(r)
        if subprocess.Popen.poll(p) != None and not r:
            break


