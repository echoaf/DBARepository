#!/usr/bin/env python
#coding=utf8

import sys
import os
import time
import datetime
import re
import commands
import threading
from threading import Thread, Semaphore

base_dir = '/data/DBARepository/mysql/mysql_archive'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)
from python_conf import *
from python_function import connMySQL, printLog, PubicFunction as PF
#from python_function import connMySQL
#from python_function import printLog

reload(sys)
sys.setdefaultencoding('utf8')


def archivePartitions(d_archive, mysql_archive, check_info, task_id):
    pc = mysql_archive.pc
    table_schema,table_name  = splitPoint(d_archive['table'])
    pri_column, column_type, horizon_time = check_info
    ddl_user = getKV(k='ddl_user', ip=d_archive['ip'], port=int(d_archive['port']))
    ddl_pass = getKV(k='ddl_pass', ip=d_archive['ip'], port=int(d_archive['port']))
    conn_instance = {
        'host' : d_archive['ip'],
        'port' : int(d_archive['port']),
        'user' : ddl_user,
        'passwd' : ddl_pass
    }
    print conn_instance
    exit()
    where_module = """TABLE_NAME IS NOT NULL
                and PARTITION_METHOD = 'RANGE COLUMNS'
                and table_schema='%s' 
                and table_name='%s' 
                and PARTITION_EXPRESSION='`%s`' 
                and PARTITION_DESCRIPTION<'%s';
         """%(table_schema,table_name,d_archive['column'],horizon_time)
    sql1 = ("""select 
                TABLE_SCHEMA,
                TABLE_NAME,
                sum(DATA_LENGTH+INDEX_LENGTH)/1024/1024 AS DATA_LENGTH,
                sum(TABLE_ROWS) AS TABLE_ROWS,
                count(*) AS TABLE_COUNT
              from information_schema.PARTITIONS
              where %s"""%(where_module)
    )
    sql2 = ("""select PARTITION_NAME from information_schema.PARTITIONS
            where %s"""%(where_module))
    sum_info = connMySQL(sql1,conn_instance)
    sum_info = sum_info[0]
    if sum_info['TABLE_COUNT'] == 0:
        printLog("[%s]没有需要删除的分区"
                %(d_archive['table']),normal_log)
        return
    ps = connMySQL(sql2,conn_instance,"0")
    v = ""
    for p in ps:
        p = p[0]
        if not v:
            v = p
        else:
            v = v + "," + p
    printLog("[%s]开始执行删除语句,预计删除分区个数:%s,行数:%s,数据量大小:%sM"
            %(d_archive['table'], sum_info['TABLE_COUNT'], 
            sum_info['TABLE_ROWS'], sum_info['DATA_LENGTH']),
            normal_log)
    sql = ("""alter table %s.%s drop partition %s"""
            %(sum_info['TABLE_SCHEMA'],sum_info['TABLE_NAME'],v))
    printLog((sql),normal_log)
    connMySQL(sql,conn_instance)


