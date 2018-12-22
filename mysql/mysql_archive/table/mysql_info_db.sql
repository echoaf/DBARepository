-- MySQL dump 10.13  Distrib 5.7.19, for Linux (x86_64)
--
-- Host: localhost    Database: mysql_info_db
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
-- Table structure for table `t_mysql_info`
--

DROP TABLE IF EXISTS `t_mysql_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `t_mysql_info` (
  `Findex` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Ftype` varchar(64) NOT NULL DEFAULT '' COMMENT '实例类型',
  `Fserver_host` varchar(32) NOT NULL DEFAULT '' COMMENT 'IP',
  `Fserver_port` int(11) NOT NULL DEFAULT '0' COMMENT '端口',
  `Frole` varchar(64) NOT NULL DEFAULT '' COMMENT '实例角色(Master|Slave|Masterbackup)',
  `Fmaster_status` int(11) NOT NULL DEFAULT '0' COMMENT '是否是主库:1:是,0:不是',
  `Fstate` varchar(16) NOT NULL DEFAULT '' COMMENT '机器状态:online|非online',
  `Fcreate_time` datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  `Fmodify_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`Findex`),
  UNIQUE KEY `Fhost_port` (`Fserver_host`,`Fserver_port`),
  KEY `idx_Fmodify_time` (`Fmodify_time`),
  KEY `idx_Ftype` (`Ftype`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COMMENT='MySQL信息表|arthur|2018-10-16';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `t_mysql_info`
--

LOCK TABLES `t_mysql_info` WRITE;
/*!40000 ALTER TABLE `t_mysql_info` DISABLE KEYS */;
INSERT INTO `t_mysql_info` (`Findex`, `Ftype`, `Fserver_host`, `Fserver_port`, `Frole`, `Fmaster_status`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (1,'DBADB','172.16.112.12',10000,'Master',1,'online','2018-12-07 16:13:02','2018-12-07 08:13:02');
INSERT INTO `t_mysql_info` (`Findex`, `Ftype`, `Fserver_host`, `Fserver_port`, `Frole`, `Fmaster_status`, `Fstate`, `Fcreate_time`, `Fmodify_time`) VALUES (2,'DBADB','172.16.112.13',10000,'Masterbackup',0,'online','2018-12-07 16:13:11','2018-12-07 08:13:11');
/*!40000 ALTER TABLE `t_mysql_info` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-12-22 15:09:45
