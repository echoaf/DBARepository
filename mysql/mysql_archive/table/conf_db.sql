-- MySQL dump 10.13  Distrib 5.7.19, for Linux (x86_64)
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
-- Table structure for table `t_archive_conf_common`
--

DROP TABLE IF EXISTS `t_archive_conf_common`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `t_archive_conf_common` (
  `Findex` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Fkey` varchar(64) NOT NULL DEFAULT '' COMMENT '配置参数',
  `Fvalue` varchar(1024) NOT NULL DEFAULT '' COMMENT '配置值',
  `Fmemo` varchar(2048) NOT NULL DEFAULT '' COMMENT '注解',
  `Fstate` varchar(32) NOT NULL DEFAULT '' COMMENT '该行是否有效(online|offline)',
  `Fcreate_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  `Fmodify_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`Findex`),
  UNIQUE KEY `uniq_Fkey` (`Fkey`),
  KEY `idx_Fmodify_time` (`Fmodify_time`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8 COMMENT='配置公共表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_archive_conf_common`
--

LOCK TABLES `t_archive_conf_common` WRITE;
/*!40000 ALTER TABLE `t_archive_conf_common` DISABLE KEYS */;
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (1,'dba_host','172.16.112.12','DBADB Master','online','2018-12-15 10:12:08','2018-12-15 02:12:08');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (2,'dba_port','10000','DBADB Master','online','2018-12-15 10:15:17','2018-12-15 02:15:17');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (3,'dba_user','dba_master','DBADB Master','online','2018-12-15 10:15:17','2018-12-15 02:15:17');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (4,'dba_pass','redhat','DBADB Master','online','2018-12-15 10:15:17','2018-12-15 02:15:17');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (5,'master_user','master_user','SELECT,INSERT,UPDATE,DELETE','online','2018-12-15 10:15:17','2018-12-15 02:16:22');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (6,'master_pass','redhat','SELECT,INSERT,UPDATE,DELETE','online','2018-12-15 10:15:17','2018-12-15 02:16:22');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (7,'repl_user','repl_user','SUPER, REPLICATION CLIENT','online','2018-12-15 10:15:17','2018-12-15 02:15:53');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (8,'repl_pass','redhat','SUPER, REPLICATION CLIENT','online','2018-12-15 10:15:17','2018-12-15 02:15:53');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (10,'t_mysql_info','mysql_info_db.t_mysql_info','实例信息表','online','2018-12-15 10:18:14','2018-12-15 02:18:14');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (11,'t_mysql_archive_info','mysql_archive_db.t_mysql_archive_info','归档信息表','online','2018-12-15 10:18:15','2018-12-15 02:18:15');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (12,'t_mysql_archive_result','mysql_archive_db.t_mysql_archive_result','归档结果表','online','2018-12-15 10:18:15','2018-12-15 02:18:15');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (13,'archive_count','20000','每次处理数据行数','online','2018-12-15 10:26:50','2018-12-15 02:26:50');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (14,'threads_running','1000','最大活跃连接数','online','2018-12-15 10:26:51','2018-12-15 02:26:51');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (16,'ddl_user','ddl_user','SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, SHUTDOWN, PROCESS, FILE, REFERENCES, INDEX, ALTER, SHOW DATABASES, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER, CREATE TABLESPACE','online','2018-12-17 16:10:28','2018-12-17 08:14:38');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (18,'ddl_pass','redhat','','online','2018-12-17 16:10:50','2018-12-17 08:10:50');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (19,'repl_time','3','最大延迟阈值','online','2018-12-21 14:24:26','2018-12-21 06:24:26');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (20,'backup_host','172.16.112.12','备份地址','online','2018-12-21 22:00:05','2018-12-21 14:00:05');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (21,'backup_port','10000','备份地址','online','2018-12-21 22:00:14','2018-12-21 14:00:14');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (22,'backup_user','ddl_user','备份地址','online','2018-12-21 22:00:25','2018-12-21 14:00:25');
INSERT INTO `t_archive_conf_common` (`Findex`, `Fkey`, `Fvalue`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (23,'backup_pass','redhat','备份地址','online','2018-12-21 22:00:32','2018-12-21 14:00:32');
/*!40000 ALTER TABLE `t_archive_conf_common` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_archive_conf_person`
--

DROP TABLE IF EXISTS `t_archive_conf_person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `t_archive_conf_person` (
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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COMMENT='配置特性表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_archive_conf_person`
--

LOCK TABLES `t_archive_conf_person` WRITE;
/*!40000 ALTER TABLE `t_archive_conf_person` DISABLE KEYS */;
INSERT INTO `t_archive_conf_person` (`Findex`, `Fkey`, `Fvalue`, `Fserver_host`, `Fserver_port`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (1,'threads_running','20000','172.16.112.10',65536,'test','offline','2018-12-15 11:14:45','2018-12-15 03:15:55');
INSERT INTO `t_archive_conf_person` (`Findex`, `Fkey`, `Fvalue`, `Fserver_host`, `Fserver_port`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (2,'threads_running','30000','172.16.112.10',10000,'test','online','2018-12-15 11:14:54','2018-12-15 03:14:54');
INSERT INTO `t_archive_conf_person` (`Findex`, `Fkey`, `Fvalue`, `Fserver_host`, `Fserver_port`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (3,'archive_count','1000','172.16.112.12',10000,'','online','2018-12-21 15:45:56','2018-12-21 08:18:07');
/*!40000 ALTER TABLE `t_archive_conf_person` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-12-22 15:09:57