#def archiveTable(d):
#    """
#    单表归档逻辑
#    """
#    load_big_file = "%s/%s.txt"%(tmp_dir,task_id)
#    ##### create table
#    t_task_id = "mysql_archive_2018_db.t_%s"%(task_id)
#    create_sql = example_sql.replace("table_schema.table_name", t_task_id)
#    printLog("[%s]create water table:%s"%(task_id,t_task_id), normal_log)
#    createTable(create_sql, t_task_id, conn_dba)
#    # load数据
#    archive_sql = ("delete from %s where %s<'%s';" %(d_archive['table'], d_archive['column'], horizon_time))
#    printLog("[%s]import data to file"%(task_id),normal_log)
#    mysql_archive.importToLocal(d_archive, horizon_time,
#                                    t_task_id, load_big_file, 
#                                    task_id, pri_column, master_user, master_pass
#                               )
#    printLog("[%s]start load big file to mysql(%s)" %(task_id,t_task_id),normal_log)
#    mysql_archive.loadToMySQL(d_archive, pri_column, horizon_time, 
#                                t_task_id, load_big_file,
#                                task_id, load_user, load_pass
#                             )
#    printLog("[%s]end load big file to mysql(%s)" %(task_id,t_task_id),normal_log)
#    # 更新t_mysql_archive_result
#    t_mysql_archive_result = getKV('t_mysql_archive_result')
#    sql = "select count(*) from %s;" % (t_task_id)
#    deal_count = connMySQL(sql,conn_dba)[0]['count(*)']
#    ins_s = ("""select '%s',current_date(),'%s','%s','%s','%s','%s',"%s",now(),now()"""%
#            (task_id,d_archive['ip'], d_archive['port'], 
#            d_archive['table'], deal_count, 'Init', archive_sql))
#    ins_sql = ("""insert into %s (Ftask_id,Fdate,Fip,Fport,Ftable,
#              Fcount,Fexec_status,Fsql,Fcreate_time,Fmodify_time) %s"""%
#              (t_mysql_archive_result,ins_s))
#    connMySQL(ins_sql,conn_dba)
#    
#    # 删除数据逻辑
#    mysql_archive.deleteDo(conn_instance, conn_dba, d_archive['table'], 
#                          pri_column, t_task_id, task_id)
#    
#    # 更新t_mysql_archive_result
#    exec_status = "Succ"
#    sql = ("""update %s set Fcount='%s',Fexec_status='%s',Fmodify_time=now() where Ftask_id='%s';"""%
#          (t_mysql_archive_result, deal_count, exec_status, task_id))
#    connMySQL(sql,conn_dba)
#    printLog("[%s]is done"%(task_id),normal_log)



def getFL(d):

    general_sql = ("""select {select_module} from {table_schema}.{table_name}"""
            """ FORCE INDEX({uk_name})"""
            """ WHERE {column}<'{threshold_time}'""".format(select_module = d['select_module'],
                table_schema = d['table_schema'],
                table_name = d['table_name'],
                uk_name = d['uk_name'],
                column = d['column'],
                threshold_time = d['threshold_time']
                )
    )
    first_sql = "%s order by %s limit 1;"%(general_sql, d['uc_name'])
    last_sql = "%s order by %s desc limit 1;"%(general_sql, d['uc_name'])
    f = connMySQL(first_sql, d['conn_instance'])
    l = connMySQL(last_sql, d['conn_instance'])
    if f and l:
        f = f[0]['%s'%(d['uc_name'])]
        l = l[0]['%s'%(d['uc_name'])]
        v = (f, l)
        #v = (f[0]['%s'%d[uc_name]], l[0]['%s'%d[uc_name]])
    else:
        v = False
    return v


def deletePoint(v):
    return str(v.replace('.',''))

def returnTaskID(ip, port):
    false_ip = deletePoint(ip)
    timestamp = time.strftime("%H%M%S_%Y%m%d")
    task_id = "%s_%s_%s"%(false_ip, port, timestamp)
    return task_id

def splitPoint(v):
    return v.split('.',-1)[0], v.split('.',-1)[1]

def e():
    exit()


def showSlaveStatus(conn_setting):
    slave_status = connMySQL("SHOW SLAVE STATUS;", conn_setting)
    if slave_status:
        Slave_IO_Running = slave_status[0]['Slave_IO_Running']
        Slave_SQL_Running = slave_status[0]['Slave_SQL_Running']
        Seconds_Behind_Master = slave_status[0]['Seconds_Behind_Master']
        d = {
            'Seconds_Behind_Master':Seconds_Behind_Master,
            'Slave_IO_Running':Slave_IO_Running,
            'Slave_SQL_Running':Slave_SQL_Running
        }
    else:
        d = False
    return d


def checkReadonly(conn_setting):
    sql = "SHOW GLOBAL VARIABLES LIKE 'read_only';"
    v = connMySQL("SHOW GLOBAL VARIABLES LIKE 'read_only';", conn_setting)
    v = v[0]['Value']
    return v


