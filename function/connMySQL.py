import MySQLdb
import MySQLdb.cursors

def connMySQL(sql=None, d=None, is_dict=1):
    """
    d = {'host': host, 'port': port, 'user': user, 'passwd': passwd}
    """
    # MySQLdb Warning升级为Error
    from warnings import filterwarnings
    filterwarnings('error', category = MySQLdb.Warning)

    try:
        if is_dict == 1:
            conn = MySQLdb.connect(host=d['host'], port=d['port'],
                    user=d['user'], passwd=d['passwd'],
                    db='information_schema', charset='utf8',
                    cursorclass=MySQLdb.cursors.DictCursor)
        else:
            conn = MySQLdb.connect(host=d['host'], port=d['port'],
                    user=d['user'], passwd=d['passwd'],
                    db='information_schema', charset='utf8')
        cur = conn.cursor()
        cur.execute(sql)
        values = cur.fetchall()
        conn.commit()
        cur.close()
        conn.close()
        return values
    except Exception,e:
        raise Exception("sql is running error:%s..."%e)

