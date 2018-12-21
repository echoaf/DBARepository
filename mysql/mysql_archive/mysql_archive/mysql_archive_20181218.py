#!/usr/bin/env python
#coding=utf8

import sys
import os
import time
import datetime
import commands

import threading
from threading import Thread, Semaphore

base_dir = '/data/DBARepository/mysql/mysql_archive'
common_dir = '%s/common'%base_dir
sys.path.append(common_dir)
from python_common import PulicConf as PC

reload(sys)
sys.setdefaultencoding('utf8')


log_dir = '%s/log'%(base_dir)
tmp_dir = '%s/tmp'%(base_dir)
backup_parent_dir = '%s/backup'%base_dir
#mysqlbinlog = '%s/mysqlbinlog'%(common_dir)
mysql = '%s/mysql'%(common_dir)
normal_log = '%s/python.log'%(log_dir)

conf_host = '172.16.112.12'
conf_port = 10000
conf_user = 'master_user'
conf_pass = 'redhat'
t_conf_common = 'conf_db.t_archive_conf_common'
t_conf_person = 'conf_db.t_archive_conf_person'

if not os.path.exists(log_dir):
    os.makedirs(log_dir)
if not os.path.exists(tmp_dir):
    os.makedirs(tmp_dir)
#if not os.path.exists(backup_parent_dir):
#    os.makedirs(backup_parent_dir)

conf_keys = (
    'archive_count',
    'dba_host',
    'dba_pass',
    'dba_port',
    'dba_user',
    'master_pass',
    'master_user',
    'repl_pass',
    'repl_user',
    'threads_running',
    't_mysql_archive_info',
    't_mysql_archive_result',
    't_mysql_info',
    'ddl_user',
    'ddl_pass',
)
example_sql = (
  "CREATE TABLE table_schema.table_name ("
  "Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',"
  "Ftask_id varchar(64) NOT NULL DEFAULT '' COMMENT '任务ID(ip_port_timestamp)',"
  "Funique_id varchar(64) NOT NULL DEFAULT '' COMMENT '唯一键',"
  "Fstart_pos varchar(2048) NOT NULL DEFAULT '' COMMENT '执行前位点',"
  "Fend_pos varchar(2048) NOT NULL DEFAULT '' COMMENT '执行结束位点',"
  "Fexec_status varchar(12) NOT NULL DEFAULT '' COMMENT '执行状态(Succ|Fail)',"
  "Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',"
  "PRIMARY KEY (Findex),"
  "UNIQUE KEY Ftask_unique_id(Ftask_id,Funique_id),"
  "KEY idx_Fmodify_time (Fmodify_time),"
  "KEY idx_Fexec_status (Fexec_status)"
") ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='MySQL归档结果流水表';")


