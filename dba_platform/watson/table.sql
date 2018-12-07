CREATE TABLE machine_info_db.t_machine_info (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  Ftype varchar(64) NOT NULL DEFAULT '' COMMENT '机器角色',
  Fserver_host varchar(32) NOT NULL DEFAULT '' COMMENT '服务器IP',
  Fserver_port int(11) NOT NULL DEFAULT '0' COMMENT '服务器Port',
  Fstate varchar(16) NOT NULL DEFAULT '' COMMENT '机器状态:online|非online',
  Fcreate_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (Findex),
  UNIQUE KEY Fserver_host_port (Fserver_host,Fserver_port),
  KEY idx_Ftype (Ftype),
  KEY idx_Fmodify_time (Fmodify_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='DBA CMDB信息表|arthurhuang|2018-12-01';
