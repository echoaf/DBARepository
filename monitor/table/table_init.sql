create database monitor_db;


create table monitor_db.t_mysql_slave_info(
Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
Fip varchar(16) not null default '' comment '',
Fport int not null default '0' comment '',
Fmaster_host varchar(16) not null default '' comment '',
Fmaster_port int not null default '0' comment '',
Fdate_time datetime not null default '1970-01-01 00:00:00' comment '上报时间',
Fdelay_time int not null default '-1' comment '延迟表延迟时间',
Fserver_id int not null default '0' comment '服务器ServerID',
Fserver_uuid varchar(38) not null default '' comment '服务器ServerUUID',
Fmaster_server_id int not null default '0' comment 'Master ServerID',
Fmaster_uuid varchar(38) not null default '' comment 'Master ServerUUID',
Fmaster_user varchar(32) not null default '' comment '',
Fmaster_log_file varchar(32) not null default '' comment 'IO线程位点',
Fread_master_log_pos int not null default '0' comment 'IO线程位点',
Frelay_master_log_file varchar(32) not null default '' comment 'SQL线程位点',
Fexec_master_log_pos int not null default '0' comment 'SQL线程位点',
Frelay_log_file varchar(32) not null default '' comment 'SQL线程正在读取的RELAY Log',
Frelay_log_pos int not null default '0' comment 'SQL线程正在读取的RELAY Log',
Frelay_log_space varchar(32) not null default '' comment '',
Fexecuted_gtid_set varchar(32) not null default '' comment '',
Fauto_position int not null default '0' comment '0',
Fchannel_name varchar(32) not null default '' comment '',
Fslave_io_running varchar(32) not null default '' comment '',
Fslave_sql_running varchar(32) not null default '' comment '',
Fseconds_behind_master varchar(32) not null default '' comment '',
Fslave_sql_running_state varchar(2048) not null default '' comment 'sql运行状态',
Freplicate_do_db varchar(32) not null default '' comment '',
Freplicate_ignore_db varchar(32) not null default '' comment '',
Freplicate_do_table varchar(32) not null default '' comment '',
Freplicate_ignore_table varchar(32) not null default '' comment '',
Freplicate_wild_do_table varchar(32) not null default '' comment '',
Freplicate_wild_ignore_table varchar(32) not null default '' comment '',
Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
PRIMARY KEY (Findex),
UNIQUE KEY Fip_port_datatime(Fip,Fport,Fdate_time),
KEY idx_Fmodify_time (Fmodify_time)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='MySQL-Slave信息表';

create table monitor_db.t_mysql_table_info(
Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
Fip varchar(16) not null default '' comment '',
Fport int not null default '0' comment '',
Fdate date not null default '1970-01-01' comment '上报时间',
Ftable_schema varchar(64) not null default '' comment '',
Ftable_name varchar(64) not null default '' comment '',
Ftable_type varchar(32) not null default '' comment '',
Fengine varchar(32) not null default '' comment '',
Fversion bigint not null default '0' comment '',
Frow_format varchar(16) not null default '' comment '',
Ftable_rows bigint not null default '0' comment '',
Fdata_length bigint not null default '0' comment '',
Findex_length bigint not null default '0' comment '',
Fdata_free bigint not null default '0' comment '',
Fauto_increment bigint not null default '0' comment '',
Fcreate_options varchar(255) not null default '' comment '',
Ftable_comment varchar(2048) not null default '' comment '',
Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
PRIMARY KEY (Findex),
UNIQUE KEY Fip_port_date_table (Fip,Fport,Fdate,Ftable_schema,Ftable_name),
KEY idx_Fmodify_time (Fmodify_time)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='MySQL-TABLE信息表|arthur|2018-11-22';


CREATE TABLE t_conf_common (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  Fkey varchar(64) NOT NULL DEFAULT '' COMMENT '配置参数',
  Fvalue varchar(1024) NOT NULL DEFAULT '' COMMENT '配置值',
  Fmemo varchar(2048) NOT NULL DEFAULT '' COMMENT '注解',
  Fstate varchar(32) NOT NULL DEFAULT '' COMMENT '该行是否有效(online|offline)',
  Fcreate_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (Findex),
  UNIQUE KEY uniq_Fkey (Fkey),
  KEY i_Fmodify_time (Fmodify_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT '配置公共表';


CREATE TABLE t_conf_person (
  Findex int(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  Fkey varchar(64) NOT NULL DEFAULT '' COMMENT '配置参数',
  Fvalue varchar(1024) NOT NULL DEFAULT '' COMMENT '配置值',
  Ftype varchar(32) NOT NULL DEFAULT 'system' COMMENT '配置类型(system|mysql|redis)',
  Fserver_host varchar(32) NOT NULL DEFAULT '' COMMENT '服务器IP',
  Fserver_port int NOT NULL DEFAULT '0' COMMENT '服务器PORT',
  Fmemo varchar(2048) NOT NULL DEFAULT '' COMMENT '注解',
  Fstate varchar(32) NOT NULL DEFAULT '' COMMENT '该行是否有效(online|offline)',
  Fcreate_time datetime NOT NULL DEFAULT '1970-01-01 00:00:00' COMMENT '创建时间',
  Fmodify_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (Findex),
  UNIQUE KEY uniq_Fkey_type_host_port (Fkey,Ftype,Fserver_host,Fserver_port),
  KEY i_Fmodify_time (Fmodify_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT '配置特性表';
