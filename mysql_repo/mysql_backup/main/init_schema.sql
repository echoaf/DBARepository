CREATE TABLE t_mysql_info (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  Ftype varchar(64) NOT NULL DEFAULT '' COMMENT '实例类型',
  Fserver_host varchar(32) NOT NULL DEFAULT '' COMMENT 'IP',
  Fserver_port int(11) NOT NULL DEFAULT '0' COMMENT '端口',
  Frole varchar(64) NOT NULL DEFAULT '' COMMENT '实例角色(Master|Slave|Masterbackup)',
  Fmaster_status int(11) NOT NULL DEFAULT '0' COMMENT '是否是主库:1:是,0:不是',
  Fstate varchar(16) NOT NULL DEFAULT '' COMMENT '机器状态:online|非online',
  Fcreate_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (Findex),
  UNIQUE KEY Fhost_port (Fserver_host,Fserver_port),
  KEY idx_Fmodify_time (Fmodify_time),
  KEY idx_Ftype (Ftype)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='MySQL信息表|arthur|2018-10-16';


CREATE TABLE t_mysql_fullbackup_info (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  Ftype varchar(64) NOT NULL DEFAULT '实例类型',
  Fbackup_address varchar(32) NOT NULL DEFAULT '' COMMENT '本地备份机器地址',
  Fdata_source varchar(64) NOT NULL DEFAULT '' COMMENT '备份数据源(IP:PORT),默认初始化为MasterBackup地址,可以手动修改',
  Fbackup_mode varchar(32) NOT NULL DEFAULT '' COMMENT '备份方式(mydumper|xtrabackup|mysqldump)',
  Fbackup_weekday int(11) NOT NULL DEFAULT '8' COMMENT '备份日期,按照一周来算(0,1,2,3,4,5,6,9):0代表周日,依次类推;9代表每天都备份',
  Fnice int(11) NOT NULL DEFAULT '0' COMMENT '备份优先级(目前累计连续备份失败的次数):此值越高,说明连续失败次数越大,如果最近有一次备份成功,则刷新为0',
  Fstate varchar(16) NOT NULL DEFAULT '' COMMENT '该行状态是否有效(online|非online)',
  Fcreate_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (Findex),
  UNIQUE KEY uniq_Ftype (Ftype),
  KEY idx_Fmodify_time (Fmodify_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='MySQL全量备份信息表|arthur|2018-10-16'



CREATE TABLE t_mysql_fullbackup_result (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  Ftype varchar(128) NOT NULL DEFAULT '实例类型',
  Ftask_id varchar(128) NOT NULL DEFAULT '' COMMENT '唯一task_id(Ftype_+%Y%m%d)',
  Fdata_time date NOT NULL DEFAULT '1970-01-01' COMMENT '备份日期',
  Fdata_source varchar(64) NOT NULL DEFAULT '' COMMENT '备份数据来源(IP:PORT)',
  Fbackup_mode varchar(32) NOT NULL DEFAULT '' COMMENT '备份方式(mydumper|xtrabackup|mysqldump)',
  Fbackup_address varchar(32) NOT NULL DEFAULT '' COMMENT '本地备份机器地址',
  Fbackup_path varchar(256) NOT NULL DEFAULT '' COMMENT '备份路径',
  Fbackup_size int(11) NOT NULL COMMENT '数据集大小(M)',
  Fbackup_metadata varchar(2048) NOT NULL DEFAULT '' COMMENT '备份位点信息(mydumper:metadata,xtrabackup:xtrabackup_info,mysqldump:CHANGE MASTER TO...)',
  Fbackup_start_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00',
  Fbackup_end_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00',
  Fback_status varchar(32) NOT NULL DEFAULT '' COMMENT '备份状态(Backing|Succ|Fail)',
  Fbackup_info varchar(2048) NOT NULL DEFAULT '' COMMENT '备份日志信息',
  Fcreate_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (Findex),
  UNIQUE KEY uniq_Ftask_id (Ftask_id),
  KEY idx_Fmodify_time (Fmodify_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='MySQL全量备份结果表|arthur|2018-10-16';



