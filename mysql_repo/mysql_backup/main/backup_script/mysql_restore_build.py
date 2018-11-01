#!/usr/bin/env python
# coding=utf8

# description:MySQL数据集恢复
# arthur 
# 2018-10-17 

import sys
import os
import time,datetime
import linecache
import argparse
import subprocess

github_dir = '/data/code/github/repository/mysql_repo/mysql_backup'
common_dir = '%s/common'%github_dir
sys.path.append(common_dir)
from python_cnf import *
script_dir = '%s/main/backup_script'%github_dir
sys.path.append(script_dir)
from backup_function import *

#sys.path.append('/data/code/douyu/project/mysql_backup/common/')
#from python_cnf import *
#sys.path.append('/data/code/douyu/project/mysql_backup/script')
#from mysql_restore_main import restoreMain
reload(sys)
sys.setdefaultencoding('utf8')

 
def parseArgs():

	parser = argparse.ArgumentParser(description='MySQL Restore Data', add_help=False)
	parser.add_argument('-i','--instance',dest='instance',type=str,help='实例类型',default='')
	parser.add_argument('-d','--dest',dest='dest',type=str,help='IP:Port',default='')
	parser.add_argument('-t','--load_threads',dest='load_threads',type=int,help='default thread is 4,then load thread is 8',default=4)
	parser.add_argument('--innodb_buff',dest='innodb_buff',type=str,help='xtrabackup, innodb_buff, default is 1G',default='1G')
	parser.add_argument('--remote_backup_path',dest='remote_backup_path',type=str,help='remote_backup_path',default='')

	return parser
   

def commandLineArgs(args):
	
	need_print_help = False if args else True
	parser = parseArgs()
	args = parser.parse_args(args)
	#if args.help or need_print_help:
	if need_print_help:
		parser.print_help()
		sys.exit(1)

	return args


def restoreMydumperSlave(source_host,source_port,dest_host,dest_port,load_threads,backup_path,metadata,normal_log):

	E_VALUE = True

	if not metadata:
		E_VALUE = False
		return E_VALUE
	tmp = checkBackupAgain(source_host,source_port,dest_host,dest_port,backup_path,normal_log)
	if not tmp:
		E_VALUE = False
		return E_VALUE
	doRestoreMydumper(dest_host,dest_port,load_threads,backup_path,normal_log)
	(master_log_file,master_log_pos,master_host,master_port) = parsePosFile(metadata,source_host,source_port)
	changeMaster(master_host,master_port,master_log_file,master_log_pos,dest_host,dest_port)

	return E_VALUE


def restoreXtrabackupSlave(local_path,backup_path,
		source_host,source_port,source_ssh_port,
		dest_host,dest_port,dest_ssh_port,
		innodb_buff,normal_log):

	E_VALUE = True
	backupXtrabackup_dir = '%s/main/full_backup/backupXtrabackup'%github_dir
	if not os.path.exists(backupXtrabackup_dir):
		printLog("找不到备份脚本所在路径",normal_log)
		E_VALUE = False
		return E_VALUE
	try:
		cmd = """scp -P %s -o "StrictHostKeyChecking no" -r %s root@%s:/tmp/ """%(dest_ssh_port,backupXtrabackup_dir,dest_host)
		subprocess.call(cmd,stdout=subprocess.PIPE,shell=True) # 等待命令执行完
		cmd = """ssh -p %s -o "StrictHostKeyChecking no" root@%s "mkdir -p %s" """%(dest_ssh_port,dest_host,backup_path)
		subprocess.call(cmd,stdout=subprocess.PIPE,shell=True) # 等待命令执行完
		cmd = """scp -P %s -o "StrictHostKeyChecking no" -r %s/backup.tar root@%s:%s """%(dest_ssh_port,local_path,dest_host,backup_path)
		subprocess.call(cmd,stdout=subprocess.PIPE,shell=True) # 等待命令执行完
	except Exception,e:
		printLog("scp执行错误(%s)"%(e),normal_log)
		E_VALUE = False
		return E_VALUE
	
	doXtrabackup(source_host,source_port,source_ssh_port,
		dest_host,dest_port,dest_ssh_port,
		backup_path,innodb_buff,"NO")

	return E_VALUE



def main():

	args = commandLineArgs(sys.argv[1:])
	sql = """select Fdata_source,Fbackup_mode,Fbackup_address,Fbackup_path,Fbackup_metadata from %s
	where Fback_status='Succ' and Ftype='%s' and Fdate_time>date_sub(CURDATE(),interval 1 week) 
	order by Fdate_time desc limit 1"""%(t_mysql_fullbackup_result,args.instance)
	result = connMySQL(sql)
	if not result:
		raise ValueError("找不到最近一周成功的备份集,可以使用mysql_backup_build.py进行备库搭建")
 
	result = result[0]
	data_source = result['Fdata_source']
	backup_mode = result['Fbackup_mode']
	backup_address = result['Fbackup_address']
	backup_path = result['Fbackup_path']

	source_host = data_source.split(':',-1)[0]
	source_port = data_source.split(':',-1)[1]
	dest_host = (args.dest).split(':',-1)[0]
	dest_port = (args.dest).split(':',-1)[1]

	if result['Fbackup_mode'].upper() == 'MYDUMPER':
		if not args.load_threads:
			args.load_threads = 8
		metadata = "%s/metadata"
		tmp = restoreMydumperSlave(source_host,source_port,
            dest_host,dest_port,
            args.load_threads,backup_path,
            metadata,normal_log)
		if not tmp:
			sys.exit(64)

	elif result['Fbackup_mode'].upper() == 'XTRABACKUP':
		if not args.innodb_buff:
			args.innodb_buff = "1G"
		#restoreMain('xtrabackup',backup_path,source_host,source_port,dest_host,dest_port,args.innodb_buff,normal_log)
		# bug:写死
		source_ssh_port = '22'
		dest_ssh_port = '22'
		restoreXtrabackupSlave(backup_path,args.remote_backup_path,
			source_host,source_port,source_ssh_port,
			dest_host,dest_port,dest_ssh_port,
			args.innodb_buff,normal_log)
	else:
		raise ValueError("未知的backup_mode")


if __name__ == '__main__':

	main()



