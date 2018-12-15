-- MySQL dump 10.13  Distrib 5.7.19, for Linux (x86_64)
--
-- Host: 172.16.112.12    Database: mysql_archive_db
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
-- Table structure for table `t_mysql_archive_info`
--

DROP TABLE IF EXISTS `t_mysql_archive_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `t_mysql_archive_info` (
  `Findex` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键|arthur|2018-12-12',
  `Fserver_host` varchar(32) NOT NULL DEFAULT '' COMMENT 'IP|arthur|2018-12-12',
  `Fserver_port` int(11) NOT NULL DEFAULT '0' COMMENT '端口|arthur|2018-12-12',
  `Ftable` varchar(32) NOT NULL DEFAULT '' COMMENT 'table_schema.table_name|arthur|2018-12-12',
  `Fresponsible_dev` varchar(64) NOT NULL DEFAULT 'Arthur' COMMENT '研发负责人|arthur|2018-12-12',
  `Fcolumn` varchar(64) NOT NULL DEFAULT '' COMMENT '索引列|arthur|2018-12-12',
  `Fkeep_days` int(11) NOT NULL DEFAULT '90' COMMENT '保留时间(天)|arthur|2018-12-12',
  `Fbackup_status` char(1) NOT NULL DEFAULT 'Y' COMMENT '清理前是否需要备份(Y|N)|arthur|2018-12-12',
  `Fmemo` varchar(2048) NOT NULL DEFAULT '' COMMENT '中文说明|arthur|2018-12-12',
  `Fstate` varchar(16) NOT NULL DEFAULT '' COMMENT '机器状态(online,非online)|arthur|2018-12-12',
  `Fcreate_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间|arthur|2018-12-12',
  `Fmodify_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间|arthur|2018-12-12',
  PRIMARY KEY (`Findex`),
  UNIQUE KEY `Finstance_table` (`Fserver_host`,`Fserver_port`,`Ftable`),
  KEY `idx_Fmodify_time` (`Fmodify_time`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='MySQL归档信息表|arthur|2018-12-12';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_mysql_archive_info`
--

LOCK TABLES `t_mysql_archive_info` WRITE;
/*!40000 ALTER TABLE `t_mysql_archive_info` DISABLE KEYS */;
INSERT INTO `t_mysql_archive_info` (`Findex`, `Fserver_host`, `Fserver_port`, `Ftable`, `Fresponsible_dev`, `Fcolumn`, `Fkeep_days`, `Fbackup_status`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (1,'172.16.112.12',10000,'test_db.t_delete','Arthur','Fmodify_time',30,'N','测试删除','online','2018-12-13 12:18:14','2018-12-13 04:18:14');
/*!40000 ALTER TABLE `t_mysql_archive_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `t_mysql_archive_result`
--

DROP TABLE IF EXISTS `t_mysql_archive_result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `t_mysql_archive_result` (
  `Findex` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键|arthur|2018-12-12',
  `Ftask_id` varchar(64) NOT NULL DEFAULT '' COMMENT 'task_id(ip_port_timestamp)',
  `Fdate` date NOT NULL DEFAULT '1970-01-01' COMMENT '执行时间|arthur|2018-12-12',
  `Fip` varchar(32) NOT NULL DEFAULT '' COMMENT 'IP|arthur|2018-12-12',
  `Fport` int(11) NOT NULL DEFAULT '0' COMMENT '端口|arthur|2018-12-12',
  `Ftable` varchar(32) NOT NULL DEFAULT '' COMMENT 'table_schema.table_name|arthur|2018-12-12',
  `Fcount` bigint(20) NOT NULL DEFAULT '0' COMMENT '条数目',
  `Fexec_status` varchar(12) NOT NULL DEFAULT '' COMMENT '执行状态(Succ|Fail)|arthur|2018-12-12',
  `Fsql` varchar(2048) NOT NULL DEFAULT '' COMMENT '原始SQL|arthur|2018-12-12',
  `Fcreate_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间|arthur|2018-12-12',
  `Fmodify_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间|arthur|2018-12-12',
  PRIMARY KEY (`Findex`),
  UNIQUE KEY `Ftask_id` (`Ftask_id`),
  KEY `idx_Fmodify_time` (`Fmodify_time`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8 COMMENT='MySQL归档结果表|arthur|2018-12-12';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_mysql_archive_result`
--

LOCK TABLES `t_mysql_archive_result` WRITE;
/*!40000 ALTER TABLE `t_mysql_archive_result` DISABLE KEYS */;
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (1,'1721611212_10000_174311_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:43:11','2018-12-15 09:43:11'),(2,'1721611212_10000_174324_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:43:25','2018-12-15 09:43:25'),(3,'1721611212_10000_174350_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:43:50','2018-12-15 09:43:50'),(4,'1721611212_10000_174423_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:44:24','2018-12-15 09:44:24'),(5,'1721611212_10000_174556_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:45:56','2018-12-15 09:45:56'),(6,'1721611212_10000_174635_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:46:36','2018-12-15 09:46:36'),(7,'1721611212_10000_174740_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:47:40','2018-12-15 09:47:40'),(8,'1721611212_10000_174815_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:48:16','2018-12-15 09:48:16'),(9,'1721611212_10000_174913_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:49:13','2018-12-15 09:49:13'),(10,'1721611212_10000_174923_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:49:23','2018-12-15 09:49:23'),(11,'1721611212_10000_174942_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:49:42','2018-12-15 09:49:42'),(12,'1721611212_10000_175206_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:52:06','2018-12-15 09:52:06'),(13,'1721611212_10000_175224_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:52:25','2018-12-15 09:52:25'),(14,'1721611212_10000_175258_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:52:58','2018-12-15 09:52:58'),(15,'1721611212_10000_175323_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:53:23','2018-12-15 09:53:23'),(16,'1721611212_10000_175358_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:53:58','2018-12-15 09:53:58'),(17,'1721611212_10000_175415_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Init','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:54:16','2018-12-15 09:54:16'),(18,'1721611212_10000_175525_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',20000,'Succ','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:55:25','2018-12-15 09:55:27'),(19,'1721611212_10000_175749_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',200000,'Succ','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:57:52','2018-12-15 09:58:44'),(20,'1721611212_10000_175927_20181215','2018-12-15','172.16.112.12',10000,'test_db.t_delete',200000,'Succ','delete from test_db.t_delete where Fmodify_time<\'2018-11-15\';','2018-12-15 17:59:31','2018-12-15 10:00:16');
/*!40000 ALTER TABLE `t_mysql_archive_result` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-12-15 18:04:48
