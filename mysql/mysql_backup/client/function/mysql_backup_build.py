#!/usr/bin/env python
# coding=utf8

# description:MySQL备机搭建 

import sys
import os
import time,datetime
import linecache
import subprocess
import commands
import MySQLdb
import MySQLdb.cursors
import logging
import argparse


reload(sys)
sys.setdefaultencoding('utf8')
 

dump_user = "arthur"
dump_pass = "redhat"
load_user = "arthur"
load_pass = "redhat"
repl_user = "arthur"
repl_pass = "redhat"
normal_log = "normal.log"
mydumper = "/usr/bin/dba/mydumper"
myloader = "/usr/bin/dba/myloader"


def runShell(self, c):
    status, text = commands.getstatusoutput(c)
    return status, text


def parseArgs():

    parser = argparse.ArgumentParser(description='MySQL Backup Build', add_help=False)
    parser.add_argument('-s', '--source', dest='source', type=str, help='IP:Port', default='')
    parser.add_argument('-d', '--dest', dest='dest', type=str, help='IP:Port', default='')
    parser.add_argument('--backup_path', dest='backup_path', type=str, 
                        help='must be a empty directory', default='')
    parser.add_argument('--backup_mode', dest='backup_mode', type=str, 
                        help='mydumper or xtrabackup', default=['mydumper','xtrabackup'])
    parser.add_argument('-t', '--logic_threads', dest='logic_threads', type=int, 
                        help='default thread is 4,then load thread is 8', default=4)
    parser.add_argument('--innodb_buff', dest='innodb_buff', type=str, 
                        help='xtrabackup, innodb_buff, default is 1G', default='1G')
    return parser
   

def commandLineArgs(args):
    
    need_print_help = False if args else True
    parser = parseArgs()
    args = parser.parse_args(args)
    if need_print_help:
        parser.print_help()
        sys.exit(1)

    try:
        args.source_host = (args.source).split(':',-1)[0]   
        args.source_port = int((args.source).split(':',-1)[1])
    except IndexError,e:
        raise ValueError(e)

    try:
        args.dest_host = (args.dest).split(':',-1)[0]   
        args.dest_port = int((args.dest).split(':',-1)[1])
    except IndexError,e:
        raise ValueError(e)

    if args.backup_mode.upper() not in ('MYDUMPER','XTRABACKUP'):
        raise ValueError("backupmode im ('MYDUMPER','XTRABACKUP')")
    else:
        args.backup_mode = args.backup_mode.upper()

    args.load_threads = args.logic_threads*2 # load线程是dump线程的2倍

    t = time.strftime('%Y%m%d%H%M%S', time.localtime())
    args.backup_path = ("%s/%s_%s_%s"%(args.backup_path,
                                       args.source_host, 
                                       args.source_port,
                                       t))
    if os.path.isdir(args.backup_path):
        if os.listdir(args.backup_path):
            raise ValueError('%s不是空目录'%args.backup_path)
        else:
            pass
    else:
        tmp_cmd = "mkdir -p %s"%(args.backup_path)
        subprocess.Popen(tmp_cmd,stdout=subprocess.PIPE,shell=True) 

    return args


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


def connMySQL(sql=None, d=None, is_dict=1):
    """
    d = {'host': host, 'port': port, 'user': user, 'passwd': passwd}
    """
    # MySQLdb Warning升级为Error
    #from warnings import filterwarnings
    #filterwarnings('error', category = MySQLdb.Warning)
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


def checkBackupAgain(d=None):

    E = True

    c_source = {'host': d['source_host'], 
                'port': d['source_port'], 
                'user': dump_user, 
                'passwd': dump_pass}
    c_dest = {'host': d['dest_host'], 
                'port': d['dest_port'], 
                'user': load_user, 
                'passwd': load_pass}
    sql = ("""select count(*) 
              from information_schema.tables 
              where table_schema 
              not in ('mysql','performance_schema','information_schema','sys');""")
    value = connMySQL(sql=sql, d=c_dest)
    if value:
        if value[0]['count(*)'] != 0:
            printLog('目标数据库不是空实例,需要先手动清理数据,或者更改数据源', normal_log, 'red')
            E = True
            #E = False
    else:
        E = False
    sql = "select count(*) from information_schema.innodb_trx;"
    value = connMySQL(sql=sql, d=c_dest)
    if value:
        if value[0]['count(*)'] != 0:
            printLog('数据源存在活跃事务', normal_log, 'red')
            E = False
    else:
        E = False
    return E


