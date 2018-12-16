python binlog2sql.py --flashback -h 172.16.112.12 -P 10000 -u repl_user -p redhat --start-file=binlog.000005   --start-position='93075285' --stop-position=93097595 >/root/insert.sql