def getUniqueKeyColumn(conn_setting=None, table_schema=None, table_name=None):
    sql = ("""select COLUMN_NAME from information_schema.COLUMNS 
            where table_schema='%s' and table_name='%s' and COLUMN_KEY='PRI'"""
            %(table_schema, table_name))
    cs1 = connMySQL(sql, conn_setting)
    sql = ("""select COLUMN_NAME from information_schema.COLUMNS 
            where table_schema='%s' and table_name='%s' and COLUMN_KEY='UNI'"""
            %(table_schema, table_name))
    cs2 = connMySQL(sql, conn_setting)
    c = cs1[0] if cs1 else cs2[0]
    if c:
        if len(c) > 1: # Todo:不支持联合主键或者联合唯一键
            v = False
        else:
            v = c['COLUMN_NAME']
    else:
        v = False
    return v


def getUniqueKeyName(conn_setting=None, table_schema=None, table_name=None, uc_name=None):
    sql = ("""SELECT INDEX_NAME FROM INFORMATION_SCHEMA.STATISTICS 
            where table_schema='%s' and table_name='%s' and COLUMN_NAME='%s';"""
            %(table_schema, table_name, uc_name))
    name = connMySQL(sql, conn_setting)
    name = name[0]['INDEX_NAME']
    return name

def getColumns(conn_setting=None, table_schema=None, table_name=None):
    sql = ("""select COLUMN_NAME from information_schema.COLUMNS 
            where table_schema='%s' and table_name='%s'"""
            %(table_schema, table_name))
    cs = connMySQL(sql, conn_setting)
    l = []
    for c in cs:
        c = c['COLUMN_NAME']
        l.append(c)
    return l

def getSelectModule(columns=None):
    s = ""
    for column in columns:
        if s:
            s = s + "," + column
            #s = "`%s`,%s"%(column, s)
        else:
            s = column
            #s = "`%s`"%column
    return s


def checkColumnType(conn_setting=None, table_schema=None, table_name=None, column=None):
    sql = ("""select DATA_TYPE from information_schema.COLUMNS
            where table_schema='%s' and table_name='%s' and COLUMN_NAME='%s'; """
            %(table_schema, table_name, column))
    v = connMySQL(sql, conn_setting)
    if v:
        v = v[0]['DATA_TYPE']
        if v == "int":
            r = "int"
        elif v == "datetime" or v == "date" or v == "timestamp":
            r = "char"
        else:
            r = False
    else:
        r = False
    return r


#def checkIndexType()
#    #column_type = checkColumnType(conn_instance, info['table'], info['column'])
#    if not column_type:
#        print("%s:索引列只能是时间类型(int|datetime|date|timestamp)" % (task_id))
#        return False
#    else:
#        dt = getHorizondate(info['keep_days'])
#        if column_type == "int":
#            horizon_time = ChangedatetimeToTimestamp(dt)
#        else:
#            horizon_time = dt
#    return pri_column, column_type, horizon_time


def checkMain(d):

    d_slave_status = showSlaveStatus(d['conn_instance'])
    if d_slave_status:
        if d_slave_status['Slave_IO_Running'] == "Yes" or d_slave_status['Slave_IO_Running'] == "Yes":
            printLog("[%s]天外有天"%d['task_id'])
            return False

    if checkReadonly(d['conn_instance']).upper() != "OFF":
        print("[%s]主库read_only是ON?"%d['task_id'])
        return False

    uc_name = getUniqueKeyColumn(conn_setting=d['conn_instance'], table_schema=d['table_schema'], table_name=d['table_name'])
    if not uc_name:
        printLog("[%s]找不到唯一约束"%['task_id'], normal_log)
        info = False
    else:
        ck_type = checkColumnType(conn_setting=d['conn_instance'], table_schema=d['table_schema'], table_name=d['table_name'], column=d['column'])
        if not ck_type:
            printLog("[%s]匹配列字段类型只能为时间类型(int|datetime|date|timestamp)"%(d['task_id']), normal_log)
            info = False
        else:
            uk_name = getUniqueKeyName(conn_setting=d['conn_instance'], table_schema=d['table_schema'], table_name=d['table_name'], uc_name=uc_name)
            columns = getColumns(conn_setting=d['conn_instance'], table_schema=d['table_schema'], table_name=d['table_name'])
            select_module = getSelectModule(columns)
            info = uc_name,ck_type,uk_name,columns,select_module
    return info


