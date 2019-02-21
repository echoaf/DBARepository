--CREATE DATABASE mysql_backup_db;

CREATE TABLE mysql_backup_db.t_mysql_binarylog_info (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  Ftype varchar(64) NOT NULL DEFAULT '' COMMENT '实例类型',
  Fbackup_address varchar(32) NOT NULL DEFAULT '' COMMENT '本地备份机器地址',
  Fdata_source varchar(64) NOT NULL DEFAULT '' COMMENT '备份数据源(IP:PORT),默认初始化为MasterBackup地址,可以手动修改',
  Fstate varchar(16) NOT NULL DEFAULT '' COMMENT '该行状态是否有效(online|非online)',
  Fcreate_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (Findex),
  UNIQUE KEY uniq_Ftype (Ftype),
  KEY idx_Fmodify_time (Fmodify_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='MySQL增量备份信息表';

CREATE TABLE mysql_backup_db.t_mysql_binarylog_result (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  Ftype varchar(128) NOT NULL DEFAULT '' COMMENT '实例类型',
  Fbinarylog_name varchar(32) NOT NULL DEFAULT '' COMMENT '二进制',
  Fdate_time date NOT NULL DEFAULT '1970-01-01' COMMENT '备份日期',
  Fdata_source varchar(64) NOT NULL DEFAULT '' COMMENT '备份数据来源(IP:PORT)',
  Fbackup_address varchar(32) NOT NULL DEFAULT '' COMMENT '本地备份机器地址',
  Fbackup_path varchar(256) NOT NULL DEFAULT '' COMMENT '备份路径',
  Fbackup_size int(11) NOT NULL DEFAULT '0' COMMENT '数据集大小',
  Fstart_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '二进制日志第一个位点开始执行时间',
  Fback_status varchar(32) NOT NULL DEFAULT '' COMMENT '备份状态(Reported:数据已上报,Succ:备份成功,Fail:备份失败,Deleted:缺失,拉无可拉,Failagain:单独拉取失败,需要手动处理)',
  Fbackup_info varchar(2048) NOT NULL DEFAULT '' COMMENT '备份日志信息',
  Fcreate_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (Findex),
  UNIQUE KEY uniq_Fdata_source_name (Fdata_source,Fbinarylog_name),
  KEY idx_Fdate_time (Fdate_time),
  KEY idx_Fmodify_time (Fmodify_time),
  KEY Ftype_backup_status (Ftype,Fback_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='MySQL全量备份结果表';

CREATE TABLE mysql_backup_db.t_mysql_check_info (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  Ftype varchar(128) NOT NULL DEFAULT '' COMMENT '实例类型',
  Ftask_id varchar(128) NOT NULL DEFAULT '' COMMENT '唯一task_id:当前正在做恢复的task_id',
  Fdelay_time int(11) NOT NULL DEFAULT '3600' COMMENT '延迟阈值',
  Frestore_source varchar(64) NOT NULL DEFAULT '' COMMENT '恢复数据源(IP:PORT)',
  Frestore_address varchar(32) NOT NULL DEFAULT '' COMMENT '本机地址',
  Fweekday int(11) NOT NULL DEFAULT '1' COMMENT '恢复日期,按照一周来算(0,1,2,3,4,5,6):0代表周日,依次类推;默认从周一开始最恢复验证',
  Fload_thread int(11) NOT NULL DEFAULT '8' COMMENT '逻辑恢复load threads',
  Finnodb_buff varchar(16) NOT NULL DEFAULT '512M' COMMENT '物理恢复,数据库innodb_buff',
  Finfo varchar(2048) NOT NULL DEFAULT '' COMMENT '说明',
  Fstate varchar(16) NOT NULL DEFAULT '' COMMENT '数据状态',
  Fcreate_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (Findex),
  UNIQUE KEY uniq_Ftype (Ftype),
  KEY idx_Fmodify_time (Fmodify_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='MySQL恢复校验表';

CREATE TABLE mysql_backup_db.t_mysql_check_result (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  Ftype varchar(128) NOT NULL DEFAULT '' COMMENT '实例类型',
  Ftask_id varchar(128) NOT NULL DEFAULT '' COMMENT '唯一task_id(Ftype_+%Y%m%d)',
  Frestore_address varchar(32) NOT NULL DEFAULT '' COMMENT '本机地址',
  Frestore_result varchar(32) NOT NULL DEFAULT '' COMMENT '恢复结果(Doing:正在恢复,Succ:成功,Fail:失败)|arthur|2018-11-01',
  Frestore_start_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '开始时间',
  Frestore_end_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '结束时间',
  Finfo varchar(2048) NOT NULL DEFAULT '' COMMENT '说明',
  Fcreate_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (Findex),
  UNIQUE KEY uniq_Ftask_id (Ftask_id),
  KEY idx_Fmodify_time (Fmodify_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='MySQL恢复结果表';

CREATE TABLE mysql_backup_db.t_mysql_fullbackup_info (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  Ftype varchar(64) NOT NULL DEFAULT '' COMMENT '实例类型',
  Fbackup_address varchar(32) NOT NULL DEFAULT '' COMMENT '本地备份机器地址',
  Fdata_source varchar(64) NOT NULL DEFAULT '' COMMENT '备份数据源(IP:PORT),默认初始化为MasterBackup地址,可以手动修改',
  Fbackup_mode varchar(32) NOT NULL DEFAULT '' COMMENT '备份方式(mydumper|xtrabackup|mysqldump)',
  Fbackup_weekday int(11) NOT NULL DEFAULT '8' COMMENT '备份日期,按照一周来算(0,1,2,3,4,5,6,9):0代表周日,依次类推;9代表每天都备份',
  Fstart_time time NOT NULL DEFAULT '00:00:01' COMMENT '开始备份时间点',
  Fend_time time NOT NULL DEFAULT '08:00:00' COMMENT '结束备份时间点(已经在备份的并不会终止)',
  Fnice int(11) NOT NULL DEFAULT '0' COMMENT '备份优先级(目前累计连续备份失败的次数):此值越高,说明连续失败次数越大,如果最近有一次备份成功,则刷新为0',
  Fclear_rule varchar(64) NOT NULL DEFAULT '0-7-365-3650' COMMENT '清理规则:0-7保留一份最新的,7-365保留一份最新的,365-3650保留一份最老的',
  Fmemo varchar(1024) NOT NULL DEFAULT '' COMMENT '说明',
  Fstate varchar(16) NOT NULL DEFAULT '' COMMENT '该行状态是否有效(online|非online)',
  Fcreate_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (Findex),
  UNIQUE KEY uniq_Ftype (Ftype),
  KEY idx_Fmodify_time (Fmodify_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='MySQL全量备份信息表';

CREATE TABLE mysql_backup_db.t_mysql_fullbackup_result (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  Ftype varchar(128) NOT NULL DEFAULT '' COMMENT '实例类型',
  Ftask_id varchar(128) NOT NULL DEFAULT '' COMMENT '唯一task_id(Ftype_+%Y%m%d)',
  Fdate_time date NOT NULL DEFAULT '1970-01-01' COMMENT '备份日期',
  Fdata_source varchar(64) NOT NULL DEFAULT '' COMMENT '备份数据来源(IP:PORT)',
  Fbackup_mode varchar(32) NOT NULL DEFAULT '' COMMENT '备份方式(mydumper|xtrabackup|mysqldump)',
  Fbackup_address varchar(32) NOT NULL DEFAULT '' COMMENT '本地备份机器地址',
  Fbackup_path varchar(256) NOT NULL DEFAULT '' COMMENT '备份路径',
  Fbackup_size int(11) NOT NULL DEFAULT '0' COMMENT '数据集大小(M)',
  Fbackup_metadata varchar(2048) NOT NULL DEFAULT '' COMMENT '备份位点信息(mydumper:metadata,xtrabackup:xtrabackup_info,mysqldump:CHANGE MASTER TO...)',
  Fbackup_start_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '备份开始时间',
  Fbackup_end_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '备份结束时间',
  Fback_status varchar(32) NOT NULL DEFAULT '' COMMENT '备份状态(Backing|Succ|Fail)',
  Fclear_state varchar(16) NOT NULL DEFAULT 'todo' COMMENT 'not:不能清理,todo:待清理,done:已清理',
  Fbackup_info varchar(2048) NOT NULL DEFAULT '' COMMENT '备份日志信息',
  Fcreate_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (Findex),
  UNIQUE KEY uniq_Ftask_id (Ftask_id),
  UNIQUE KEY uniq_Fbackup_path (Fbackup_path),
  KEY idx_Fmodify_time (Fmodify_time),
  KEY idx_Ftype (Ftype)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='MySQL全量备份结果表';