class MySQLArchive(object):

    def __init__(self, pc=None, d=None):

        self.pc = pc
        self.d = d

    def initDBAConn(self):   
        d = {
            'host':self.d['dba_host'], 
            'port':int(self.d['dba_port']),
            'user':self.d['dba_user'],
            'passwd':self.d['dba_pass']
        }
        return d

    def checkArchiveInfo(self, info):
        conn_instance = {
                            'host':info['ip'],
                            'port':int(info['port']),
                            'user':self.d['master_user'], 
                            'passwd':self.d['master_pass']
        }
        conn_repl = {
                        'host':info['ip'],
                        'port':int(info['port']),
                        'user':self.d['repl_user'],
                        'passwd':self.d['repl_pass']
        }
        task_id = ("%s:%s" % (info['ip'], info['port']))
        d_slave = self.pc.showSlaveStatus(conn_repl)
        if d_slave:
            if d_slave['Slave_IO_Running'] == "Yes" or d_slave['Slave_IO_Running'] == "Yes":
                print("[%s]:天外有天"%task_id)
                return False
    
        if self.pc.checkReadonly(conn_instance).upper() != "OFF":
            print("[%s]:主库read_only是ON?" % task_id)
            return False

        pri_column = self.pc.getUinqueColumn(conn_instance, info['table'])
        if not pri_column:
            print("[%s]不好意思,找不到唯一约束" % task_id)
            return False

        column_type = self.pc.checkColumnType(conn_instance, info['table'], info['column'])
        if not column_type:
            print("%s:索引列只能是时间类型(int|datetime|date|timestamp)" % (task_id))
            return False
        else:
            dt = self.pc.getHorizondate(info['keep_days'])
            if column_type == "int":
                horizon_time = self.pc.ChangedatetimeToTimestamp(dt)
            else:
                horizon_time = dt
        return pri_column, column_type, horizon_time

    def getOnlineInfo(self):
        conn_setting = self.initDBAConn()
        sql = ("""select 
                        Fserver_host as `ip`,
                        Fserver_port as `port`,
                        Ftable as `table`,
                        Fcolumn as `column`,
                        Fkeep_days as `keep_days`,
                        Fbackup_status as `backup_status` 
                  from %s 
                  where Fstate='online';
              """
              %(self.d['t_mysql_archive_info'])
       )
        d = self.pc.connMySQL(sql,conn_setting)
        return d

    def getInstanceDelayTime(self, master_ip, master_port):
        conn_setting = self.initDBAConn()
        max_delay_time = 0
        sql = ("""select 
                        Fserver_host,Fserver_port 
                  from %s 
                  where Fstate='online' 
                        and Ftype in 
                        (select distinct Ftype from %s 
                        where Fstate='online' and Fserver_host='%s' and Fserver_port='%s');
              """
              %(self.d['t_mysql_info'], self.d['t_mysql_info'], 
                    master_ip, master_port
               )
        )
        instances = self.pc.connMySQL(sql,conn_setting)
        for instance in instances:
            ip = instance['Fserver_host']
            port = instance['Fserver_port']
            conn_instance = {
                            'host':ip,
                            'port':int(port), 
                            'user':self.d['repl_user'],
                            'passwd':self.d['repl_pass']
            }
            delay_time = self.pc.getDelayTime(conn_instance)
            max_delay_time = delay_time if delay_time > max_delay_time else max_delay_time
        return max_delay_time

    def returnTaskID(self, ip, port):
        false_ip = self.pc.deletePoint(ip)
        timestamp = time.strftime("%H%M%S_%Y%m%d")
        task_id = "%s_%s_%s"%(false_ip, port, timestamp)
        return task_id

    def importToLocal(
                     self, archive_info, horizon_time, t_task_id, 
                     load_big_file, task_id, pri_column, user, passwd
        ):
        """
        Todo:
            1、从集群从库查数据
            2、可能数据集合一次性会捞太大,超过限制异常
        """
        #Tips:task_id+pri_column构成流水表唯一键
        sql = ("""select '%s',%s from %s where %s<'%s' limit 100000;"""
                  %(task_id, pri_column, archive_info['table'], archive_info['column'], horizon_time)
              )
        cmd = ("""%s -u%s -p%s -h%s -P%s -N -e "%s" >%s""" 
                %(mysql, user, passwd, archive_info['ip'], archive_info['port'],sql, load_big_file)
              )
        self.pc.runShell(cmd)

    def loadToMySQL(self, archive_info, pri_column, horizon_time, 
                   t_task_id, load_big_file, task_id, load_user, load_pass
        ):
        """
        Tips:
            使用split分隔成小文件load to mysql
            split -d -l 1000000 1721611212_10000.txt 1721611212_10000_split
        """
        file_pre = "%s_split"%(task_id)
        sp_cmd = "cd %s && split -d -l 10000 %s %s" % (tmp_dir, load_big_file, file_pre)
        self.pc.runShell(sp_cmd)
        files_cmd = "ls %s/%s*" % (tmp_dir, file_pre)
        files = self.pc.runShell(files_cmd)
        files = files.split('\n') # 转换为list
        for file_name in files:
            sql = "LOAD DATA LOCAL INFILE '%s' REPLACE INTO TABLE %s (Ftask_id,Funique_id);" % (file_name, t_task_id)
            cmd = ("""%s -u%s -p%s -h%s -P%s -N -e "%s" """
                      %(mysql, load_user, load_pass,archive_info['ip'], archive_info['port'], sql
                       )
                  )
            self.pc.printLog("[%s]load split file to mysql(%s)"%(task_id,t_task_id),normal_log)
            self.pc.runShell(cmd)
            self.pc.runShell("rm -fv %s"%file_name)
        self.pc.runShell("rm -fv %s"%load_big_file)

    def deleteDo(self, conn_instance, conn_dba, 
                table, pri_column, t_task_id, task_id
        ):
        """
        Tips
            1、实时读取数据库:threads_running|archive_count
        """
        sql = "select max(Findex) as max_num,min(Findex) as min_num from %s;"%(t_task_id)
        nums = self.pc.connMySQL(sql,conn_dba)
        if not nums[0]['min_num'] or not num[0]['max_num']:
            self.pc.printLog("[%s]没有需要处理的数据"%(task_id),normal_log)
            return
        repl_user = self.pc.getKV('repl_user')
        repl_pass = self.pc.getKV('repl_pass')
        conn_repl = {
                        'host':conn_instance['host'],
                        'port':int(conn_instance['port']),
                        'user':repl_user,
                        'passwd':repl_pass
                    }
        min_num = int(nums[0]['min_num'])
        max_num = int(nums[0]['max_num']) + 1
        # Tips:由于自增主键断层,并不是实际值
        count = max_num - min_num
        self.pc.printLog("[%s]总计大约需要处理%s条数据"%(task_id,max_num),normal_log)
        cur_num = min_num
        while cur_num < max_num:                
            archive_count = self.pc.getKV('archive_count') # 实时读取数据库
            right_num = int(cur_num) + int(archive_count)
            sql = "select Funique_id from %s where Findex>=%s and Findex<%s;"%(t_task_id,cur_num,right_num) # 左闭右+1
            cmd = ("""echo $(%s -u%s -p%s -h%s -P%s -N -e "%s")| sed "s/ /','/g"| sed -e "s/^/'/g" -e "s/$/'/g" """%
                  (mysql,conn_instance['user'], conn_instance['passwd'], conn_instance['host'], conn_instance['port'], sql))
            id_range = self.pc.runShell(cmd)
            cur_sql = """delete from %s where %s in (%s);"""%(table, pri_column, id_range)
            self.pc.printLog("[%s]开始处理主键区间:%s-%s"%(task_id,cur_num,right_num), normal_log)
            start_pos = self.pc.showMasterStatus(conn_repl)
            self.pc.connMySQL(cur_sql,conn_instance)
            end_pos = self.pc.showMasterStatus(conn_repl)
            update_sql = ("""update %s 
                             set Fexec_status='Succ',Fstart_pos="%s",Fend_pos="%s" 
                             where Findex>=%s and Findex<%s;"""
                             %(t_task_id,start_pos,end_pos,cur_num,right_num)
                         ) # 左闭右+1
            self.pc.connMySQL(update_sql, conn_dba)

            cur_num = right_num # 置换
    
            # 判断参数
            sleep_time = self.getInstanceDelayTime(conn_instance['host'], conn_instance['port'])
            if sleep_time > 0:
                self.pc.printLog("[%s]检测数据库延迟了%ss,sleep..."%(task_id,sleep_time), normal_log)
                time.sleep(sleep_time)
    
            threads_running = self.pc.checkRunning(conn_instance)
            threads_running_max = self.pc.getKV('threads_running') 
            if threads_running >= threads_running_max:
                self.pc.printLog("[%s]检测数据库连接数为%s(阈值%s),sleep 10s..."%(task_id,threads_running,threads_running_max), normal_log)
                time.sleep(10)