def checkTableType(conn_setting=None, table_schema=None, table_name=None):
    sql = ("""select count(*) from information_schema.PARTITIONS
            where table_schema='%s' and table_name='%s' and PARTITION_NAME is NOT NULL"""
            %(table_schema,table_name))
    is_count = connMySQL(sql, conn_setting)
    is_count = is_count[0]['count(*)']
    v = True if is_count > 0 else False
    return v


def getThresholdTime(ck_type=None, days=None):
    d = (datetime.datetime.now() + datetime.timedelta(days=int("-%s"%int(days)))).strftime("%Y-%m-%d")
    if ck_type == 'int':
        try:
            time.strptime("%s 00:00:01"%d,'%Y-%m-%d %H:%M:%S')
            threshold_time = int(time.mktime(time.strptime("%s 00:00:01"%d,'%Y-%m-%d %H:%M:%S')))
        except ValueError, e:
            time.strptime(d,'%Y-%m-%d %H:%M:%S')
            threshold_time = int(time.mktime(time.strptime(d,'%Y-%m-%d %H:%M:%S')))
    else:
        threshold_time = d
    return threshold_time


def runShell(c):
    return commands.getoutput(c)


def backupData(d, f_begin=None, f_end=None):

    general_sql = ("""from {table_schema}.{table_name}"""
            """ FORCE INDEX({uk_name})"""
            """ WHERE {column}<'{threshold_time}'"""
            """ AND {uc_name}>='{f_begin}'""" # 左开
            """ AND {uc_name}<='{f_end}'""" # 又闭
            """ ORDER BY {uc_name}""".format(
                    table_schema = d['table_schema'],
                    table_name = d['table_name'],
                    uk_name = d['uk_name'],
                    column = d['column'],
                    threshold_time = d['threshold_time'],
                    uc_name = d['uc_name'],
                    f_begin = f_begin,
                    f_end = f_end
                )
    )
        
    backup_sql = "SELECT %s %s;"%(d['select_module'], general_sql)
    cmd = ("""{mysql} -u{user} -p{passwd} -h{host} -P{port} -e "{sql}" -N --default-character-set='utf8'"""
            .format(
                mysql = mysql,
                user = getKV(k='backup_user'),
                passwd = getKV(k='backup_pass'),
                host = getKV(k='backup_host'),
                port = getKV(k='backup_port'),
                sql = backup_sql)
    )
    print runShell(cmd)
    return
    load_sql = ("""LOAD DATA LOCAL INFILE '%s' REPLACE INTO TABLE %s CHARACTER SET UTF8 (%s)"""
            %(d['tmp_file'], d['t_backup'], d['select_module']))
    #cmd = ("""echo $(%s -u%s -p%s -h%s -P%s -N -e "%s")| sed "s/ /','/g"| sed -e "s/^/'/g" -e "s/$/'/g" """%
    #  (mysql,conn_instance['user'], conn_instance['passwd'], conn_instance['host'], conn_instance['port'], sql))
    #id_range = self.pc.runShell(cmd)