def doBackupMydumper(d=None):

    # TIPS:
    # -s,-r:分块,锁表时间会变长
    # --regex '^(?!(mysql|performance_schema|sys))':不备份performance_schema|sys
    cmd = ("""%s --user='%s' --password='%s' --host='%s' --port='%s' --threads='%s' --outputdir='%s' --verbose=3 -s 1000000 -r 1000000 --regex '^(?!(performance_schema|sys))' >>%s 2>&1"""%
              (mydumper, dump_user, dump_pass, 
              d['source_host'], d['source_port'], 
              d['logic_threads'], d['backup_path'], 
              normal_log))

    printLog("dump数据(%s)"%cmd, normal_log, 'green')
    subprocess.call(cmd,stdout=subprocess.PIPE,shell=True) # 等待命令执行完
    metadata = '%s/metadata'%(d['backup_path'])
    if os.path.exists(metadata):
        printLog("结束dump,dump成功", normal_log, 'green')
    else:
        printLog ('结束dump,dump失败,找不到metadata,exit', normal_log, 'red')
        return False

    return metadata


def doRestoreMydumper(d=None):
    # TODO:
    # --overwrite-tables:不覆盖,mysql.user表导不过去
    # --enable-binlog:不写binary log,如果dest是主库的话，下有从库会有问题
    cmd = ("""%s --user='%s' --password='%s' --host='%s' --port='%s' --threads='%s' --verbose=3 --overwrite-tables --directory='%s' >>%s 2>&1"""%
              (myloader, load_user, load_pass, d['dest_host'], d['dest_port'],
              d['load_threads'], d['backup_path'], normal_log))

    printLog("load数据(%s)"%cmd, normal_log, 'green')

    c_dest = {'host': d['dest_host'], 
                'port': d['dest_port'], 
                'user': load_user, 
                'passwd': load_pass}

    connMySQL(sql="set global slow_query_log='off';", d=c_dest)
    subprocess.call(cmd, stdout=subprocess.PIPE, shell=True) # 等待命令执行完
    connMySQL(sql="set global slow_query_log='on';", d=c_dest)

    printLog("结束load", normal_log, 'green')


def parsePosFile(metadata, d=None):
    """
    解析metadata
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
    c_source = {'host': d['source_host'], 
                'port': d['source_port'], 
                'user': load_user, 
                'passwd': load_pass}
    slave_status = connMySQL(sql="show slave status;", d=c_source)

    if not slave_status:
        master_host = d['source_host']
        master_port = d['source_port']
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
            master_host = d['source_host']
            master_port = d['source_port']
            log_file = linecache.getline(metadata, master_line+1).replace('\n', '').split('Log: ', -1)[1]
            log_pos = int(linecache.getline(metadata, master_line+2).replace('\n', '').split('Pos: ', -1)[1])

    return (log_file,log_pos,master_host,master_port)


def changeMaster(master_host, master_port, master_log_file, master_log_pos, d=None):

    sql = ("""change master to 
              master_host='%s', master_port=%s, 
              master_user='%s', master_password='%s', 
              master_log_file='%s', master_log_pos=%s;""" %
              (master_host, master_port, repl_user, repl_pass,
               master_log_file, master_log_pos))

    c_dest = {'host': d['dest_host'], 
                'port': d['dest_port'], 
                'user': load_user, 
                'passwd': load_pass}

    printLog("打开主从,请检测延迟(%s)"%(sql), normal_log, 'green')
    connMySQL(sql=sql, d=c_dest)
    #connMySQL(sql="stop slave;", d=c_dest)
    connMySQL(sql="start slave;", d=c_dest)


def doMydumperSlave(d=None):

    E = True
    tmp = checkBackupAgain(d=d)
    if not tmp:
        E = False
        return E
    metadata = doBackupMydumper(d=d)
    if not metadata:
        E = False
        return E
    doRestoreMydumper(d=d)
    (master_log_file, master_log_pos, master_host, master_port) = parsePosFile(metadata, d=d)
    changeMaster(master_host, master_port, master_log_file, master_log_pos, d=d)
    return E


def doSlave(d = None):

    E = True

    if d['backup_mode'].upper() == 'MYDUMPER':
        tmp = doMydumperSlave(d = d)
        if not tmp:
            E = False

    elif d['backup_mode'].upper() == 'XTRABACKUP':
        printLog('暂时不支持Mxtrabackup',normal_log)
        sys.exit()
        backupXtrabackup_dir = '%s/main/full_backup/backupXtrabackup'%github_dir
        if not os.path.exists(backupXtrabackup_dir):
            printLog("找不到备份脚本所在路径",normal_log)
            E = False

        doXtrabackup(source_host,source_port,dest_host,dest_port,
        backup_path,innodb_buff,"YES")       

    else:
        printLog("未知的backup_mode",normal_log)
        E = False

    return E


def main():

    args = commandLineArgs(sys.argv[1:])

    d = {
        'backup_mode' : args.backup_mode,
        'backup_path' : args.backup_path,
        'source_host' : args.source_host,
        'source_port' : args.source_port,
        'dest_host' : args.dest_host,
        'dest_port' : args.dest_port,
        'logic_threads' : args.logic_threads,
        'load_threads' : args.load_threads,
        'innodb_buff' : args.innodb_buff,
    }

    doSlave(d = d)


if __name__ == '__main__':

    main()