def archivePartitions(archive_info, mysql_archive, check_info, task_id):
    pc = mysql_archive.pc
    table_schema,table_name  = pc.splitPoint(archive_info['table'])
    pri_column, column_type, horizon_time = check_info
    ddl_user = pc.getKV('ddl_user')
    ddl_pass = pc.getKV('ddl_pass')
    conn_instance = {
        'host' : archive_info['ip'],
        'port' : int(archive_info['port']),
        'user' : ddl_user,
        'passwd' : ddl_pass
    }
    where_module = """TABLE_NAME IS NOT NULL
                and PARTITION_METHOD = 'RANGE COLUMNS'
                and table_schema='%s' 
                and table_name='%s' 
                and PARTITION_EXPRESSION='`%s`' 
                and PARTITION_DESCRIPTION<'%s';
         """%(table_schema,table_name,archive_info['column'],horizon_time)
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
    sum_info = pc.connMySQL(sql1,conn_instance)
    sum_info = sum_info[0]
    if sum_info['TABLE_COUNT'] == 0:
        pc.printLog("[%s]没有需要删除的分区"
                %(archive_info['table']),normal_log)
        return
    ps = pc.connMySQL(sql2,conn_instance,"0")
    v = ""
    for p in ps:
        p = p[0]
        if not v:
            v = p
        else:
            v = v + "," + p
    pc.printLog("[%s]开始执行删除语句,预计删除分区个数:%s,行数:%s,数据量大小:%sM"
            %(archive_info['table'], sum_info['TABLE_COUNT'], 
            sum_info['TABLE_ROWS'], sum_info['DATA_LENGTH']),
            normal_log)
    sql = ("""alter table %s.%s drop partition %s"""
            %(sum_info['TABLE_SCHEMA'],sum_info['TABLE_NAME'],v))
    pc.printLog((sql),normal_log)
    pc.connMySQL(sql,conn_instance)


