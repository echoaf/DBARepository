标准库

    莫贪婪
        from pprint import * -- not
        from modulename import name1, name2, name3

    as
        import pprint as pr
        from pprint import pprint as pt

    dir
        >>> import pprint
        >>> dir(pprint)
        ['PrettyPrinter', '_StringIO', '__all__', '__builtins__', '__doc__', '__file__', '__name__', '__package__', '_commajoin', '_id', '_len', '_perfcheck', '_recursion', '_safe_repr', '_sorted', '_sys', '_type', 'isreadable', 'isrecursive', 'pformat', 'pprint', 'saferepr', 'warnings']
        >>> [ m for m in dir(pprint) if not m.startswith('_') ]
        ['PrettyPrinter', 'isreadable', 'isrecursive', 'pformat', 'pprint', 'saferepr', 'warnings']

    help
        help(pprint.PrettyPrinter)

    pprint.__all__
        >>> pprint.__all__
        ['pprint', 'pformat', 'isreadable', 'isrecursive', 'saferepr', 'PrettyPrinter']
        当我们使用 from pprint import * 的时候,就是将 __all__ 里面的方法引入

    pprint.__doc__
        [root@Backup ~]# python 
        Python 2.7.5 (default, Oct 30 2018, 23:45:53) 
        [GCC 4.8.5 20150623 (Red Hat 4.8.5-36)] on linux2
        Type "help", "copyright", "credits" or "license" for more information.
        >>> 
        >>> import test
        >>> print test.__doc__
        
        from test.py 111
        
        >>> 
        >>> 
        [root@Backup ~]# cat test.py
        #!/usr/bin/env/python
        # coding=utf8
        
        
        """
        from test.py 111
        """
        [root@Backup ~]#

    pprint.__file__ 
        >>> print pprint.__file__ 
        /usr/lib64/python2.7/pprint.pyc
        [root@Backup ~]# ls /usr/lib64/python2.7/pprint.py*
        /usr/lib64/python2.7/pprint.py  /usr/lib64/python2.7/pprint.pyc  /usr/lib64/python2.7/pprint.pyo