def getCurFL(d=None, f0=None, max_value=None):

    rconf = getKVDict(realtime_keys, ip=d['ip'], port=d['port']) # 实时keys,每次读取数据库最新数据
    archive_count = int(rconf['archive_count'])

    general_sql = ("""from {table_schema}.{table_name}"""
            """ FORCE INDEX({uk_name})"""
            """ WHERE {column}<'{threshold_time}'"""
            """ AND {uc_name}>='{f0}'""" # 左开
            """ AND {uc_name}<'{max_value}'""" # 又闭
            """ ORDER BY {uc_name}""".format(
                    table_schema = d['table_schema'],
                    table_name = d['table_name'],
                    uk_name = d['uk_name'],
                    column = d['column'],
                    threshold_time = d['threshold_time'],
                    uc_name = d['uc_name'],
                    f0 = f0,
                    max_value = max_value,
                )
    )
        
    f12_sql = "SELECT %s %s limit %s,2;"%(d['select_module'], general_sql, archive_count-1)
    f12 = connMySQL(f12_sql, d['conn_instance'], 0)
    if f12:
        f1 = f12[0][0]
        f2 = f12[1][0]
        print f0, f1, f2
        backupData(d=d, f_begin=f0, f_end=f1)
        getCurFL(d=d, f0=f2, max_value=max_value)
        v = True
    else: # 已经到末尾了
        f1_sql = "SELECT %s %s limit 1;"%(d['select_module'], general_sql)
        f1 = connMySQL(f1_sql, d['conn_instance'], 0)
        f1 = f1[0][0]
        f2 = max_value # Todo:最后一条数据获取不到
        print f0, f1, f2
        backupData(d=d, f_begin=f1, f_end=f2)
        v = False
    if not v:
        return
        

def archiveTableMain(d):
    
    getCurFL(d=d, f0=d['f_uc_name'], max_value=d['l_uc_name'])       


def getTableDefion(conn_setting=None, table_schema=None, table_name=None):

    sql = "show create table %s.%s"%(table_schema, table_name)
    v = connMySQL(sql, conn_setting)
    if v:
        v = v[0]['Create Table']
        v = re.sub('AUTO_INCREMENT=[0-9].*','',v)  
    else:
        v = False
    return v

def createBackupTable(conn_setting=None, t_new=None, t_old=None, t_defition=None):
    table_schema,table_name  = splitPoint(t_new)
    t_defition = re.sub('`%s`'%t_old, t_new, t_defition)  
    createTable(conn_setting=conn_setting, t=t_new, t_defition=t_defition)

def createTable(conn_setting=None, t=None, t_defition=None):

    table_schema,table_name  = splitPoint(t)
    sql = ("""select count(*) from information_schema.tables where table_schema='%s' and table_name='%s'"""%(table_schema, table_name))
    v = connMySQL(sql, conn_setting)
    if v:
        if v[0]['count(*)'] == 0:
            connMySQL(t_defition, conn_setting)
        else:
            return False
    else:
        return False