def perfectInfo(table_info, pc, conn_instance):
    table_info['uc_name'] = pc.getUniqueKeyColumn(conn_instance, table_info)
    if not table_info['uc_name']:
        print("[%s]唯一索引有问题" % task_id)
        table_info = False
    else:
        table_info['uk_name'] = pc.getUniqueKeyName(conn_instance, table_info)
        table_info['columns'] = pc.getColumns(conn_instance, table_info)
        table_info['select_module'] = pc.getSelectModule(table_info['columns'])
    return table_info
    

def archiveTable(mysql_archive, archive_info, check_info, table_info, task_id):
    pri_column, column_type, horizon_time = check_info
    load_big_file = "%s/%s.txt"%(tmp_dir,task_id)
    ##### create table
    t_task_id = "mysql_archive_2018_db.t_%s"%(task_id)
    create_sql = example_sql.replace("table_schema.table_name", t_task_id)
    pc.printLog("[%s]create water table:%s"%(task_id,t_task_id), normal_log)
    pc.createTable(create_sql, t_task_id, conn_dba)
    # load数据
    archive_sql = ("delete from %s where %s<'%s';" %(archive_info['table'], archive_info['column'], horizon_time))
    pc.printLog("[%s]import data to file"%(task_id),normal_log)
    mysql_archive.importToLocal(archive_info, horizon_time,
                                    t_task_id, load_big_file, 
                                    task_id, pri_column, master_user, master_pass
                               )
    pc.printLog("[%s]start load big file to mysql(%s)" %(task_id,t_task_id),normal_log)
    mysql_archive.loadToMySQL(archive_info, pri_column, horizon_time, 
                                t_task_id, load_big_file,
                                task_id, load_user, load_pass
                             )
    pc.printLog("[%s]end load big file to mysql(%s)" %(task_id,t_task_id),normal_log)
    # 更新t_mysql_archive_result
    t_mysql_archive_result = pc.getKV('t_mysql_archive_result')
    sql = "select count(*) from %s;" % (t_task_id)
    deal_count = pc.connMySQL(sql,conn_dba)[0]['count(*)']
    ins_s = ("""select '%s',current_date(),'%s','%s','%s','%s','%s',"%s",now(),now()"""%
            (task_id,archive_info['ip'], archive_info['port'], 
            archive_info['table'], deal_count, 'Init', archive_sql))
    ins_sql = ("""insert into %s (Ftask_id,Fdate,Fip,Fport,Ftable,
              Fcount,Fexec_status,Fsql,Fcreate_time,Fmodify_time) %s"""%
              (t_mysql_archive_result,ins_s))
    pc.connMySQL(ins_sql,conn_dba)
    
    # 删除数据逻辑
    mysql_archive.deleteDo(conn_instance, conn_dba, archive_info['table'], 
                          pri_column, t_task_id, task_id)
    
    # 更新t_mysql_archive_result
    exec_status = "Succ"
    sql = ("""update %s set Fcount='%s',Fexec_status='%s',Fmodify_time=now() where Ftask_id='%s';"""%
          (t_mysql_archive_result, deal_count, exec_status, task_id))
    pc.connMySQL(sql,conn_dba)
    pc.printLog("[%s]is done"%(task_id),normal_log)

