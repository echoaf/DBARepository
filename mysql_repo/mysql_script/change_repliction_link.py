#!/usr/bin/env python
# coding=utf8

# description:级联复制改造
# arthur
# 2018-10-19

"""

一、功能
修改前:
instance->slave1->master
修改后:
instance->master
slave1->master

二、参数
提供instance(slave_host,slave_port)
默认修改instance主库为instance当前主库的主库
当是instance->slave1->slave2->master这种架构或者更深的级联架构可以重复执行脚本

三、步骤
1、先检测instance和slave的Seconds_Behind_Master,大于阈值不执行
2、slave:stop slave
3、slave确认没有延迟，提供master info
4、instance确认没有延迟
5、instance:change master to master_host='master'
6、instance和slave:start slave
7、判断主从延迟

"""

import sys
import time,datetime
import logging
import argparse
import MySQLdb,MySQLdb.cursors

reload(sys)
sys.setdefaultencoding('utf8')


######################## MySQL相关权限 ##############################
dba_host = '172.16.112.10'
dba_port = 10000
dba_user = 'dba_master' # DML权限
dba_pass = 'dba_master'
repl_user = 'repl_user' # 复制用户
repl_pass = 'repl_user'
admin_user = 'remote_root' # surper权限
admin_pass = 'remote_root'


delay_time = 3
normal_log = '/tmp/printLog.log'


# 打日志
def printLog(content,normal_log,color='normal'):

    # Tips:可能没有权限写日志
    try:
        logging.basicConfig(
                    level = logging.DEBUG,
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


def connMySQL(exec_sql,db_host=dba_host,db_port=dba_port,db_user=dba_user,db_pass=dba_pass):

    conn = MySQLdb.connect(host=db_host,port=db_port,user=db_user,passwd=db_pass,
        db='information_schema',charset='utf8',
        cursorclass=MySQLdb.cursors.DictCursor)
    cur = conn.cursor()

    try:
        cur.execute(exec_sql)
        values = cur.fetchall()
        conn.commit()
    except MySQLdb.error,e:
        print(e)
        print("MySQL Error [%d]: %s" %(e.args[0],e.args[1]))

    cur.close()
    conn.close()

    return values


def parseArgs():

    parser = argparse.ArgumentParser(description='MySQL Replcition Link Change!!!', add_help=False)
    parser.add_argument('-i','--instance',dest='instance',type=str,help='IP:Port',default='')

    return parser


def commandLineArgs(args):

    need_print_help = False if args else True
    parser = parseArgs()
    args = parser.parse_args(args)
    #if args.help or need_print_help:
    if need_print_help:
        parser.print_help()
        sys.exit(1)

    try:
        args.instance_host = (args.instance).split(':',-1)[0]
        args.instance_port = int((args.instance).split(':',-1)[1])
    except IndexError,e:
        raise ValueError(e)

    return args


def getMasterInfo(slave_host,slave_port):

    slave_info = connMySQL("show slave status;",slave_host,slave_port,repl_user,repl_pass)
    if not slave_info:
        value = False
    else:
        try:
            if int(slave_info[0]['Seconds_Behind_Master']) < delay_time:
                master_host = slave_info[0]['Master_Host']
                master_port = slave_info[0]['Master_Port']
                value = {"master_host":master_host,"master_port":master_port}
            else:
                value = False
        except Exception,e:
            printLog("slave status err:%s"%e,normal_log)
            value = False

    return value


def getReplLink(slave_host,slave_port):

    master = getMasterInfo(slave_host,slave_port)
    if master:
        print "复制链路:%s:%s->%s:%s"%(slave_host,slave_port,master['master_host'],master['master_port'])
        getReplLink(master['master_host'],master['master_port'])
    else:
        return
 
   
def checkSlaveStatus(host,port):

    slave_status = connMySQL("show slave status;",host,port,repl_user,repl_pass)   
    Master_Log_File = slave_status[0]['Master_Log_File']
    Read_Master_Log_Pos = slave_status[0]['Read_Master_Log_Pos']
    Relay_Master_Log_File = slave_status[0]['Relay_Master_Log_File']
    Exec_Master_Log_Pos = slave_status[0]['Exec_Master_Log_Pos']

    if Master_Log_File == Relay_Master_Log_File and Read_Master_Log_Pos == Exec_Master_Log_Pos:
        printLog("位点一致",normal_log)
        value = True
    else:
        value = False

    return value


def stopSlave(instance_host,instance_port,slave_host,slave_port):

    connMySQL("stop slave;",slave_host,slave_port,admin_user,admin_pass)
    if not checkSlaveStatus(slave_host,slave_port):
        connMySQL("start slave;",slave_host,slave_port,admin_user,admin_pass)
        raise ValueError("复制异常,start slave")
    else:
        connMySQL("stop slave;",instance_host,instance_port,admin_user,admin_pass)
        if not checkSlaveStatus(instance_host,instance_port):
            connMySQL("start slave;",slave_host,slave_port,admin_user,admin_pass)
            connMySQL("start slave;",instance_host,instance_port,admin_user,admin_pass)
            raise ValueError("复制异常,start slave")
        else:
            slave_status = connMySQL("show slave status;",slave_host,slave_port,repl_user,repl_pass)
            master_host = slave_status[0]['Master_Host']
            master_port = slave_status[0]['Master_Port']
            master_log_file = slave_status[0]['Relay_Master_Log_File']
            master_log_pos = slave_status[0]['Exec_Master_Log_Pos'] 

    return master_host,master_port,master_log_file,master_log_pos


def main():

    args = commandLineArgs(sys.argv[1:])

    printLog("======================当前复制链路如下",normal_log)
    getReplLink(args.instance_host,args.instance_port)
    printLog("======================",normal_log)

    slave = getMasterInfo(args.instance_host,args.instance_port)
    if not slave:
        printLog("[%s:%s]获取不到master,无上游主库,或者延迟过大(>%s)"%(args.instance_host,args.instance_port,delay_time),normal_log)
        return
    else:
        slave_host = slave['master_host']
        slave_port = slave['master_port']
        master = getMasterInfo(slave_host,slave_port)
        if not master:
            printLog("[%s:%s]获取不到master,无上游主库,或者延迟过大(>%s)"%(slave_host,slave_port,delay_time),normal_log)
            return
        else:
            master_host = master['master_host']
            master_port = master['master_port']
 
 
    master_host,master_port,master_log_file,master_log_pos = stopSlave(args.instance_host,args.instance_port,slave_host,slave_port)     
    
    connMySQL("start slave;",slave_host,slave_port,admin_user,admin_pass)
    sql = ("""change master to master_host='%s',master_port=%s,master_user='%s',master_password='%s',master_log_file='%s',master_log_pos=%s"""
        %(master_host,master_port,repl_user,repl_pass,master_log_file,master_log_pos))
    printLog(sql,normal_log)
    connMySQL(sql,args.instance_host,args.instance_port,admin_user,admin_pass)
    connMySQL("start slave;",args.instance_host,args.instance_port,admin_user,admin_pass)

    printLog("======================当前复制链路如下",normal_log)
    getReplLink(args.instance_host,args.instance_port)
    printLog("======================",normal_log)


if __name__ == '__main__':
    
    main()


