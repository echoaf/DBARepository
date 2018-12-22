-- MySQL dump 10.13  Distrib 5.7.19, for Linux (x86_64)
--
-- Host: localhost    Database: mysql_archive_db
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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COMMENT='MySQL归档信息表|arthur|2018-12-12';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_mysql_archive_info`
--

LOCK TABLES `t_mysql_archive_info` WRITE;
/*!40000 ALTER TABLE `t_mysql_archive_info` DISABLE KEYS */;
INSERT INTO `t_mysql_archive_info` (`Findex`, `Fserver_host`, `Fserver_port`, `Ftable`, `Fresponsible_dev`, `Fcolumn`, `Fkeep_days`, `Fbackup_status`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (1,'172.16.112.12',10000,'test_db.t_delete','Arthur','Fmodify_time',30,'Y','测试删除','online','2018-12-13 12:18:14','2018-12-21 12:10:21');
INSERT INTO `t_mysql_archive_info` (`Findex`, `Fserver_host`, `Fserver_port`, `Ftable`, `Fresponsible_dev`, `Fcolumn`, `Fkeep_days`, `Fbackup_status`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (2,'172.16.112.13',10000,'test_db.t_delete','Arthur','Fmodify_time',10,'Y','测试多线程','offline','2018-12-15 19:11:53','2018-12-21 12:10:21');
INSERT INTO `t_mysql_archive_info` (`Findex`, `Fserver_host`, `Fserver_port`, `Ftable`, `Fresponsible_dev`, `Fcolumn`, `Fkeep_days`, `Fbackup_status`, `Fmemo`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (3,'172.16.112.12',10000,'test_db.t_test_partitions','Arthur','insert_time',3,'Y','测试分区表','online','2018-12-16 14:47:23','2018-12-22 05:29:40');
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
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8 COMMENT='MySQL归档结果表|arthur|2018-12-12';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_mysql_archive_result`
--

LOCK TABLES `t_mysql_archive_result` WRITE;
/*!40000 ALTER TABLE `t_mysql_archive_result` DISABLE KEYS */;
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (1,'1721611212_10000_144042_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_delete',0,'Succ','DLLETE FROM test_db.t_delete WHERE Fmodify_time<\'2018-11-22\'','2018-12-22 14:40:44','2018-12-22 06:40:44');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (2,'1721611212_10000_144043_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_test_partitions',0,'Succ','没有需要删除的分区','2018-12-22 14:40:44','2018-12-22 06:40:44');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (3,'1721611212_10000_144121_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_delete',2048,'Succ','DLLETE FROM test_db.t_delete WHERE Fmodify_time<\'2018-11-22\'','2018-12-22 14:41:23','2018-12-22 06:41:24');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (4,'1721611212_10000_144122_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_test_partitions',0,'Init','','2018-12-22 14:41:23','2018-12-22 06:41:23');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (5,'1721611212_10000_144324_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_delete',0,'Init','','2018-12-22 14:43:26','2018-12-22 06:43:26');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (6,'1721611212_10000_144325_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_test_partitions',0,'Init','','2018-12-22 14:43:26','2018-12-22 06:43:26');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (7,'1721611212_10000_144653_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_delete',0,'Init','','2018-12-22 14:46:55','2018-12-22 06:46:55');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (8,'1721611212_10000_144654_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_test_partitions',0,'Init','','2018-12-22 14:46:55','2018-12-22 06:46:55');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (9,'1721611212_10000_144715_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_delete',0,'Init','','2018-12-22 14:47:17','2018-12-22 06:47:17');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (10,'1721611212_10000_144716_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_test_partitions',0,'Init','','2018-12-22 14:47:17','2018-12-22 06:47:17');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (11,'1721611212_10000_145133_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_delete',0,'Init','','2018-12-22 14:51:35','2018-12-22 06:51:35');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (12,'1721611212_10000_145134_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_test_partitions',0,'Init','','2018-12-22 14:51:35','2018-12-22 06:51:35');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (13,'1721611212_10000_145316_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_delete',2048,'Succ','DLLETE FROM test_db.t_delete WHERE Fmodify_time<\'2018-11-22\'','2018-12-22 14:53:18','2018-12-22 06:53:18');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (14,'1721611212_10000_145317_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_test_partitions',0,'Init','','2018-12-22 14:53:18','2018-12-22 06:53:18');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (15,'1721611212_10000_145427_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_delete',0,'Succ','DLLETE FROM test_db.t_delete WHERE Fmodify_time<\'2018-11-22\'','2018-12-22 14:54:29','2018-12-22 06:54:30');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (16,'1721611212_10000_145428_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_test_partitions',0,'Succ','没有需要删除的分区','2018-12-22 14:54:30','2018-12-22 06:54:30');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (17,'1721611212_10000_145441_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_delete',2048,'Succ','DLLETE FROM test_db.t_delete WHERE Fmodify_time<\'2018-11-22\'','2018-12-22 14:54:43','2018-12-22 06:54:43');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (18,'1721611212_10000_145442_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_test_partitions',0,'Succ','没有需要删除的分区','2018-12-22 14:54:43','2018-12-22 06:54:43');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (19,'1721611212_10000_145845_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_delete',0,'Succ','DLLETE FROM test_db.t_delete WHERE Fmodify_time<\'2018-11-22\'','2018-12-22 14:58:47','2018-12-22 06:58:47');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (20,'1721611212_10000_145846_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_test_partitions',0,'Succ','没有需要删除的分区','2018-12-22 14:58:47','2018-12-22 06:58:47');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (21,'1721611212_10000_150013_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_delete',0,'Succ','DLLETE FROM test_db.t_delete WHERE Fmodify_time<\'2018-11-22\'','2018-12-22 15:00:15','2018-12-22 07:00:15');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (22,'1721611212_10000_150014_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_test_partitions',0,'Succ','没有需要删除的分区','2018-12-22 15:00:15','2018-12-22 07:00:15');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (23,'1721611212_10000_150213_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_delete',0,'Succ','DLLETE FROM test_db.t_delete WHERE Fmodify_time<\'2018-11-22\'','2018-12-22 15:02:15','2018-12-22 07:02:15');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (24,'1721611212_10000_150214_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_test_partitions',0,'Succ','没有需要删除的分区','2018-12-22 15:02:15','2018-12-22 07:02:15');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (25,'1721611212_10000_150534_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_delete',0,'Succ','DLLETE FROM test_db.t_delete WHERE Fmodify_time<\'2018-11-22\'','2018-12-22 15:05:36','2018-12-22 07:05:36');
INSERT INTO `t_mysql_archive_result` (`Findex`, `Ftask_id`, `Fdate`, `Fip`, `Fport`, `Ftable`, `Fcount`, `Fexec_status`, `Fsql`, `Fcreate_time`, `Fmodify_time`) VALUES (26,'1721611212_10000_150535_20181222','2018-12-22','172.16.112.12',10000,'test_db.t_test_partitions',0,'Succ','没有需要删除的分区','2018-12-22 15:05:36','2018-12-22 07:05:36');
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

-- Dump completed on 2018-12-22 15:10:08
