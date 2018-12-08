# 生成器

定义
    # 生成器,生成器解析式
    my_generator = (x*x for x in range(4))
    # 列表解析
    my_list = [x*x for x in range(4)]
    
    >>> my_generator = (x*x for x in range(4))
    >>> my_list = [x*x for x in range(4)]
    >>> dir(my_generator)
    ['__class__', '__delattr__', '__doc__', '__format__', '__getattribute__', '__hash__', '__init__', '__iter__', '__name__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', 'close', 'gi_code', 'gi_frame', 'gi_running', 'next', 'send', 'throw']
    >>> dir(my_list)
    ['__add__', '__class__', '__contains__', '__delattr__', '__delitem__', '__delslice__', '__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__getitem__', '__getslice__', '__gt__', '__hash__', '__iadd__', '__imul__', '__init__', '__iter__', '__le__', '__len__', '__lt__', '__mul__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__reversed__', '__rmul__', '__setattr__', '__setitem__', '__setslice__', '__sizeof__', '__str__', '__subclasshook__', 'append', 'count', 'extend', 'index', 'insert', 'pop', 'remove', 'reverse', 'sort']
    
    next

yield

    生成器标志
    至此,已经明确,一个函数中,只要包含了 yield 语句,它就是生成器,也是迭代器.这种方式显然比前面写迭代器的类要简便多了,但这并不意味着迭代器就被抛弃,是用生成器还是用迭代器要根据具体的使用情景而定
    >>> def g():
    ...     yield 0
    ...     yield 1
    ...     yield 2
    ... 
    >>> g
    <function g at 0x7fc161fe41b8>
    >>> 
    >>> type(g)
    <type 'function'>
    >>> 
    >>> ge = g()
    >>> ge
    <generator object g at 0x7fc161fcae10>
    >>> 
    >>> type(ge)
    <type 'generator'>
    >>> 
    >>> for i in ge:
    ...     print i
    ... 
    0
    1
    2
