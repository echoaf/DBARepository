CREATE TABLE mysql_info_db.t_mysql_archive_info (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键|arthur|2018-12-12',
  Fserver_host varchar(32) NOT NULL DEFAULT '' COMMENT 'IP|arthur|2018-12-12',
  Fserver_port int(11) NOT NULL DEFAULT '0' COMMENT '端口|arthur|2018-12-12',
  Ftable varchar(32) NOT NULL DEFAULT '' COMMENT 'table_schema.table_name|arthur|2018-12-12',
  Fresponsible_dev varchar(64) NOT NULL DEFAULT 'Arthur' COMMENT '研发负责人|arthur|2018-12-12',
  Fcolumn varchar(64) NOT NULL DEFAULT '' COMMENT '索引列|arthur|2018-12-12',
  Fkeep_days int(11) NOT NULL DEFAULT '90' COMMENT '保留时间(天)|arthur|2018-12-12',
  Fbackup_status char(1) NOT NULL DEFAULT 'Y' COMMENT '清理前是否需要备份(Y|N)|arthur|2018-12-12',
  Fmemo varchar(2048) NOT NULL DEFAULT '' COMMENT '中文说明|arthur|2018-12-12',
  Fstate varchar(16) NOT NULL DEFAULT '' COMMENT '机器状态(online,非online)|arthur|2018-12-12',
  Fcreate_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间|arthur|2018-12-12',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间|arthur|2018-12-12',
  PRIMARY KEY (Findex),
  UNIQUE KEY Finstance_table (Fserver_host,Fserver_port,Ftable),
  KEY idx_Fmodify_time (Fmodify_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='MySQL归档信息表|arthur|2018-12-12';