def processOneInstance(d_archive=None, dconf=None, sem=None):
    
    d_archive['task_id'] = returnTaskID(d_archive['ip'], d_archive['port'])
    d_archive['t_backup'] = 'mysql_archive_2018_db.t_backup_%s'%(d_archive['task_id'])
    d_archive['t_taskid'] = 'mysql_archive_2018_db.t_taskid_%s'%(d_archive['task_id'])
    d_archive['tmp_file'] = '%s/%s.txt'%(tmp_dir,d_archive['task_id'])
    d_archive['conn_instance'] = {
            'host' : d_archive['ip'],
            'port' : int(d_archive['port']),
            'user' : getKV(k='ddl_user', ip=d_archive['ip'], port=int(d_archive['port'])),
            'passwd' : getKV(k='ddl_pass', ip=d_archive['ip'], port=int(d_archive['port']))
    }
    d_archive['table_schema'], d_archive['table_name'] = splitPoint(d_archive['table'])
    printLog("[%s]begin:检测参数"%d_archive['task_id'], normal_log, 'green')
    check_info = checkMain(d_archive)
    if not check_info:
        printLog("[%s]end:参数有误,退出逻辑"%d_archive['task_id'], normal_log, 'red')
        return False # Tips:跳转

    else:
        printLog("[%s]end:参数正常"%d_archive['task_id'], normal_log, 'green')
    d_archive['uc_name'] = check_info[0]
    d_archive['ck_type'] = check_info[1]
    d_archive['uk_name'] = check_info[2]
    d_archive['columns'] = check_info[3]
    d_archive['select_module'] = check_info[4]
    d_archive['threshold_time'] = getThresholdTime(ck_type=d_archive['ck_type'], days=d_archive['keep_days'])
    fl = getFL(d_archive)
    if not fl:
        printLog("[%s]找不到需要归档的数据"%(d_archive['task_id']), normal_log)
        return False # Tips:再一次跳转
    else:
        d_archive['f_uc_name'] = fl[0]
        d_archive['l_uc_name'] = fl[1]
        printLog("[%s]本次计划归档的数据(%s:%s-%s)"
                    %(d_archive['task_id'], d_archive['uc_name'], 
                    d_archive['f_uc_name'], d_archive['l_uc_name']), 
                normal_log)
    t_task_id_defition = example_sql.replace('table_schema.table_name', '%s'%(d_archive['t_taskid']))
    createTable(conn_setting=conn_dbadb, t=d_archive['t_taskid'], t_defition=t_task_id_defition)
    if d_archive['backup_status'].upper() == 'Y':
        table_deftion = getTableDefion(conn_setting=d_archive['conn_instance'], 
                table_schema=d_archive['table_schema'], table_name=d_archive['table_name'])
        printLog("[%s]创建备份库%s"%(d_archive['task_id'], d_archive['t_backup']), normal_log)
        printLog("[%s]创建结果库%s"%(d_archive['task_id'], d_archive['t_taskid']), normal_log)
        createBackupTable(conn_setting=conn_dbadb, t_new=d_archive['t_backup'], t_old=d_archive['table_name'], t_defition=table_deftion)

    bool_partition = checkTableType(conn_setting=d_archive['conn_instance'], table_schema=d_archive['table_schema'], table_name=d_archive['table_name'])
    if bool_partition:
        pass
        #archivePartitions(mysql_archive, d_archive, check_info, task_id) # 分区表逻辑
    else:
        archiveTableMain(d_archive) # 单表逻辑

    sem.release() # 释放 semaphore


def getOnlineInfo(conn_setting, t):
    sql = ("""select 
                Fserver_host as `ip`,
                Fserver_port as `port`,
                Ftable as `table`,
                Fcolumn as `column`,
                Fkeep_days as `keep_days`,
                Fbackup_status as `backup_status` 
            from %s 
            where Fstate='online';"""%(t)
    )
    d = connMySQL(sql, conn_setting)
    return d

def getKV(k, ip=None, port=None):
    conn_setting = conn_dbadb
    w_generl = "Fstate='online' and Fkey='%s'"%(k)
    s1 = "select Fvalue from %s where %s;"%(t_conf_common, w_generl)
    if not port:
        port = 65536
    s2 = "select Fvalue from %s where %s and Fserver_host='%s' and Fserver_port='%s';"%(t_conf_person, w_generl, ip, port)
    v1 = connMySQL(s1, conn_setting)
    v2 = connMySQL(s2, conn_setting)
    v = v2 if v2 else v1
    v = v[0]['Fvalue'] if v else False
    return v


def getKVDict(conf_keys=conf_keys, ip=None, port=None):
    d = {}
    for key in conf_keys:
        d[key] = getKV(k=key, ip=ip, port=port)
    return d


def main():

    printLog('===start execute archive progress.', normal_log, 'purple')

    dconf = getKVDict(conf_keys)
    archive_infos = getOnlineInfo(conn_dbadb, dconf['t_mysql_archive_info'])
    thread_num = 3 # 同时跑的线程数
    sem = Semaphore(thread_num) 
    threads = []
    for archive_info in archive_infos:
        t = threading.Thread(target=processOneInstance, args=(archive_info, dconf, sem))
        threads.append(t)
    length = len(threads)
    for i in range(length):
        sem.acquire()
        threads[i].start()
    for i in range(length):
        threads[i].join()

    printLog('===archive progress is Done.', normal_log, 'purple')


if __name__ == '__main__':

    main()

