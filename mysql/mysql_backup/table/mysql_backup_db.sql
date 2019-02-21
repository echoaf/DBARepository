-- MySQL dump 10.14  Distrib 5.5.60-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: mysql_backup_db
-- ------------------------------------------------------
-- Server version	5.7.19-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `t_mysql_backup_info`
--

DROP TABLE IF EXISTS `t_mysql_backup_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `t_mysql_backup_info` (
  `Findex` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Ftype` varchar(64) NOT NULL DEFAULT '' COMMENT '集群名',
  `Faddress` varchar(32) NOT NULL DEFAULT '' COMMENT '备份地址',
  `Fsource_host` varchar(64) NOT NULL DEFAULT '' COMMENT '数据源',
  `Fsource_port` int(11) NOT NULL DEFAULT '0' COMMENT '数据源',
  `Fxtrabackup_state` varchar(16) NOT NULL DEFAULT '' COMMENT '全备开关控制',
  `Fxtrabackup_weekday` int(11) NOT NULL DEFAULT '8' COMMENT '备份日期,按照一周来算(0,1,2,3,4,5,6,9):0代表周日,依次类推;9代表每天都备份',
  `Fxtrabackup_start_time` time NOT NULL DEFAULT '00:00:01' COMMENT '当天尝试备份开始时间点',
  `Fxtrabackup_end_time` time NOT NULL DEFAULT '08:00:00' COMMENT '当天尝试备份结束时间点(已经在备份的并不会终止)',
  `Fxtrabackup_clear_rule` varchar(64) NOT NULL DEFAULT '0-7-365-3650' COMMENT '清理规则:0-7保留一份最新的,7-365保留一份最新的,365-3650保留一份最老的',
  `Fmydumper_state` varchar(16) NOT NULL DEFAULT '' COMMENT '全备开关控制',
  `Fmydumper_weekday` int(11) NOT NULL DEFAULT '8' COMMENT '备份日期,按照一周来算(0,1,2,3,4,5,6,9):0代表周日,依次类推;9代表每天都备份',
  `Fmydumper_start_time` time NOT NULL DEFAULT '00:00:01' COMMENT '当天尝试备份开始时间点',
  `Fmydumper_end_time` time NOT NULL DEFAULT '08:00:00' COMMENT '当天尝试备份结束时间点(已经在备份的并不会终止)',
  `Fmydumper_clear_rule` varchar(64) NOT NULL DEFAULT '0-7-365-3650' COMMENT '清理规则:0-7保留一份最新的,7-365保留一份最新的,365-3650保留一份最老的',
  `Fmysqldump_state` varchar(16) NOT NULL DEFAULT '' COMMENT '全备开关控制',
  `Fmysqldump_weekday` int(11) NOT NULL DEFAULT '8' COMMENT '备份日期,按照一周来算(0,1,2,3,4,5,6,9):0代表周日,依次类推;9代表每天都备份',
  `Fmysqldump_start_time` time NOT NULL DEFAULT '00:00:01' COMMENT '当天尝试备份开始时间点',
  `Fmysqldump_end_time` time NOT NULL DEFAULT '08:00:00' COMMENT '当天尝试备份结束时间点(已经在备份的并不会终止)',
  `Fmysqldump_clear_rule` varchar(64) NOT NULL DEFAULT '0-7-365-3650' COMMENT '清理规则:0-7保留一份最新的,7-365保留一份最新的,365-3650保留一份最老的',
  `Fbinary_name` varchar(128) NOT NULL DEFAULT '' COMMENT '可配置化first binary log',
  `Fmemo` varchar(1024) NOT NULL DEFAULT '' COMMENT '中文注释',
  `Fstate` varchar(16) NOT NULL DEFAULT '' COMMENT '该行状态是否有效(online|非online)',
  `Fcreate_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  `Fmodify_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`Findex`),
  UNIQUE KEY `uniq_Ftype` (`Ftype`),
  KEY `idx_Fmodify_time` (`Fmodify_time`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COMMENT='MySQL全量备份信息表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_mysql_backup_info`
--

LOCK TABLES `t_mysql_backup_info` WRITE;
/*!40000 ALTER TABLE `t_mysql_backup_info` DISABLE KEYS */;
INSERT INTO `t_mysql_backup_info` VALUES (1,'DBADB','172.16.112.12','172.16.112.13',10000,'online',9,'00:00:00','23:59:59','0-7-365-3650','online',9,'00:00:00','23:59:59','0-7-365-3650','online',9,'00:00:00','23:59:59','0-7-365-3650','empty','','online','2019-01-21 20:40:52','2019-02-14 06:05:06');
/*!40000 ALTER TABLE `t_mysql_backup_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_mysql_backup_result`
--

DROP TABLE IF EXISTS `t_mysql_backup_result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `t_mysql_backup_result` (
  `Findex` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Ftype` varchar(128) NOT NULL DEFAULT '' COMMENT '集群名',
  `Fmode` varchar(32) NOT NULL DEFAULT '' COMMENT '备份模式',
  `Ftask_id` varchar(128) NOT NULL DEFAULT '' COMMENT '本周或者当天的备份任务ID',
  `Fdate` date NOT NULL DEFAULT '1970-01-01' COMMENT '备份日期',
  `Fsource_host` varchar(64) NOT NULL DEFAULT '' COMMENT '备份数据源',
  `Fsource_port` int(11) NOT NULL DEFAULT '0' COMMENT '备份数据源',
  `Faddress` varchar(32) NOT NULL DEFAULT '' COMMENT '备份地址',
  `Fpath` varchar(256) NOT NULL DEFAULT '' COMMENT '备份路径',
  `Fsize` int(11) NOT NULL DEFAULT '0' COMMENT '数据集大小(M)',
  `Fmetadata` varchar(2048) NOT NULL DEFAULT '' COMMENT '备份位点信息',
  `Fstart_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '备份开始时间',
  `Fend_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '备份结束时间',
  `Fbackup_status` varchar(32) NOT NULL DEFAULT '' COMMENT '备份状态(Backing|Succ|Fail)',
  `Fclear_status` varchar(16) NOT NULL DEFAULT 'todo' COMMENT 'not:永不清理,todo:待清理,done:已清理',
  `Fremote_address` varchar(32) NOT NULL DEFAULT '' COMMENT '远程备份地址',
  `Fremote_path` varchar(256) NOT NULL DEFAULT '' COMMENT '远程备份路径',
  `Fremote_backup_status` varchar(32) NOT NULL DEFAULT 'todo' COMMENT '远程备份状态(not:不需要上传,todo:待上传,done:上传成功)',
  `Fcheck_status` varchar(32) NOT NULL DEFAULT 'todo' COMMENT '校验恢复状态(todo:待验证恢复,done:恢复验证成功,not:恢复验证失败)',
  `Fbackup_info` varchar(2048) NOT NULL DEFAULT '' COMMENT '日志记录',
  `Fcreate_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  `Fmodify_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`Findex`),
  UNIQUE KEY `uniq_Fpath` (`Fpath`),
  UNIQUE KEY `uniq_Ftask_id` (`Ftask_id`),
  KEY `idx_Ftype` (`Ftype`),
  KEY `idx_Fmodify_time` (`Fmodify_time`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8 COMMENT='MySQL全量备份结果表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_mysql_backup_result`
--

LOCK TABLES `t_mysql_backup_result` WRITE;
/*!40000 ALTER TABLE `t_mysql_backup_result` DISABLE KEYS */;
INSERT INTO `t_mysql_backup_result` VALUES (1,'DBADB','xtrabackup','DBADB-20190214-XTRABACKUP','2019-02-14','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190214-XTRABACKUP',41,'{\'master_log_file\': \'binlog.000013\', \'start_time\': \'2019-02-14 09:59:01\', \'master_host\': u\'172.16.112.13\', \'master_gtid\': \'\', \'end_time\': \'2019-02-14 09:59:14\', \'master_port\': 10000L, \'master_log_pos\': \'24833953\'}','2019-02-14 09:59:01','2019-02-14 09:59:14','Succ','todo','','','todo','todo','备份成功','2019-02-14 09:57:25','2019-02-14 02:42:59'),(2,'DBADB','mydumper','DBADB-20190214-MYDUMPER','2019-02-14','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190214-MYDUMPER',18,'{\'master_log_file\': \'binlog.000013\', \'start_time\': \'2019-02-14 10:49:06\', \'master_host\': u\'172.16.112.12\', \'master_gtid\': \'\', \'end_time\': \'2019-02-14 10:49:10\', \'master_port\': 10000L, \'master_log_pos\': 26853943}','2019-02-14 10:49:06','2019-02-14 10:49:10','Succ','todo','','','todo','todo','备份成功','2019-02-14 10:49:06','2019-02-14 02:49:12'),(7,'DBADB','mysqldump','DBADB-20190214-MYSQLDUMP','2019-02-14','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190214-MYSQLDUMP',0,'{\'master_log_file\': \'\', \'start_time\': \'1970-01-01\', \'master_host\': \'\', \'master_gtid\': \'\', \'end_time\': \'1970-01-01\', \'master_port\': \'\', \'master_log_pos\': \'\'}','1970-01-01 00:00:00','1970-01-01 00:00:00','Succ','todo','','','todo','todo','备份成功(使用mysqldump备份方式都为备份成功状态)','2019-02-14 14:48:42','2019-02-14 06:53:04'),(8,'DBADB','xtrabackup','DBADB-20190215-XTRABACKUP','2019-02-15','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190215-XTRABACKUP',41,'{\'master_log_file\': \'binlog.000013\', \'start_time\': \'2019-02-15 10:02:58\', \'master_host\': u\'172.16.112.13\', \'master_gtid\': \'\', \'end_time\': \'2019-02-15 10:03:18\', \'master_port\': 10000L, \'master_log_pos\': \'50057090\'}','2019-02-15 10:02:58','2019-02-15 10:03:18','Succ','done','','','todo','todo','备份成功','2019-02-15 09:59:49','2019-02-20 06:55:04'),(9,'DBADB','mydumper','DBADB-20190215-MYDUMPER','2019-02-15','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190215-MYDUMPER',18,'{\'master_log_file\': \'binlog.000013\', \'start_time\': \'2019-02-15 09:59:52\', \'master_host\': u\'172.16.112.12\', \'master_gtid\': \'\', \'end_time\': \'2019-02-15 10:00:04\', \'master_port\': 10000L, \'master_log_pos\': 52219394}','2019-02-15 09:59:52','2019-02-15 10:00:04','Succ','done','','','todo','todo','备份成功','2019-02-15 09:59:49','2019-02-19 06:20:00'),(10,'DBADB','mysqldump','DBADB-20190215-MYSQLDUMP','2019-02-15','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190215-MYSQLDUMP',0,'{\'master_log_file\': \'\', \'start_time\': \'1970-01-01\', \'master_host\': \'\', \'master_gtid\': \'\', \'end_time\': \'1970-01-01\', \'master_port\': \'\', \'master_log_pos\': \'\'}','1970-01-01 00:00:00','1970-01-01 00:00:00','Succ','done','','','todo','todo','备份成功','2019-02-15 09:59:49','2019-02-19 06:20:00'),(11,'DBADB','xtrabackup','DBADB-20190218-XTRABACKUP','2019-02-18','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190218-XTRABACKUP',0,'{\'master_log_file\': \'\', \'start_time\': \'1970-01-01 00:00:00\', \'master_host\': u\'172.16.112.13\', \'master_gtid\': \'\', \'end_time\': \'1970-01-01 00:00:00\', \'master_port\': 10000L, \'master_log_pos\': 0}','1970-01-01 00:00:00','1970-01-01 00:00:00','Fail','done','','','todo','todo','备份失败,解析xtrabackup_info失败','2019-02-18 09:20:32','2019-02-19 06:20:00'),(12,'DBADB','mydumper','DBADB-20190218-MYDUMPER','2019-02-18','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190218-MYDUMPER',18,'{\'master_log_file\': \'binlog.000013\', \'start_time\': \'2019-02-18 09:20:32\', \'master_host\': u\'172.16.112.12\', \'master_gtid\': \'\', \'end_time\': \'2019-02-18 09:20:42\', \'master_port\': 10000L, \'master_log_pos\': 130310935}','2019-02-18 09:20:32','2019-02-18 09:20:42','Succ','done','','','todo','todo','备份成功','2019-02-18 09:20:32','2019-02-20 06:55:05'),(13,'DBADB','mysqldump','DBADB-20190218-MYSQLDUMP','2019-02-18','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190218-MYSQLDUMP',0,'{\'master_log_file\': \'\', \'start_time\': \'1970-01-01\', \'master_host\': \'\', \'master_gtid\': \'\', \'end_time\': \'1970-01-01\', \'master_port\': \'\', \'master_log_pos\': \'\'}','1970-01-01 00:00:00','1970-01-01 00:00:00','Succ','done','','','todo','todo','备份成功','2019-02-18 09:20:32','2019-02-20 06:55:05'),(14,'DBADB','xtrabackup','DBADB-20190219-XTRABACKUP','2019-02-19','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190219-XTRABACKUP',41,'{\'master_log_file\': \'binlog.000015\', \'start_time\': \'2019-02-19 16:44:09\', \'master_host\': u\'172.16.112.13\', \'master_gtid\': \'\', \'end_time\': \'2019-02-19 16:44:23\', \'master_port\': 10000L, \'master_log_pos\': \'3115181\'}','2019-02-19 16:44:09','2019-02-19 16:44:23','Succ','done','','','todo','todo','备份成功','2019-02-19 13:41:27','2019-02-21 03:14:19'),(15,'DBADB','mydumper','DBADB-20190219-MYDUMPER','2019-02-19','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190219-MYDUMPER',18,'{\'master_log_file\': \'binlog.000015\', \'start_time\': \'2019-02-19 13:41:29\', \'master_host\': u\'172.16.112.12\', \'master_gtid\': \'\', \'end_time\': \'2019-02-19 13:41:40\', \'master_port\': 10000L, \'master_log_pos\': 38037}','2019-02-19 13:41:29','2019-02-19 13:41:40','Succ','done','','','todo','todo','备份成功','2019-02-19 13:41:27','2019-02-21 03:14:20'),(16,'DBADB','mysqldump','DBADB-20190219-MYSQLDUMP','2019-02-19','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190219-MYSQLDUMP',0,'{\'master_log_file\': \'\', \'start_time\': \'1970-01-01\', \'master_host\': \'\', \'master_gtid\': \'\', \'end_time\': \'1970-01-01\', \'master_port\': \'\', \'master_log_pos\': \'\'}','1970-01-01 00:00:00','1970-01-01 00:00:00','Succ','done','','','todo','todo','备份成功','2019-02-19 13:41:27','2019-02-21 03:14:20'),(17,'DBADB','xtrabackup','DBADB-20190220-XTRABACKUP','2019-02-20','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190220-XTRABACKUP',41,'{\'master_log_file\': \'binlog.000015\', \'start_time\': \'2019-02-20 15:30:06\', \'master_host\': u\'172.16.112.13\', \'master_gtid\': \'\', \'end_time\': \'2019-02-20 15:30:20\', \'master_port\': 10000L, \'master_log_pos\': \'26981448\'}','2019-02-20 15:30:06','2019-02-20 15:30:20','Succ','todo','','','todo','todo','备份成功','2019-02-20 14:55:06','2019-02-20 07:30:55'),(18,'DBADB','mydumper','DBADB-20190220-MYDUMPER','2019-02-20','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190220-MYDUMPER',18,'{\'master_log_file\': \'binlog.000016\', \'start_time\': \'2019-02-20 15:30:55\', \'master_host\': u\'172.16.112.12\', \'master_gtid\': \'\', \'end_time\': \'2019-02-20 15:30:58\', \'master_port\': 10000L, \'master_log_pos\': 28200936}','2019-02-20 15:30:55','2019-02-20 15:30:58','Succ','todo','','','todo','todo','备份成功','2019-02-20 14:55:06','2019-02-20 09:40:00'),(19,'DBADB','mysqldump','DBADB-20190220-MYSQLDUMP','2019-02-20','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190220-MYSQLDUMP',0,'{\'master_log_file\': \'\', \'start_time\': \'1970-01-01\', \'master_host\': \'\', \'master_gtid\': \'\', \'end_time\': \'1970-01-01\', \'master_port\': \'\', \'master_log_pos\': \'\'}','1970-01-01 00:00:00','1970-01-01 00:00:00','Succ','todo','','','todo','todo','备份成功','2019-02-20 14:55:06','2019-02-20 06:55:34'),(20,'DBADB','xtrabackup','DBADB-20190221-XTRABACKUP','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190221-XTRABACKUP',41,'{\'master_log_file\': \'binlog.000015\', \'start_time\': \'2019-02-21 11:14:22\', \'master_host\': u\'172.16.112.13\', \'master_gtid\': \'\', \'end_time\': \'2019-02-21 11:15:13\', \'master_port\': 10000L, \'master_log_pos\': \'47682703\'}','2019-02-21 11:14:22','2019-02-21 11:15:13','Succ','todo','','','todo','todo','备份成功','2019-02-21 11:14:21','2019-02-21 03:21:18'),(21,'DBADB','mydumper','DBADB-20190221-MYDUMPER','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190221-MYDUMPER',18,'{\'master_log_file\': \'binlog.000016\', \'start_time\': \'2019-02-21 11:14:22\', \'master_host\': u\'172.16.112.12\', \'master_gtid\': \'\', \'end_time\': \'2019-02-21 11:14:57\', \'master_port\': 10000L, \'master_log_pos\': 49794118}','2019-02-21 11:14:22','2019-02-21 11:14:57','Succ','todo','','','todo','todo','备份成功','2019-02-21 11:14:21','2019-02-21 03:21:18'),(22,'DBADB','mysqldump','DBADB-20190221-MYSQLDUMP','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/FULLBACKUP/DBADB-20190221-MYSQLDUMP',0,'{\'master_log_file\': \'\', \'start_time\': \'1970-01-01\', \'master_host\': \'\', \'master_gtid\': \'\', \'end_time\': \'1970-01-01\', \'master_port\': \'\', \'master_log_pos\': \'\'}','1970-01-01 00:00:00','1970-01-01 00:00:00','Succ','todo','','','todo','todo','备份成功','2019-02-21 11:14:21','2019-02-21 03:14:56');
/*!40000 ALTER TABLE `t_mysql_backup_result` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_mysql_binarylog_result`
--

DROP TABLE IF EXISTS `t_mysql_binarylog_result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `t_mysql_binarylog_result` (
  `Findex` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Ftype` varchar(128) NOT NULL DEFAULT '' COMMENT '实例类型',
  `Fname` varchar(32) NOT NULL DEFAULT '' COMMENT '二进制',
  `Fdate` date NOT NULL DEFAULT '1970-01-01' COMMENT '备份日期',
  `Fsource_host` varchar(64) NOT NULL DEFAULT '' COMMENT '数据源',
  `Fsource_port` int(11) NOT NULL DEFAULT '0' COMMENT '数据源',
  `Faddress` varchar(32) NOT NULL DEFAULT '' COMMENT '备份地址',
  `Fpath` varchar(256) NOT NULL DEFAULT '' COMMENT '备份路径',
  `Fsize` int(11) NOT NULL DEFAULT '0' COMMENT '数据集大小',
  `Fstart_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '二进制日志第一个位点开始执行时间',
  `Fbackup_status` varchar(32) NOT NULL DEFAULT '' COMMENT '备份状态(Reported|Succ|Fail|Deleted|Failagain)',
  `Fbackup_info` varchar(2048) NOT NULL DEFAULT '' COMMENT '备份日志信息',
  `Fcreate_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  `Fmodify_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`Findex`),
  UNIQUE KEY `uniq_Fsource_hp_name` (`Fsource_host`,`Fsource_port`,`Fname`),
  KEY `idx_Fdate` (`Fdate`),
  KEY `idx_Fmodify_time` (`Fmodify_time`),
  KEY `Ftype_backup_status` (`Ftype`,`Fbackup_status`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8 COMMENT='MySQL增量备份结果表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_mysql_binarylog_result`
--

LOCK TABLES `t_mysql_binarylog_result` WRITE;
/*!40000 ALTER TABLE `t_mysql_binarylog_result` DISABLE KEYS */;
INSERT INTO `t_mysql_binarylog_result` VALUES (1,'DBADB','binlog.000001','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/BINARYBACKUP/DBADB/172.16.112.13_10000/REPORTED/binlog.000001',177,'2019-02-21 00:00:00','Succ','备份成功','2019-02-14 11:36:23','2019-02-21 08:52:17'),(2,'DBADB','binlog.000002','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/BINARYBACKUP/DBADB/172.16.112.13_10000/REPORTED/binlog.000002',139401935,'2019-02-21 00:00:00','Succ','备份成功','2019-02-14 11:36:23','2019-02-21 08:52:24'),(3,'DBADB','binlog.000003','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/BINARYBACKUP/DBADB/172.16.112.13_10000/REPORTED/binlog.000003',1076450222,'2019-02-21 00:00:00','Succ','备份成功','2019-02-14 11:36:23','2019-02-21 08:52:26'),(4,'DBADB','binlog.000004','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/BINARYBACKUP/DBADB/172.16.112.13_10000/REPORTED/binlog.000004',1077412628,'2019-02-21 00:00:00','Succ','备份成功','2019-02-14 11:36:23','2019-02-21 08:52:31'),(5,'DBADB','binlog.000005','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/BINARYBACKUP/DBADB/172.16.112.13_10000/REPORTED/binlog.000005',242385252,'2019-02-21 00:00:00','Succ','备份成功','2019-02-14 11:36:23','2019-02-21 08:52:31'),(6,'DBADB','binlog.000006','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/BINARYBACKUP/DBADB/172.16.112.13_10000/REPORTED/binlog.000006',133708467,'2019-02-21 00:00:00','Succ','备份成功','2019-02-14 11:36:23','2019-02-21 08:52:31'),(7,'DBADB','binlog.000007','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/BINARYBACKUP/DBADB/172.16.112.13_10000/REPORTED/binlog.000007',748903,'2019-02-21 00:00:00','Succ','备份成功','2019-02-14 11:36:23','2019-02-21 08:52:31'),(8,'DBADB','binlog.000008','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/BINARYBACKUP/DBADB/172.16.112.13_10000/REPORTED/binlog.000008',5145,'2019-02-21 00:00:00','Succ','备份成功','2019-02-14 11:36:23','2019-02-21 08:52:31'),(9,'DBADB','binlog.000009','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/BINARYBACKUP/DBADB/172.16.112.13_10000/REPORTED/binlog.000009',269030114,'2019-02-21 00:00:00','Succ','备份成功','2019-02-14 11:36:23','2019-02-21 08:52:31'),(10,'DBADB','binlog.000010','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/BINARYBACKUP/DBADB/172.16.112.13_10000/REPORTED/binlog.000010',177,'2019-02-21 00:00:00','Succ','备份成功','2019-02-14 11:36:23','2019-02-21 08:52:31'),(11,'DBADB','binlog.000011','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/BINARYBACKUP/DBADB/172.16.112.13_10000/REPORTED/binlog.000011',6733,'2019-02-21 00:00:00','Succ','备份成功','2019-02-14 11:36:23','2019-02-21 08:52:31'),(12,'DBADB','binlog.000012','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/BINARYBACKUP/DBADB/172.16.112.13_10000/REPORTED/binlog.000012',3567,'2019-02-21 00:00:00','Succ','备份成功','2019-02-14 11:36:23','2019-02-21 08:52:31'),(13,'DBADB','binlog.000013','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/BINARYBACKUP/DBADB/172.16.112.13_10000/REPORTED/binlog.000013',129207249,'2019-02-21 00:00:00','Succ','备份成功','2019-02-19 13:43:59','2019-02-21 08:52:32'),(14,'DBADB','binlog.000014','2019-02-21','172.16.112.13',10000,'172.16.112.12','/data/MySQL_BACKUP/BINARYBACKUP/DBADB/172.16.112.13_10000/REPORTED/binlog.000014',134267,'2019-02-21 00:00:00','Succ','备份成功','2019-02-19 13:46:43','2019-02-21 08:52:52');
/*!40000 ALTER TABLE `t_mysql_binarylog_result` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-02-21 16:55:28
