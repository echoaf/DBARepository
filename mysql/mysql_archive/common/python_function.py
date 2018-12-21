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


class PubicFunction(object):

    def __init__(self):
        pass



    def getKV(self, key, ip=None, port=None):
        d = {'host':self.conf_host, 'port':self.conf_port, 'user':self.conf_user, 'passwd':self.conf_pass} 
        w_generl = "Fstate='online' and Fkey='%s'"%(key)
        s1 = "select Fvalue from %s where %s;"%(self.t_conf_common,w_generl) 
        if not port:
            port = 65536
        s2 = "select Fvalue from %s where %s and Fserver_host='%s' and Fserver_port='%s';"%(self.t_conf_person,w_generl,ip,port)
        v1 = self.connMySQL(s1, d)
        v2 = self.connMySQL(s2, d)
        v = v2 if v2 else v1
        v = v[0]['Fvalue'] if v else False
        return v


    def ChangedatetimeToTimestamp(self, d):
        try:
            time.strptime("%s 00:00:01"%d,'%Y-%m-%d %H:%M:%S')
            s = time.mktime(time.strptime("%s 00:00:01"%d,'%Y-%m-%d %H:%M:%S'))
        except ValueError, e:
            time.strptime(d,'%Y-%m-%d %H:%M:%S')
            s = time.mktime(time.strptime(d,'%Y-%m-%d %H:%M:%S'))
        return int(s)
    
    def deletePoint(self, v):
        return str(v.replace('.',''))

    def runShell(delf, c):
        return commands.getoutput(c)

    def splitPoint(self, v):
        return v.split('.',-1)[0], v.split('.',-1)[1]

    def checkRunning(self, d):
        sql = "SHOW GLOBAL STATUS LIKE 'Threads_running';"
        r = self.connMySQL(sql,d)
        return int(r[0]['Value'])

    def getHorizondate(self, days):
        today = datetime.datetime.now()
        d = (today + datetime.timedelta(days=int("-%s"%int(days)))).strftime("%Y-%m-%d")
        return d

    def showMasterStatus(self, d):
        sql = "SHOW MASTER STATUS;"
        v = self.connMySQL(sql, d)
        v = dict(v[0]) if v else False
        return v

    def createTable(self, sql,table, d):
        table_schema,table_name  = self.splitPoint(table)
        check_sql = ("""select count(*) 
                from information_schema.tables 
                where table_schema='%s' and table_name='%s' """
                %(table_schema,table_name))
        v = self.connMySQL(check_sql, d)
        if v:
            if v[0]['count(*)'] == 0:
                self.connMySQL(sql, d)
        else:
            self.connMySQL(sql,d)

    def getDelayTime(self, d):
        delay_time = self.showSlaveStatus(d)
        if delay_time:
            delay_time = delay_time['Seconds_Behind_Master']
            try:
                delay_time = int(delay_time)
            except Exception,e:
                delay_time = 8640000
        else:
            delay_time = 0
        return delay_time

    def showSlaveStatus(self, d):
        sql = "SHOW SLAVE STATUS;"
        slave_status = self.connMySQL(sql,d)
        if slave_status:
            Slave_IO_Running = slave_status[0]['Slave_IO_Running']
            Slave_SQL_Running = slave_status[0]['Slave_SQL_Running']
            Seconds_Behind_Master = slave_status[0]['Seconds_Behind_Master']
            d = {'Seconds_Behind_Master':Seconds_Behind_Master,
                    'Slave_IO_Running':Slave_IO_Running,
                    'Slave_SQL_Running':Slave_SQL_Running
            }
        else:
            d = False
        return d

    def checkReadonly(self, d):
        sql = "SHOW GLOBAL VARIABLES LIKE 'read_only';"
        v = self.connMySQL(sql,d)
        v = v[0]['Value']
        return v

    def getUinqueColumn(self, d, table):
        table_schema,table_name  = self.splitPoint(table)
        sql = ("""select COLUMN_NAME 
                from information_schema.COLUMNS 
                where COLUMN_KEY='PRI' and table_schema='%s' and table_name='%s'; """
                %(table_schema,table_name))
        v = self.connMySQL(sql,d,0)
        if v:
            v = v[0]
            if len(v) > 1:
                v = False
            else:
                v = v[0]
        else:
            v = False
        return v

    def checkColumnType(self, d, table,column):
        table_schema,table_name  = self.splitPoint(table)
        sql = ("""select DATA_TYPE from information_schema.COLUMNS
                where table_schema='%s' and table_name='%s' and COLUMN_NAME='%s'; """
                %(table_schema,table_name,column))
        v = self.connMySQL(sql,d)
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

    def getUniqueKeyName(self, conn_instance, d):
        #d = {table_schema:'', table_name:'', columns='', uc_name='', uk_name=''}
        sql = ("""SELECT INDEX_NAME FROM INFORMATION_SCHEMA.STATISTICS 
                where table_schema='%s' and table_name='%s' and COLUMN_NAME='%s';"""
                %(d['table_schema'], d['table_name'], d['uc_name']))
        name = self.connMySQL(sql, conn_instance)
        name = name[0]['INDEX_NAME']
        return name
    
    def getUniqueKeyColumn(self, conn_instance, d):
        sql = ("""select COLUMN_NAME from information_schema.COLUMNS 
                where table_schema='%s' and table_name='%s' and COLUMN_KEY='PRI'"""
                %(d['table_schema'], d['table_name']))
        cs1 = self.connMySQL(sql, conn_instance)
        sql = ("""select COLUMN_NAME from information_schema.COLUMNS 
                where table_schema='%s' and table_name='%s' and COLUMN_KEY='UNI'"""
                %(d['table_schema'], d['table_name']))
        cs2 = self.connMySQL(sql, conn_instance)
        if cs1:
            c = cs1[0]
        else:
            c = cs2[0]
        if c:
            if len(c) > 1: # Todo:不支持联合主键或者联合唯一键
                v = False
            else:
                v = c['COLUMN_NAME']
        else:
            v = False
        return v
    
    def getColumns(self, conn_instance, d):
        sql = ("""select COLUMN_NAME from information_schema.COLUMNS 
                where table_schema='%s' and table_name='%s'"""
                %(d['table_schema'], d['table_name']))
        cs = self.connMySQL(sql, conn_instance)
        l = []
        for c in cs:
            c = c['COLUMN_NAME']   
            l.append(c)
        return l
    
    def getSelectModule(self, columns):
        s = ""
        for column in columns:
            if s:
                s = s + "," + column
            else:
                s = column
        return s
    
    def getFL(self, d, f0, f_max, num, select_module):
        #d = {table_schema:'', table_name:'', columns='', uc_name='', uk_name=''}
        sql = ("""select %s
                from %s.%s 
                FORCE INDEX(%s) 
                where Fmodify_time<'2018-12-17' 
                    and %s > '%s'
                    and %s <= '%s'
                order by %s limit %s,2;"""
                %(d['uc_name'], d['table_schema'], d['table_name'],
                    d['uk_name'], d['uc_name'], f0,
                    d['uc_name'], f_max, d['uc_name'], num-2))
        info = self.connMySQL(sql, conn_instance, 0)
        if not info:
            sql = ("""select %s
                    from %s.%s 
                    FORCE INDEX(%s) 
                    where Fmodify_time<'2018-12-17' 
                        and %s > '%s'
                        and %s <= '%s'
                    order by %s limit 1;"""
                    %(d['uc_name'], d['table_schema'], d['table_name'],
                        d['uk_name'], d['uc_name'], f0, d['uc_name'],
                        f_max, d['uc_name']))
            info = self.connMySQL(sql, conn_instance, 0)
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


    #def initDBAConn(self):   
    #    d = {
    #        'host':self.d['dba_host'], 
    #        'port':int(self.d['dba_port']),
    #        'user':self.d['dba_user'],
    #        'passwd':self.d['dba_pass']
    #    }
    #    return d

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
