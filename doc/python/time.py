
calendar

    calendar.isleap(year)
        判断是否是闰年
    calendar.weekday(year,month,day)
        获取周几
    

time

    time.localtime()
        >>> time.localtime()
        time.struct_time(tm_year=2018, tm_mon=12, tm_mday=10, tm_hour=21, tm_min=45, tm_sec=33, tm_wday=0, tm_yday=344, tm_isdst=0)
    time.asctime()
        >>> time.asctime()
        'Mon Dec 10 21:47:41 2018'
    strftime()
        >>> time.strftime("%Y-%m-%d")
        '2018-12-10'
    strptime()
        将字符串转化为时间元组
        

datetime

    datetime.date：日期类,常用的属性有year/month/day
    datetime.time：时间类,常用的有hour/minute/second/microsecond
    datetime.datetime：日期时间类
    datetime.timedelta：时间间隔,即两个时间点之间的时间长度
    datetime.tzinfo：时区类
    
    date
        >>> import datetime
        >>> datetime.date.today()
        datetime.date(2018, 12, 10)
        >>> 
        >>> print datetime.date.today()
        2018-12-10
        >>> print datetime.date.today().year
        2018
        >>> datetime.date.today().year
        2018
        >>> datetime.date.today().month
        12
        >>> datetime.date.today().day
        10

    timedelta
        >>> datetime.time.hour
        <attribute 'hour' of 'datetime.time' objects>
        >>> now = datetime.datetime.now()
        >>> print now 
        2018-12-10 21:54:37.693950
        >>> b = now + datetime.timedelta(hours=5)
        >>> print b
        2018-12-11 02:54:37.693950
        
        >>> c = now + datetime.timedelta(weeks=2)
        >>> print c #Python 3: print(c)
        2015-05-19 09:22:43.142520
        
        >>> d = c - b
        >>> print d #Python 3: print(d)
        13 days, 19:00:00
