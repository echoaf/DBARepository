#!/usr/bin/env python
#coding=utf8

import sys
import os
import os.path
import time
import re
import pprint
import datetime
import commands
import subprocess
import logging
import linecache
import MySQLdb
import MySQLdb.cursors


class MySQLBackupFunction(object):

    def __init__(self, BF=None, dconf=None):

        self.BF = BF
        self.dconf = dconf

    def getOnlineFullbackupInfo(self):
    
        #sql = ("""select Ftype as instance,
        #                Fsource_host as source_host,
        #                Fsource_port as source_port,
        #                Fmode as backup_mode,
        #                Fweekday as backup_weekday,
        #                Fstart_time as backup_start_time,
        #                Fend_time as backup_end_time,
        #                Fclear_rule as backup_clear_rule
        #            from {table}
        #            where Fstate='online'
        #                and Faddress='{address}'"""
        #            .format(table = self.dconf['t_mysql_fullbackup_info'],
        #                address = self.dconf['local_ip']
        #            )
        #       )
        sql = ("""select Ftype as instance,
                        Fmydumper as is_mydumper,
                        Fxtrabackup as is_xtrabackup,
                        Fmysqldump as mysqldump
                    from {table} 
                    where Fstate='online';"""
                    .format(table = self.dconf['t_mysql_fullbackup_info'])
        )
        v = self.BF.connMySQL(sql, self.dconf['conn_dbadb'])
        return v


    def getOnlineBinarybackupInfo(self):
    
        sql = ("""select Ftype as instance,
                        Fsource_host as source_host,
                        Fsource_port as source_port,
                        Fname as name
                    from {table}
                    where Fstate='online'
                        and Faddress='{address}'"""
                    .format(table = self.dconf['t_mysql_binarylog_info'],
                        address = self.dconf['local_ip']
                    )
               )
        v = self.BF.connMySQL(sql, self.dconf['conn_dbadb'])
        return v


    def findFirstBinaryLogName(self):

        sql = "SHOW BINARY LOGS;"
        names = self.BF.connMySQL(sql=sql, d=self.dconf['conn_instance'], is_dict=0)
        if names:
            name = names[0][0]
        else:
            name = False
        return name

    def checkFullbackupTaskID(self):
        """return backup_status for task_id"""
        sql = ("""select Fbackup_status as backup_status from %s where Ftask_id='%s';"""
                %(self.dconf['t_mysql_fullbackup_result'], self.dconf['task_id']))
        v = self.BF.connMySQL(sql, self.dconf['conn_dbadb'])
        return v

    def getToday(self):
        """获取今天date,比如1970-01-01"""
        return time.strftime('%F',time.localtime())
    
    def compactTime(self, t):
        """获取今天date,比如19700101"""
        return t.replace('-', '')
    
    def getWeekDay(self):
        """获取本周是周几,比如返回0,代表周日"""
        return datetime.datetime.now().strftime("%w")
    
    def getSpecialtoday(self, w):
        """获取本周具体周几的日期"""
        # 本周周日的日期
        weekday_sun = (datetime.date.today() - datetime.timedelta(days=datetime.date.today().weekday()) 
                        + datetime.timedelta(days=6)) 
        t = weekday_sun + datetime.timedelta(days=int(w))
        return t
    
    def getFullbackupTaskID(self):
        today = self.getToday()
        compact_today = self.compactTime(today)
        weekday = int(self.getWeekDay())
        if int(self.dconf['f_info']['backup_weekday']) == 9:
            task_id = "{instance}-{datetime}".format(instance=self.dconf['f_info']['instance'], datetime=compact_today)
        elif int(self.dconf['f_info']['backup_weekday']) in range(0,7):
            if self.dconf['f_info']['backup_weekday'] > weekday: # 非我良时
                task_id = False
            else:
                d_today = self.getSpecialtoday(int(delf.dconf['f_info']['backup_weekday']))
                d_compact_today = self.compactTime(str(d_today))
                task_id = "{instance}-{datetime}".format(instance=self.dconf['f_info']['instance'], datetime=d_compact_today)
        else:
            task_id = False
        return task_id


    def doBackup(self):
        # Returns:True|False
        v_check = self.checkBackup()
        if not v_check:
            v = False 
        else:
            backup_mode = self.dconf['f_info']['backup_mode'].upper()
            if backup_mode == 'MYDUMPER':
                self.doBackupMydumper(wait=0)
                v = True
            elif backup_mode == 'XTRABACKUP':
                v = False
            elif backup_mode == 'MYSQLDUMP':
                v = False
            else:
                v = False
        return v
        

    def checkPath(self, path=None):
        if os.path.isdir(path):
            if os.listdir(path):
                self.BF.printLog("目录不为空:%s"%(path), self.dconf['normal_log'])
                v = False
            else:
                #self.BF.printLog("目录为空目录:%s"%(path), self.dconf['normal_log'])
                v = True
        else:
            self.BF.printLog("找不到目录:%s"%(path), self.dconf['normal_log'])
            v = False
        return v


    def checkActiveTrx(self, conn_setting=None):
    
        sql = "select count(*) as cnt from information_schema.innodb_trx;"
        cnt = self.BF.connMySQL(sql, conn_setting)
        if cnt[0]['cnt'] > 0:
            self.BF.printLog("""[%s:%s]数据库存在活跃事务:%s"""
                                %(conn_setting['host'],conn_setting['port'],cnt[0]['cnt']),
                                self.dconf['normal_log'])
            v = False
        else:
            v = True
        return v


    def getBinarylogTime(self, f, mysqlbinlog):
    
        cmd = ("""%s -vv %s 2>&1 | head -100 | grep "server id " | awk -F"server id" '{print $1}' | sed 's/#//g'| head -1"""%(mysqlbinlog, f))
        time1 = self.BF.runShell(cmd)[1]
        cmd2 = """date -d "%s" +"%%F %%T" """%(time1)
        time2 = self.BF.runShell(cmd2)[1]
        time2 = time2 if time2 else "1970-01-01 00:00:00"
        return time2

    def updateBinarybackup(self, d_result=None):
        sql = ("""select count(*) as cnt from {table} 
                    where Fsource_host='{host}' and Fsource_port='{port}' 
                    and Fname='{name}'"""
                .format(table = self.dconf['t_mysql_binarylog_result'],
                    host = d_result['host'],
                    port = d_result['port'],
                    name = d_result['name'])
              )

        cnt = self.BF.connMySQL(sql, self.dconf['conn_dbadb'])
        if cnt[0]['cnt'] == 0:
            u_sql = ("""insert into {table}"""
                            """ (Ftype,Fname,Fdate,Fsource_host,Fsource_port"""
                            """,Faddress,Fpath,Fsize,Fstart_time,Fbackup_status"""
                            """,Fbackup_info,Fcreate_time,Fmodify_time)"""
                            """ values"""
                            """ ('{instance}','{name}',curdate(),'{host}','{port}'"""
                            """,'{address}','{path}','{size}','{start_time}','{backup_status}'"""
                            """,'{backup_info}',now(),now());"""
                        .format(table = self.dconf['t_mysql_binarylog_result'],
                            instance = d_result['instance'],
                            name = d_result['name'],
                            host = d_result['host'],
                            port = d_result['port'],
                            address = d_result['address'],
                            path = d_result['path'],
                            size = d_result['size'],
                            start_time = d_result['start_time'],
                            backup_status = d_result['backup_status'],
                            backup_info = d_result['backup_info']
                        )
                    )
        else:
            u_sql = ("""update {table}"""
                            """ set Ftype='{instance}',Fname='{name}',Fdate=curdate(),"""
                            """ Fsource_host='{host}',Fsource_port='{port}'"""
                            """,Faddress='{address}',Fpath='{path}',Fsize='{size}'"""
                            """,Fstart_time='{start_time}',Fbackup_status='{backup_status}'"""
                            """,Fbackup_info='{backup_info}',Fmodify_time=now()"""
                            """ where Fsource_host='{host}' and Fsource_port='{port}'"""
                            """ and Fname='{name}';"""
                        .format(table = self.dconf['t_mysql_binarylog_result'],
                            instance = d_result['instance'],
                            name = d_result['name'],
                            host = d_result['host'],
                            port = d_result['port'],
                            address = d_result['address'],
                            path = d_result['path'],
                            size = d_result['size'],
                            start_time = d_result['start_time'],
                            backup_status = d_result['backup_status'],
                            backup_info = d_result['backup_info']
                        )
                    )
        print u_sql    
        self.BF.connMySQL(u_sql, self.BF.conn_dbadb)

    def updateFullbackup(self, d=None):
    
        sql = "select count(*) as cnt from %s where Ftask_id='%s';"%(self.dconf['t_mysql_fullbackup_result'], self.dconf['task_id'])
        cnt = self.BF.connMySQL(sql, self.dconf['conn_dbadb'])
        if cnt[0]['cnt'] == 0:
            u_sql = ("""insert into {table} 
                            (Ftype,Ftask_id,Fdate,Fsource_host,Fsource_port,
                            Fmode,Faddress,Fpath,Fbackup_status,Fbackup_info,
                            Fcreate_time,Fmodify_time) 
                        values 
                            ('{instance}','{task_id}',curdate(),'{source_host}','{source_port}',
                            '{mode}','{address}','{path}','{backup_status}','{backup_info}',
                            now(),now());"""
                        .format(table = self.dconf['t_mysql_fullbackup_result'],
                                instance = self.dconf['f_info']['instance'],
                                task_id = self.dconf['task_id'],
                                source_host = self.dconf['f_info']['source_host'],
                                source_port = self.dconf['f_info']['source_port'],
                                mode = self.dconf['f_info']['backup_mode'],
                                address = self.dconf['local_ip'],
                                path = self.dconf['backup_path'],
                                backup_status = d['check_status'],
                                backup_info = d['memo'],
                        )
                    )
        else:
            u_sql =  ("""update {table} 
                        set 
                            Fbackup_status='{backup_status}',
                            Fsize='{size}',
                            Fmetadata=\"{metadata}\",
                            Fstart_time='{start_time}',
                            Fend_time='{end_time}',
                            Fbackup_info='{backup_info}' 
                        where Ftask_id='{task_id}';"""
                        .format(table = self.dconf['t_mysql_fullbackup_result'],
                                backup_status = d['check_status'],
                                size = d['size'],
                                metadata = d['metadata'],
                                start_time = d['metadata']['start_time'],
                                end_time = d['metadata']['end_time'],
                                backup_info = d['memo'],
                                task_id = self.dconf['task_id']
                            )
                     )
        self.BF.connMySQL(u_sql, self.BF.conn_dbadb)


    def checkBackup(self):
        """
        check backup is continue
        backup_path必须为空
        不存在活跃事务
        Returns:True:False
        """
        conn_instance = {
            'host' : self.dconf['f_info']['source_host'],
            'port' : self.dconf['f_info']['source_port'],
            'user' : self.dconf['dump_user'],
            'passwd' : self.dconf['dump_pass']
        }
        v1 = self.checkPath(self.dconf['backup_path'])
        v2 = self.checkActiveTrx(conn_setting=conn_instance)
        if not v1 or not v2:
            v = False
        else:
            v = True
        return v

    def showSlaveStatus(self, conn_setting):
        slave_status = self.BF.connMySQL("SHOW SLAVE STATUS;", conn_setting)
        if slave_status:
            Slave_IO_Running = slave_status[0]['Slave_IO_Running']
            Slave_SQL_Running = slave_status[0]['Slave_SQL_Running']
            Seconds_Behind_Master = slave_status[0]['Seconds_Behind_Master']
            Master_Host = slave_status[0]['Master_Host']
            Master_Port = slave_status[0]['Master_Port']
            Seconds_Behind_Master = slave_status[0]['Seconds_Behind_Master']
            d = {'Seconds_Behind_Master' : Seconds_Behind_Master,
                'Slave_IO_Running' : Slave_IO_Running,
                'Slave_SQL_Running' : Slave_SQL_Running,
                'Master_Host' : Master_Host,
                'Master_Port' : Master_Port,
            }
        else:
            d = False
        return d

    def resolveMydumperBackupFile(self, f_metadata=None):
        """
        Returns:metadata
            metadata = {
                    'start_time' : '1970-01-01',
                    'end_time' : '1970-01-01',
                    'master_log_file' : '',
                    'master_log_pos' : '',
                    'master_gtid' : '',
                    'master_host' : '',
                    'master_port' : '',
            }
        Mydumper metadata May be like this:
            Started dump at: 2018-12-23 20:40:42
            SHOW MASTER STATUS:
                Log: binlog.000006
                Pos: 34248173
                GTID:
            
            SHOW SLAVE STATUS:
                Host: 172.16.112.12
                Log: binlog.000007
                Pos: 35718139
                GTID:
            Finished dump at: 2018-12-23 20:40:48
        """

        f = open(f_metadata, 'r')
        i = 1
        master_line = 0
        slave_line = 0
        for line in f.readlines():
            line = str(line.replace('\n', ''))
            if line == 'SHOW MASTER STATUS:':
                master_line = i
            if line == 'SHOW SLAVE STATUS:':
                slave_line = i
            if re.match('Started dump at', line):
                start_time = re.sub('Started dump at: ','',line)
            if re.match('Finished dump at: ', line):
                end_time = re.sub('Finished dump at: ','',line)
            i = i + 1
        f.close()
        
        """
        Tips:
        即使f_metadata存在show slave status,有可能slave状态不是Yes,这种情况下master是source
        slave_status = connMySQL("show slave status;",source_host,int(source_port),repl_user,repl_pass)
        """
        conn_instance = {
            'host' : self.dconf['f_info']['source_host'],
            'port' : self.dconf['f_info']['source_port'],
            'user' : self.dconf['repl_user'],
            'passwd' : self.dconf['repl_pass']
        }
        slave_status = self.showSlaveStatus(conn_setting=conn_instance)
        
        if not slave_status: # source_host role is master
            master_host = self.dconf['f_info']['source_host']
            master_port = self.dconf['f_info']['source_port']
            log_file = linecache.getline(f_metadata, master_line+1).replace('\n', '').split('Log: ', -1)[1]
            log_pos = int(linecache.getline(f_metadata, master_line+2).replace('\n', '').split('Pos: ', -1)[1])
        else:
            if slave_status['Slave_IO_Running'] == "Yes" and slave_status['Slave_SQL_Running'] == "Yes": # source_host role is slave
                master_host = slave_status['Master_Host']
                master_port= slave_status['Master_Port']
                log_file = linecache.getline(f_metadata, slave_line+2).replace('\n', '').split('Log: ', -1)[1]
                log_pos = int(linecache.getline(f_metadata, slave_line+3).replace('\n', '').split('Pos: ', -1)[1])
            else: # source_host role is master, but slave status is error
                master_host = self.dconf['f_info']['source_host']
                master_port = self.dconf['f_info']['source_port']
                log_file = linecache.getline(f_metadata, master_line+1).replace('\n', '').split('Log: ', -1)[1]
                log_pos = int(linecache.getline(f_metadata, master_line+2).replace('\n', '').split('Pos: ', -1)[1])

        # Todo:不支持GTID
        metadata = {
            'master_host' : master_host,
            'master_port' : master_port,
            'master_log_file' : log_file,
            'master_log_pos' : log_pos,
            'master_gtid' : '',
            'start_time' : start_time,
            'end_time' : end_time,
        }
        return metadata


    def doCheck(self):
        """
        check backup is succ?
        Returns:check_info
            check_info = {
                'check_status' : '',
                'metadata' : {
                    'start_time' : '1970-01-01',
                    'end_time' : '1970-01-01',
                    'master_log_file' : '',
                    'master_log_pos' : '',
                    'master_gtid' : '',
                    'master_host' : '',
                    'master_port' : ''
                },
                'size' : '0',
                'memo' : '',
            }
        """
        check_info = {
             'check_status' : '',
             'metadata' : '',
             'size' : '0',
             'memo' : '初始化字典',
        }
        backup_mode = self.dconf['f_info']['backup_mode'].upper()
        if backup_mode == 'MYDUMPER':
            f_metadata = "%s/metadata"%(self.dconf['backup_path'])
            if os.path.isfile(f_metadata):
                check_info['metadata'] = self.resolveMydumperBackupFile(f_metadata=f_metadata)
                check_info['size'] = self.BF.runShell("du -shm %s | awk '{print $1}'"%(self.dconf['backup_path']))[1]
                check_info['check_status'] = 'Succ'
                check_info['memo'] = '备份成功'
            else: # 可能依然还在做备份
                check_info['check_status'] = 'Backing'
                check_info['memo'] = 'not find metadata'
        elif backup_mode == 'XTRABACKUP':
            pass
        elif backup_mode == 'MYSQLDUMP':
            pass
        else:
            pass
        return check_info
    

    def doBackupMydumper(self, wait=1):
        cmd = ("""{mydumper} --user='{user}'"""
                    """ --password='{password}'"""
                    """ --host='{host}' """
                    """ --port='{port}'"""
                    """ --threads='{threads}'"""
                    """ --outputdir='{outputdir}'"""
                    """ --verbose=2"""
                    """ --statement-size='{statement_size}'"""
                    """ --rows='{rows}'"""
                    """ >>{log_file} 2>&1"""
                    .format(
                        mydumper = self.dconf['mydumper'],
                        user = self.dconf['dump_user'],
                        password = self.dconf['dump_pass'],
                        host = self.dconf['f_info']['source_host'],
                        port = self.dconf['f_info']['source_port'],
                        threads = self.dconf['rconf']['dump_threads'],
                        outputdir = self.dconf['backup_path'],
                        statement_size = self.dconf['rconf']['statement_size'],
                        rows = self.dconf['rconf']['rows'],
                        log_file = '/tmp/python.log',
                    )
        )
        self.BF.printLog("[%s]开始备份:%s"%(self.dconf['task_id'],cmd), self.dconf['normal_log'])
        if wait == 0: # not wait
            cmd = "%s &"%cmd
            subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
        else:
            subprocess.call(cmd, stdout=subprocess.PIPE, shell=True)
        return True