def processOneInstance(archive_info, mysql_archive, sem):
    task_id = mysql_archive.returnTaskID(archive_info['ip'], archive_info['port'])
    pc = mysql_archive.pc
    master_user = pc.getKV('master_user')
    master_pass = pc.getKV('master_pass')
    conn_instance = {
            'host' : archive_info['ip'],
            'port' : int(archive_info['port']),
            'user' : master_user,
            'passwd' : master_pass
    }
    table_schema,table_name  = pc.splitPoint(archive_info['table'])

    check_info = mysql_archive.checkArchiveInfo(archive_info)
    table_info = {
            'table_schema' : table_schema, 
            'table_name' : table_name,
            'columns' : None, 
            'uc_name' : None, 
            'uk_name' : None,
            'select_module' : None
    }
    table_info = perfectInfo(table_info, pc, conn_instance)
        
    if not check_info or not table_info: 
        print("[%s]结束检测参数,遗憾检测不通过" % task_id)
        return
    else:
        table_info = table_info
        print("[%s]结束检测参数,恭喜检测通过" % task_id)
    table_info = dict(table_info)
    exit()

    # Tips:检测是否是分区表
    sql = ("""select count(*) from information_schema.PARTITIONS
            where table_schema='%s' and table_name='%s' 
            and PARTITION_NAME is NOT NULL"""
            %(table_schema,table_name))
    is_count = pc.connMySQL(sql, conn_instance)
    is_count = is_count[0]['count(*)']
    if is_count > 0:
        #archivePartitions(mysql_archive, archive_info, check_info, task_id) # 分区表逻辑
        print "分区表逻辑"
    else:
        archiveTable(mysql_archive, archive_info, check_info, table_info, task_id) # 单表逻辑

    sem.release() # 释放 semaphore


def getKVDict(pc):
    d = {}
    for key in conf_keys:
        d[key] = pc.getKV(key)
    return d


def main():

    pc = PC(conf_host, conf_port, conf_user, conf_pass, t_conf_common, t_conf_person)
    d = getKVDict(pc)
    mysql_archive = MySQLArchive(pc, d)
    archive_infos = mysql_archive.getOnlineInfo()
    mysql_archive.pc.printLog('======start execute archive progress.', normal_log)
    # 使用多线程
    #processOneInstance(archive_info, mysql_archive)
    thread_num = 3 # 同时跑的线程数
    sem = Semaphore(thread_num) # 设置计数器的值为
    threads = []
    for archive_info in archive_infos:
        t = threading.Thread(target=processOneInstance,
                args=(archive_info,mysql_archive,sem))
        threads.append(t)
    length = len(threads)
    for i in range(length): # start threads
        sem.acquire() # 获取一个semaphore
        threads[i].start()
    for i in range(length): # wait for all
        threads[i].join() # threads to finish
    mysql_archive.pc.printLog('======all DONE.',normal_log)


if __name__ == '__main__':

    main()

