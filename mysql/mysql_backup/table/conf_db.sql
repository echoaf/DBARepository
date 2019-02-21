-- MySQL dump 10.14  Distrib 5.5.60-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: conf_db
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
-- Table structure for table `t_mysql_backup_conf_common`
--

DROP TABLE IF EXISTS `t_mysql_backup_conf_common`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `t_mysql_backup_conf_common` (
  `Findex` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Fkey` varchar(64) NOT NULL DEFAULT '' COMMENT '配置参数',
  `Fvalue` varchar(1024) NOT NULL DEFAULT '' COMMENT '配置值',
  `Freal_state` char(1) NOT NULL DEFAULT 'N' COMMENT '是否实时',
  `Fmemo` varchar(2048) NOT NULL DEFAULT '' COMMENT '注解',
  `Fstate` varchar(32) NOT NULL DEFAULT '' COMMENT '该行是否有效(online|offline)',
  `Fcreate_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  `Fmodify_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`Findex`),
  UNIQUE KEY `uniq_Fkey` (`Fkey`),
  KEY `idx_Fmodify_time` (`Fmodify_time`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8 COMMENT='配置公共表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_mysql_backup_conf_common`
--

LOCK TABLES `t_mysql_backup_conf_common` WRITE;
/*!40000 ALTER TABLE `t_mysql_backup_conf_common` DISABLE KEYS */;
INSERT INTO `t_mysql_backup_conf_common` VALUES (1,'t_mysql_info','mysql_info_db.t_mysql_info','N','MySQL信息表','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(2,'t_mysql_fullbackup_info','mysql_backup_db.t_mysql_fullbackup_info','N','下线key','offline','2018-12-23 11:29:13','2019-02-21 03:11:19'),(3,'t_mysql_fullbackup_result','mysql_backup_db.t_mysql_fullbackup_result','N','下线key','offline','2018-12-23 11:29:13','2019-02-21 03:11:19'),(4,'t_mysql_binarylog_info','mysql_backup_db.t_mysql_binarylog_info','N','下线key','offline','2018-12-23 11:29:13','2019-02-21 03:11:19'),(5,'t_mysql_binarylog_result','mysql_backup_db.t_mysql_binarylog_result','N','增备结果表','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(6,'t_mysql_check_info','mysql_backup_db.t_mysql_check_info','N','下线key','offline','2018-12-23 11:29:13','2019-02-21 03:11:19'),(7,'t_mysql_check_result','mysql_backup_db.t_mysql_check_result','N','下线key','offline','2018-12-23 11:29:13','2019-02-21 03:11:19'),(8,'dba_host','172.16.112.10','N','DBADB','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(9,'dba_port','10000','N','DBADB','online','2018-12-23 11:29:13','2018-12-23 10:45:33'),(10,'dba_user','dba_master','N','DBADB','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(11,'dba_pass','dba_master','N','DBADB','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(12,'admin_user','admin_user','N','surper权限,用于LOAD(SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,RELOAD,SHUTDOWN,PROCESS,FILE,REFERENCES,INDEX,ALTER,SHOWDATABASES,CREATETEMPORARYTABLES,LOCKTABLES,EXECUTE,REPLICATIONSLAVE,REPLICATIONCLIENT,CREATEVIEW,SHOWVIEW,CREATEROUTINE,ALTERROUTINE,CREATEUSER,EVENT,TRIGGER,CREATETABLESPACE)','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(13,'admin_pass','admin_user','N','surper权限,用于LOAD(SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,RELOAD,SHUTDOWN,PROCESS,FILE,REFERENCES,INDEX,ALTER,SHOWDATABASES,CREATETEMPORARYTABLES,LOCKTABLES,EXECUTE,REPLICATIONSLAVE,REPLICATIONCLIENT,CREATEVIEW,SHOWVIEW,CREATEROUTINE,ALTERROUTINE,CREATEUSER,EVENT,TRIGGER,CREATETABLESPACE)','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(14,'repl_user','repl_user','N','复制用户,用于配置SLAVE(SELECT,REPLICATIONSLAVE,REPLICATIONCLIENT)','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(15,'repl_pass','redhat','N','复制用户,用于配置SLAVE(SELECT,REPLICATIONSLAVE,REPLICATIONCLIENT)','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(16,'dump_user','dump_user','N','备份用户,用于DUMP(SELECT,RELOAD,PROCESS,REPLICATIONSLAVE,REPLICATIONCLIENT)','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(17,'dump_pass','redhat','N','备份用户,用于DUMP(SELECT,RELOAD,PROCESS,REPLICATIONSLAVE,REPLICATIONCLIENT)','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(18,'mydumper','/usr/bin/dba/mydumper','N','mydumper路径','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(19,'myloader','/usr/bin/dba/myloader','N','myloader路径','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(20,'innobackupex','/usr/bin/innobackupex','N','innobackupex路径','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(21,'ssh','/usr/bin/ssh','N','ssh路径','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(22,'backup_pdir','/data/MySQL_BACKUP','N','备份基目录','online','2018-12-23 11:29:13','2018-12-23 08:40:51'),(23,'run_times','3600','Y','脚本运行时长','online','2018-12-23 12:11:47','2018-12-23 09:12:36'),(24,'dump_threads','4','Y','mydumper备份线程数','online','2018-12-23 16:15:19','2018-12-23 09:12:36'),(25,'load_threads','6','Y','myloader导入线程数','online','2018-12-23 16:15:35','2018-12-23 09:12:36'),(26,'statement_size','1000000','Y','mydumper分块线程数','online','2018-12-23 16:22:23','2018-12-23 09:12:36'),(27,'rows','1000000','Y','mydumper分块线程数','online','2018-12-23 16:22:32','2018-12-23 09:12:36'),(28,'t_mysql_xtrabackup_info','mysql_backup_db.t_mysql_xtrabackup_info','N','下线key','offline','2019-01-10 14:16:07','2019-02-21 03:11:19'),(29,'t_mysql_mydummper_info','mysql_backup_db.t_mysql_mydummper_info','N','下线key','offline','2019-01-10 14:16:23','2019-02-21 03:11:19'),(30,'t_mysql_backup_info','mysql_backup_db.t_mysql_backup_info','N','','online','2019-01-19 10:40:04','2019-01-19 02:40:04'),(31,'t_mysql_backup_result','mysql_backup_db.t_mysql_backup_result','N','','online','2019-01-19 10:40:20','2019-01-19 02:40:20'),(32,'clear_threshold','80','Y','备份机器清理阈值','online','2019-02-14 16:26:47','2019-02-14 08:26:47'),(33,'ssh_user','douyuops','N','xtrbackup ssh用户','online','2019-02-21 13:48:02','2019-02-21 05:48:02'),(34,'ssh_port','22','N','xtrbackup ssh端口','online','2019-02-21 13:48:15','2019-02-21 05:48:15'),(35,'mysqldump','/data/DBARepository/mysql/mysql_backup/common/mysqldump','N','mysqldumper路径','online','2019-02-21 13:57:44','2019-02-21 05:57:44');
/*!40000 ALTER TABLE `t_mysql_backup_conf_common` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_mysql_backup_conf_person`
--

DROP TABLE IF EXISTS `t_mysql_backup_conf_person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `t_mysql_backup_conf_person` (
  `Findex` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Fkey` varchar(64) NOT NULL DEFAULT '' COMMENT '配置参数',
  `Fvalue` varchar(1024) NOT NULL DEFAULT '' COMMENT '配置值',
  `Fserver_host` varchar(32) NOT NULL DEFAULT '' COMMENT '服务器IP',
  `Fserver_port` int(11) NOT NULL DEFAULT '0' COMMENT '服务器PORT',
  `Fmemo` varchar(2048) NOT NULL DEFAULT '' COMMENT '注解',
  `Fstate` varchar(32) NOT NULL DEFAULT '' COMMENT '该行是否有效(online|offline)',
  `Fcreate_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  `Fmodify_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`Findex`),
  UNIQUE KEY `uniq_Fkey_host_port` (`Fkey`,`Fserver_host`,`Fserver_port`),
  KEY `idx_Fmodify_time` (`Fmodify_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='配置特性表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_mysql_backup_conf_person`
--

LOCK TABLES `t_mysql_backup_conf_person` WRITE;
/*!40000 ALTER TABLE `t_mysql_backup_conf_person` DISABLE KEYS */;
/*!40000 ALTER TABLE `t_mysql_backup_conf_person` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2019-02-21 16:55:03