class BaseFunction(object):

    def __init__(self, t_conf_common=None, t_conf_person=None, conn_dbadb=None):

        self.t_conf_common = t_conf_common
        self.t_conf_person = t_conf_person
        self.conn_dbadb = conn_dbadb
        
    def connMySQL(self, sql=None, d=None, is_dict=1):
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
    
    def printLog(self, content=None, normal_log=None, color='normal'):
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


    def getSockFile(self, f, d):
        f = '%s/%s'%(d, f.replace('.py', '.sock.lock'))
        return f
   
    def runApplication(self, f, times):
        """
        run method : runApplication("app.pid", 10)
        """
        appInstance = ApplicationInstance(f)
        time.sleep(times) 
        appInstance.exitApplication()
    
    
    def getKV(self, k=None, ip=None, port=None):
        w_generl = "Fstate='online' and Fkey='%s'"%(k)
        s1 = "select Fvalue from %s where %s;"%(self.t_conf_common, w_generl)
        if not port:
            port = 65536
        s2 = "select Fvalue from %s where %s and Fserver_host='%s' and Fserver_port='%s';"%(self.t_conf_person, w_generl, ip, port)
        v1 = self.connMySQL(s1, self.conn_dbadb)
        v2 = self.connMySQL(s2, self.conn_dbadb)
        v = v2 if v2 else v1
        v = v[0]['Fvalue'] if v else False
        return v


    def getKVDict(self, ip=None, port=None, real=0):
        d = {}
        sql = ("""select Fkey as k,
                    Fvalue as v
                from %s
                where Fstate='online'"""
                %(self.t_conf_common))
        if real == 1:
            sql = "%s and Freal_state='Y'"%(sql)
        kvs = self.connMySQL(sql, self.conn_dbadb)
        for kv in kvs:
            k = kv['k']
            d[k] = self.getKV(k=k, ip=ip, port=port)
            #d[key] = self.getKV(k=key, ip=ip, port=port)
        return d

    def runShell(self, c):
        status, text = commands.getstatusoutput(c)
        return status, text

    def mkdirPath(self, path):
        try:
            os.makedirs(path)
        except OSError,e:
            pass


 
class ApplicationInstance(object):
 
    def __init__(self, pid_file):
        self.pid_file = pid_file
        self.check()
        self.startApplication()
 
    def check(self):
        if not os.path.isfile(self.pid_file):
            return
        pid = 0
        try:
            file = open(self.pid_file, 'rt')
            data = file.read()
            file.close()
            pid = int(data)
        except:
            pass
 
        if 0 == pid:
            return
 
        try:
            os.kill(pid, 0)
        except:
            return
 
        print "The application is already running !"
        exit(0) 
 
    def startApplication(self):
        file = open(self.pid_file, 'wt')
        file.write(str(os.getpid()))
        file.close()
 
    def exitApplication(self):
        try:
            os.remove(self.pid_file)
        except:
            pass
 


#def archivePartitions(d):
#    where_module = ("""TABLE_NAME IS NOT NULL
#                        and PARTITION_METHOD = 'RANGE COLUMNS'
#                        and table_schema='%s' 
#                        and table_name='%s' 
#                        and PARTITION_EXPRESSION='`%s`' 
#                        and PARTITION_DESCRIPTION<'%s';"""
#                    %(d['table_schema'],d['table_name'],d['column'],d['threshold_time'])
#    )
#    sql1 = ("""select TABLE_SCHEMA,TABLE_NAME,
#                    sum(DATA_LENGTH+INDEX_LENGTH)/1024/1024 AS DATA_LENGTH,
#                    sum(TABLE_ROWS) AS TABLE_ROWS,
#                    count(*) AS TABLE_COUNT
#              from information_schema.PARTITIONS
#              where %s"""%(where_module))
#    sql2 = ("""select PARTITION_NAME from information_schema.PARTITIONS where %s"""%(where_module))
#
#    si = connMySQL(sql1, d['conn_instance'])
#    si = si[0]
#    if si['TABLE_COUNT'] == 0:
#        printLog("[%s]没有需要删除的分区"%(d['task_id']), normal_log)
#        u_sql = ("""update %s set Fcount='0',Fexec_status='Succ',Fsql="没有需要删除的分区",Fmodify_time=now() where Ftask_id='%s';"""
#                %(d['dconf']['t_mysql_archive_result'],d['task_id']))
#    else:
#        ps = connMySQL(sql2, d['conn_instance'], "0")
#        v = ""
#        for p in ps:
#            p = p[0]
#            if not v:
#                v = p
#            else:
#                v = v + "," + p
#
#        printLog("[%s]开始执行删除语句,表名:%s,预计删除分区个数:%s,行数:%s,数据量大小:%sM"
#                %(d['task_id'],
#                    d['table'],
#                    si['TABLE_COUNT'],
#                    si['TABLE_ROWS'],
#                    si['DATA_LENGTH']),
#                normal_log)
#        sql = ("""ALTER TABLE %s.%s DROP PARTITION %s;""" %(si['TABLE_SCHEMA'],si['TABLE_NAME'],v))
#        connMySQL(sql, d['conn_instance'])
#
#        u_sql = ("""update %s set Fcount='%s',Fexec_status='Succ',Fsql="%s",Fmodify_time=now() where Ftask_id='%s';"""
#                %(d['dconf']['t_mysql_archive_result'],si['TABLE_COUNT'],sql,d['task_id']))
#    connMySQL(u_sql, conn_dbadb)
#
#
#
#def getFL(d):
#
#    general_sql = ("""select {select_module} from {table_schema}.{table_name}"""
#            """ FORCE INDEX({uk_name})"""
#            """ WHERE {column}<'{threshold_time}'""".format(select_module = d['select_module'],
#                table_schema = d['table_schema'],
#                table_name = d['table_name'],
#                uk_name = d['uk_name'],
#                column = d['column'],
#                threshold_time = d['threshold_time']
#                )
#    )
#    first_sql = "%s order by %s limit 1;"%(general_sql, d['uc_name'])
#    last_sql = "%s order by %s desc limit 1;"%(general_sql, d['uc_name'])
#    f = connMySQL(first_sql, d['conn_instance'])
#    l = connMySQL(last_sql, d['conn_instance'])
#    if f and l:
#        f = f[0]['%s'%(d['uc_name'])]
#        l = l[0]['%s'%(d['uc_name'])]
#        v = (f, l)
#    else:
#        v = False
#    return v
#
#
#def deletePoint(v):
#    return str(v.replace('.',''))
#
#def returnTaskID(ip, port):
#    false_ip = deletePoint(ip)
#    timestamp = time.strftime("%H%M%S_%Y%m%d")
#    task_id = "%s_%s_%s"%(false_ip, port, timestamp)
#    time.sleep(1)
#    return task_id
#
#def splitPoint(v):
#    return v.split('.',-1)[0], v.split('.',-1)[1]
#
#
#
#
#def checkReadonly(conn_setting):
#    sql = "SHOW GLOBAL VARIABLES LIKE 'read_only';"
#    v = connMySQL("SHOW GLOBAL VARIABLES LIKE 'read_only';", conn_setting)
#    v = v[0]['Value']
#    return v
#
#
#def getUniqueKeyColumn(conn_setting=None, table_schema=None, table_name=None):
#    sql = ("""select COLUMN_NAME from information_schema.COLUMNS 
#            where table_schema='%s' and table_name='%s' and COLUMN_KEY='PRI'"""
#            %(table_schema, table_name))
#    cs1 = connMySQL(sql, conn_setting)
#    sql = ("""select COLUMN_NAME from information_schema.COLUMNS 
#            where table_schema='%s' and table_name='%s' and COLUMN_KEY='UNI'"""
#            %(table_schema, table_name))
#    cs2 = connMySQL(sql, conn_setting)
#    c = cs1[0] if cs1 else cs2[0]
#    if c:
#        if len(c) > 1: # Todo:不支持联合主键或者联合唯一键
#            v = False
#        else:
#            v = c['COLUMN_NAME']
#    else:
#        v = False
#    return v
#
#
#def getUniqueKeyName(conn_setting=None, table_schema=None, table_name=None, uc_name=None):
#    sql = ("""SELECT INDEX_NAME FROM INFORMATION_SCHEMA.STATISTICS 
#            where table_schema='%s' and table_name='%s' and COLUMN_NAME='%s';"""
#            %(table_schema, table_name, uc_name))
#    name = connMySQL(sql, conn_setting)
#    name = name[0]['INDEX_NAME']
#    return name
#
#def getColumns(conn_setting=None, table_schema=None, table_name=None):
#    sql = ("""select COLUMN_NAME from information_schema.COLUMNS 
#            where table_schema='%s' and table_name='%s'"""
#            %(table_schema, table_name))
#    cs = connMySQL(sql, conn_setting)
#    l = []
#    for c in cs:
#        c = c['COLUMN_NAME']
#        l.append(c)
#    return l
#
#def getSelectModule(columns=None):
#    s = ""
#    for column in columns:
#        if s:
#            s = s + "," + column
#            #s = "`%s`,%s"%(column, s)
#        else:
#            s = column
#            #s = "`%s`"%column
#    return s
#
#
#def checkColumnType(conn_setting=None, table_schema=None, table_name=None, column=None):
#    sql = ("""select DATA_TYPE from information_schema.COLUMNS
#            where table_schema='%s' and table_name='%s' and COLUMN_NAME='%s'; """
#            %(table_schema, table_name, column))
#    v = connMySQL(sql, conn_setting)
#    if v:
#        v = v[0]['DATA_TYPE']
#        if v == "int":
#            r = "int"
#        elif v == "datetime" or v == "date" or v == "timestamp":
#            r = "char"
#        else:
#            r = False
#    else:
#        r = False
#    return r
#
#
#def checkMain(d):
#
#    d_slave_status = showSlaveStatus(d['conn_instance'])
#    if d_slave_status:
#        if d_slave_status['Slave_IO_Running'] == "Yes" or d_slave_status['Slave_IO_Running'] == "Yes":
#            printLog("[%s]天外有天"%d['task_id'])
#            return False
#
#    if checkReadonly(d['conn_instance']).upper() != "OFF":
#        print("[%s]主库read_only是ON?"%d['task_id'])
#        return False
#
#    uc_name = getUniqueKeyColumn(conn_setting=d['conn_instance'], table_schema=d['table_schema'], 
#                        table_name=d['table_name'])
#    if not uc_name:
#        printLog("[%s]找不到唯一约束"%['task_id'], normal_log)
#        info = False
#    else:
#        ck_type = checkColumnType(conn_setting=d['conn_instance'], table_schema=d['table_schema'],
#                            table_name=d['table_name'], column=d['column'])
#        if not ck_type:
#            printLog("[%s]匹配列字段类型只能为时间类型(int|datetime|date|timestamp)"
#                        %(d['task_id']), normal_log)
#            info = False
#        else:
#            uk_name = getUniqueKeyName(conn_setting=d['conn_instance'], table_schema=d['table_schema'],
#                            table_name=d['table_name'], uc_name=uc_name)
#            columns = getColumns(conn_setting=d['conn_instance'], table_schema=d['table_schema'],
#                            table_name=d['table_name'])
#            select_module = getSelectModule(columns)
#            info = uc_name,ck_type,uk_name,columns,select_module
#    return info
#
#
#def checkTableType(conn_setting=None, table_schema=None, table_name=None):
#    sql = ("""select count(*) from information_schema.PARTITIONS
#            where table_schema='%s' and table_name='%s' and PARTITION_NAME is NOT NULL"""
#            %(table_schema,table_name))
#    is_count = connMySQL(sql, conn_setting)
#    is_count = is_count[0]['count(*)']
#    v = True if is_count > 0 else False
#    return v
#
#
#def getThresholdTime(ck_type=None, days=None):
#    d = (datetime.datetime.now() + datetime.timedelta(days=int("-%s"%int(days)))).strftime("%Y-%m-%d")
#    if ck_type == 'int':
#        try:
#            time.strptime("%s 00:00:01"%d,'%Y-%m-%d %H:%M:%S')
#            threshold_time = int(time.mktime(time.strptime("%s 00:00:01"%d,'%Y-%m-%d %H:%M:%S')))
#        except ValueError, e:
#            time.strptime(d,'%Y-%m-%d %H:%M:%S')
#            threshold_time = int(time.mktime(time.strptime(d,'%Y-%m-%d %H:%M:%S')))
#    else:
#        threshold_time = d
#    return threshold_time
#
#
#
#
#def dealData(d, f_begin=None, f_end=None, d_rc=None):
#
#    general_sql = ("""FROM {table_schema}.{table_name}"""
#            """ FORCE INDEX({uk_name})"""
#            """ WHERE {column}<'{threshold_time}'"""
#            """ AND {uc_name}>='{f_begin}'""" # 左开
#            """ AND {uc_name}<='{f_end}'""" # 又闭
#            """ ORDER BY {uc_name};""".format(
#                    table_schema = d['table_schema'],
#                    table_name = d['table_name'],
#                    uk_name = d['uk_name'],
#                    column = d['column'],
#                    threshold_time = d['threshold_time'],
#                    uc_name = d['uc_name'],
#                    f_begin = f_begin,
#                    f_end = f_end
#                )
#    )
#        
#    mysql_cmd = ("""{mysql} -u{user} -p{passwd} -h{host} -P{port} -N --default-character-set='utf8'"""
#            .format(
#                mysql = mysql,
#                user = getKV(k='backup_user'),
#                passwd = getKV(k='backup_pass'),
#                host = getKV(k='backup_host'),
#                port = getKV(k='backup_port')
#            )
#    )
#
#    if d['backup_status'].upper() == "Y": # 备份逻辑
#        backup_sql = "SELECT %s %s;"%(d['select_module'], general_sql)
#        load_sql = ("""LOAD DATA LOCAL INFILE '%s' REPLACE INTO TABLE %s CHARACTER SET UTF8 (%s)"""
#                %(d['tmp_file'], d['t_backup'], d['select_module']))
#        runShell(""" echo "%s" | %s >%s """%(backup_sql, mysql_cmd, d['tmp_file']))
#        runShell(""" echo "%s" | %s """%(load_sql, mysql_cmd))
#        runShell("rm -fv %s"%(d['tmp_file']))
#
#    if not d['bool_partition']:
#        delete_sql = ("""DELETE FROM {table_schema}.{table_name}"""
#                """ WHERE {column}<'{threshold_time}'"""
#                """ AND {uc_name}>='{f_begin}'""" # 左开
#                """ AND {uc_name}<='{f_end}'""" # 又闭
#                """ LIMIT {archive_count};""".format(
#                        table_schema = d['table_schema'],
#                        table_name = d['table_name'],
#                        column = d['column'],
#                        threshold_time = d['threshold_time'],
#                        uc_name = d['uc_name'],
#                        f_begin = f_begin,
#                        f_end = f_end,
#                        archive_count = int(d_rc['archive_count']),
#                    )
#        )
#        start_pos = showMasterStatus(d['conn_instance'])
#        v_del = runShell(""" echo "%s" | %s """%(delete_sql, mysql_cmd))
#        end_pos = showMasterStatus(d['conn_instance'])
#        exec_status = "Succ" if v_del[0] == 0 else "Fail"
#        report_sql = ("""replace into {t}"""
#                """ (Ftask_id,Fbegin_unique,Fend_unique,Fstart_pos,Fend_pos,Fexec_status,Fmodify_time)"""
#                """ values"""
#                """ ("{task_id}","{begin_unique}","{end_unique}","{start_pos}","{end_pos}","{exec_status}",now()) """
#                .format(t = d['t_taskid'],
#                    task_id = d['task_id'],
#                    begin_unique = f_begin,
#                    end_unique = f_end,
#                    start_pos = start_pos,
#                    end_pos = end_pos,
#                    exec_status = exec_status)
#        )
#        connMySQL(report_sql, conn_dbadb)
#
#
#def showMasterStatus(conn_setting=None):
#
#    sql = "SHOW MASTER STATUS;"
#    v = connMySQL(sql, conn_setting)
#    v = v[0] if v else ""
#    return v
#
#
#def checkThreadsRunning(conn_setting=None, a=None):
#    r = True
#    sql = "SHOW GLOBAL STATUS LIKE 'Threads_running';"
#    v = connMySQL(sql, conn_setting)
#    v = v[0]['Value']
#    if int(v) > a:
#        printLog("[%s:%s]当前Threads_running:%s(阈值%s)"%(conn_setting['host'],conn_setting['port'],v,a), normal_log)
#        r = False
#    else:
#        printLog("[%s:%s]当前Threads_running:%s(阈值%s)"%(conn_setting['host'],conn_setting['port'],v,a), normal_log)
#    return r
#    
#
#def getSlave(conn_setting=None, master_host=None, master_port=None):
# 
#    t_mysql_info = getKV('t_mysql_info')
#    sql = ("""select Fserver_host as slave_host,
#                    Fserver_port as slave_port 
#            from {t_mysql_info} 
#            where Fstate='online' and Frole!='Master' 
#            and Ftype in (
#                select Ftype from {t_mysql_info} 
#                where Fstate='online' 
#                    and Fserver_host='{master_host}' 
#                    and Fserver_port='{master_port}'
#                    and Frole='Master');"""
#            .format(t_mysql_info = t_mysql_info,
#                    master_host = master_host,
#                    master_port = master_port,
#            )
#    )
#    slave_hosts = connMySQL(sql, conn_setting)
#    return slave_hosts
#
#def checkSlaveDelay(conn_setting=None, a=None):
#
#    r = True
#    repl_user = getKV('repl_user')
#    repl_pass = getKV('repl_pass')
#    master_host = conn_setting['host']
#    master_port = conn_setting['port']
#    slave_hosts = getSlave(conn_setting=conn_setting, master_host=master_host, master_port=master_port)
#    for s in slave_hosts:
#        slave_host = s['slave_host']
#        slave_port = s['slave_port']
#        conn_slave = {'host' : slave_host,
#            'port' : slave_port,
#            'user' : repl_user,
#            'passwd' : repl_pass
#        }
#        slave_status = showSlaveStatus(conn_slave)
#        """
#        slave_status = {'Seconds_Behind_Master': 0L, 'Slave_IO_Running': u'Yes', 'Slave_SQL_Running': u'Yes'}
#        """
#        if slave_status['Slave_IO_Running'] == 'Yes' and slave_status['Slave_SQL_Running'] == 'Yes':
#            if int(slave_status['Seconds_Behind_Master']) > a:
#                printLog("[%s:%s]当前主从延迟:%ss(阈值%ss)"
#                        %(slave_host,slave_port,slave_status['Seconds_Behind_Master'],a),
#                        normal_log)
#                r = False
#            else:
#                printLog("[%s:%s]当前主从延迟:%ss(阈值%ss)"
#                        %(slave_host,slave_port,slave_status['Seconds_Behind_Master'],a),
#                        normal_log)
#        else:
#            printLog("[%s:%s]主从复制已断开(%s)"%(slave_host,slave_port,slave_status), normal_log)
#            r = False
#    return r
#
#
#def checkDBStatus(conn_setting=None, d_rc=None, times=1):
#
#    if times > 10800: # 我等你一天
#        return False
#
#    r1 = checkThreadsRunning(conn_setting=conn_setting, a=int(d_rc['threads_running']))
#    r2 = checkSlaveDelay(conn_setting=conn_dbadb, a=int(d_rc['repl_time']))
#    if not r1 or not r2:
#        times = times + 1
#        time.sleep(8)
#        checkDBStatus(conn_setting, d_rc=d_rc, times=times)
#    return True
#
#
#def getCurFL(d=None, f0=None, max_value=None):
#    rconf = getKVDict(realtime_keys, ip=d['ip'], port=d['port']) # 实时keys,每次读取数据库最新数据
#    general_sql = ("""from {table_schema}.{table_name}"""
#            """ FORCE INDEX({uk_name})"""
#            """ WHERE {column}<'{threshold_time}'"""
#            """ AND {uc_name}>='{f0}'""" # 左开
#            """ AND {uc_name}<'{max_value}'""" # 右闭
#            """ ORDER BY {uc_name}""".format(
#                    table_schema = d['table_schema'],
#                    table_name = d['table_name'],
#                    uk_name = d['uk_name'],
#                    column = d['column'],
#                    threshold_time = d['threshold_time'],
#                    uc_name = d['uc_name'],
#                    f0 = f0,
#                    max_value = max_value,
#                )
#    )
#        
#    f12_sql = "SELECT %s %s limit %s,2;"%(d['select_module'], general_sql, int(rconf['archive_count'])-1)
#    f12 = connMySQL(f12_sql, d['conn_instance'], 0)
#    if f12:
#        f1 = f12[0][0]
#        f2 = f12[1][0]
#        printLog("[%s]开始处理数据(%s-%s)"%(d['task_id'],f0,f1), normal_log)
#        dealData(d=d, f_begin=f0, f_end=f1, d_rc=rconf)
#        printLog("[%s]结束处理数据(%s-%s)"%(d['task_id'],f0,f1), normal_log)
#        printLog("[%s]开始检测DB状态"%(d['task_id']), normal_log)
#        if not checkDBStatus(conn_setting=d['conn_instance'], d_rc=rconf, times=1): 
#            printLog("[%s]检测不通过,执行失败,退出逻辑"%(d['task_id']), normal_log)
#            return False # 生命之再再次跳转
#        else:
#            printLog("[%s]检测通过,进入下一步逻辑"%(d['task_id']), normal_log)
#        getCurFL(d=d, f0=f2, max_value=max_value)
#        v = True
#    else: # 来日无期
#        f1_sql = "SELECT %s %s limit 1;"%(d['select_module'], general_sql)
#        f1 = connMySQL(f1_sql, d['conn_instance'], 0)
#        f1 = f1[0][0]
#        f2 = max_value # Todo:最后一条数据获取不到
#        printLog("[%s]开始处理数据(%s-%s)"%(d['task_id'],f1,f2), normal_log)
#        dealData(d=d, f_begin=f1, f_end=f2, d_rc=rconf)
#        printLog("[%s]结束处理数据(%s-%s)"%(d['task_id'],f1,f2), normal_log)
#        v = False
#    if not v:
#        return
#        
#
#def recordTable(d):
#
#    sql1 = "select count(*) as cnt from %s where Fexec_status='Fail';"%(d['t_taskid'])
#    cnt = connMySQL(sql1, conn_dbadb)
#    cnt = cnt[0]['cnt']
#    if cnt > 0:
#        exec_status = "Fail"
#    else:
#        exec_status = "Succ"
#
#    sql2 = "select count(*) as cnt from %s;"%(d['t_backup']) # slow sql
#    exec_cnt = connMySQL(sql2, conn_dbadb)
#    exec_cnt = exec_cnt[0]['cnt']
# 
#    del_sql = "DLLETE FROM %s WHERE %s<'%s'"%(d['table'],d['column'],d['threshold_time'])  
#    sql = ("""update {t_mysql_archive_result} 
#            SET Fcount='{count}',Fexec_status='{exec_status}',Fsql="{sql}",Fmodify_time=now() 
#            WHERE Ftask_id='{task_id}'"""
#            .format(t_mysql_archive_result = d['dconf']['t_mysql_archive_result'],
#                    count = exec_cnt,
#                    sql = del_sql,
#                    exec_status = exec_status,
#                    task_id = d['task_id'])
#    )
#    connMySQL(sql, conn_dbadb)
#
#
#def archiveTableMain(d):
#    if 'f_uc_name' in d and 'l_uc_name' in d:
#        getCurFL(d=d, f0=d['f_uc_name'], max_value=d['l_uc_name'])       
#    if d['bool_partition']: # 处理分区表
#        archivePartitions(d)
#    else:
#        recordTable(d)
#        
#
#
#def getTableDefion(conn_setting=None, table_schema=None, table_name=None):
#
#    sql = "show create table %s.%s"%(table_schema, table_name)
#    v = connMySQL(sql, conn_setting)
#    if v:
#        v = v[0]['Create Table']
#        v = re.sub('AUTO_INCREMENT=[0-9].*','',v)  
#    else:
#        v = False
#    return v
#
#def createBackupTable(conn_setting=None, t_new=None, t_old=None, t_defition=None):
#    table_schema,table_name  = splitPoint(t_new)
#    t_defition = re.sub('`%s`'%t_old, t_new, t_defition)  
#    createTable(conn_setting=conn_setting, t=t_new, t_defition=t_defition)
#
#def createTable(conn_setting=None, t=None, t_defition=None):
#
#    table_schema,table_name  = splitPoint(t)
#    sql = ("""select count(*) from information_schema.tables 
#              where table_schema='%s' and table_name='%s'"""%(table_schema, table_name))
#    v = connMySQL(sql, conn_setting)
#    if v:
#        if v[0]['count(*)'] == 0:
#            connMySQL(t_defition, conn_setting)
#        else:
#            return False
#    else:
#        return False
#
#
#def processOneInstance(d_archive=None, sem=None):
#
#    d_archive['t_backup'] = 'mysql_archive_2018_db.t_backup_%s'%(d_archive['task_id'])
#    d_archive['t_taskid'] = 'mysql_archive_2018_db.t_taskid_%s'%(d_archive['task_id'])
#    d_archive['tmp_file'] = '%s/%s.txt'%(tmp_dir,d_archive['task_id'])
#    d_archive['conn_instance'] = {
#            'host' : d_archive['ip'],
#            'port' : int(d_archive['port']),
#            'user' : getKV(k='ddl_user', ip=d_archive['ip'], port=int(d_archive['port'])),
#            'passwd' : getKV(k='ddl_pass', ip=d_archive['ip'], port=int(d_archive['port']))
#    }
#    d_archive['table_schema'], d_archive['table_name'] = splitPoint(d_archive['table'])
#
#    printLog("[%s]begin:检测参数"%d_archive['task_id'], normal_log, 'green')
#    check_info = checkMain(d_archive)
#    if not check_info:
#        printLog("[%s]end:参数有误,退出逻辑"%d_archive['task_id'], normal_log, 'red')
#        return False # Tips:死亡跳转
#    else:
#        printLog("[%s]end:参数正常"%d_archive['task_id'], normal_log, 'green')
#
#    d_archive['uc_name'] = check_info[0]
#    d_archive['ck_type'] = check_info[1]
#    d_archive['uk_name'] = check_info[2]
#    d_archive['columns'] = check_info[3]
#    d_archive['select_module'] = check_info[4]
#    d_archive['threshold_time'] = getThresholdTime(ck_type=d_archive['ck_type'], days=d_archive['keep_days'])
#
#    result_sql = ("""replace into {t} (Ftask_id,Fdate,Fip,Fport,Ftable,Fexec_status,Fcreate_time,Fmodify_time) 
#            values 
#            ('{task_id}','{dt}','{ip}','{port}','{table}','{exec_status}',now(),now());"""
#            .format(t = d_archive['dconf']['t_mysql_archive_result'],
#                    task_id = d_archive['task_id'],
#                    dt = getToday(),
#                    ip = d_archive['conn_instance']['host'],
#                    port = d_archive['conn_instance']['port'],
#                    table = d_archive['table'],
#                    exec_status = 'Init')
#    )
#    connMySQL(result_sql, conn_dbadb)
#
#    fl = getFL(d_archive)
#    if not fl:
#        printLog("[%s]找不到需要归档的数据"%(d_archive['task_id']), normal_log)
#        #return False # Tips:再一次死亡跳转
#    else:
#        d_archive['f_uc_name'] = fl[0]
#        d_archive['l_uc_name'] = fl[1]
#        printLog("[%s]本次计划归档的数据(%s:%s-%s)"
#                    %(d_archive['task_id'], d_archive['uc_name'], 
#                    d_archive['f_uc_name'], d_archive['l_uc_name']), 
#                normal_log)
#
#    t_task_id_defition = example_sql.replace('table_schema.table_name','%s'%(d_archive['t_taskid']))
#    createTable(conn_setting=conn_dbadb, t=d_archive['t_taskid'], t_defition=t_task_id_defition)
#    if d_archive['backup_status'].upper() == 'Y':
#        table_deftion = getTableDefion(conn_setting=d_archive['conn_instance'], 
#                table_schema=d_archive['table_schema'], table_name=d_archive['table_name'])
#        printLog("[%s]创建备份库%s"%(d_archive['task_id'], d_archive['t_backup']), normal_log)
#        printLog("[%s]创建结果库%s"%(d_archive['task_id'], d_archive['t_taskid']), normal_log)
#        createBackupTable(conn_setting=conn_dbadb, t_new=d_archive['t_backup'], t_old=d_archive['table_name'], t_defition=table_deftion)
#
#    d_archive['bool_partition'] = checkTableType(conn_setting=d_archive['conn_instance'], 
#                                        table_schema=d_archive['table_schema'], table_name=d_archive['table_name'])
#
#    archiveTableMain(d_archive)
#
#    sem.release() # 释放 semaphore
#
#
#def getToday():
#    return time.strftime('%F',time.localtime())
#
#def getOnlineInfo(conn_setting, t):
#    sql = ("""select 
#                Fserver_host as `ip`,
#                Fserver_port as `port`,
#                Ftable as `table`,
#                Fcolumn as `column`,
#                Fkeep_days as `keep_days`,
#                Fbackup_status as `backup_status` 
#            from %s 
#            where Fstate='online';"""%(t)
#    )
#    d = connMySQL(sql, conn_setting)
#    return d
#
#


#def main():
#
#    printLog('===start execute archive progress.', normal_log, 'purple')
#
#    dconf = getKVDict(conf_keys)
#    archive_infos = getOnlineInfo(conn_dbadb, dconf['t_mysql_archive_info'])
#    thread_num = 3 # 同时跑的线程数
#    sem = Semaphore(thread_num) 
#    threads = []
#    for archive_info in archive_infos:
#        archive_info['dconf'] = dconf
#        archive_info['task_id'] = returnTaskID(archive_info['ip'], archive_info['port'])
#        t = threading.Thread(target=processOneInstance, args=(archive_info, sem))
#        threads.append(t)
#    length = len(threads)
#    for i in range(length):
#        sem.acquire()
#        threads[i].start()
#    for i in range(length):
#        threads[i].join()
#
#    printLog('===archive progress is Done.', normal_log, 'purple')
#
#
#if __name__ == '__main__':
#
#    main()
#
