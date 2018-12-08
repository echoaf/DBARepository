字典

   操作 
        初始化
            person = {"name":"qiwsir", "site":"qiwsir.github.io", "language":"python"}
        添加元素
            person['name2'] = "qiwsir"
        key->value
            映射，就好比“物体”和“影子”的关系，“形影相吊”，两者之间是映射关系。此外，映射也是一个严格数学概念：A是非空集合，A到B的映射是指：A中每个元素都对应到B中的某个元素。
            person['name']
        len(d)
        del d[key]
        key in d
    
        """
        屠龙之技
        如果读者没有明白这句话的意思，我就只能说点通俗的了（我本来不想说通俗的，装着自己有学问）
        """
    
    copy
        Python在所执行的复制动作中，如果是基本类型的对象（专指数字和字符串），就在内存中重新建个窝；
        如果不是基本类型的，就不新建窝了，而是用标签引用原来的窝。这也好理解，如果比较简单，随便建立新窝简单；
        但是，如果对象太复杂了，就别费劲了，还是引用一下原来的省事

        浅拷贝
        深拷贝(deep copy)    

        >>> import copy
        >>> x = {'lang': ['python', 'java'], 'name': 'qiwsir'}
        >>> z = copy.deepcopy(x) # 深拷贝,互不影响
        >>> z
        {'lang': ['python', 'java'], 'name': 'qiwsir'}
        >>> id(x)
        140160171770776
        >>> id(z)
        140160171770496
        >>> 
        >>> id(x["lang"])
        140160174366304
        >>> id(z["lang"])
        140160174372408
        >>> id(x["name"])
        140160175254816
        >>> id(z["name"])
        140160175254816
        >>> 
        >>> x
        {'lang': ['python', 'java'], 'name': 'qiwsir'}
        >>> z
        {'lang': ['python', 'java'], 'name': 'qiwsir'}
        >>> 
        >>> x["lang"].remove("java") # 不影响z
        >>> 
        >>> x
        {'lang': ['python'], 'name': 'qiwsir'}
        >>> z
        {'lang': ['python', 'java'], 'name': 'qiwsir'}


    clear
        清空字典

    dict.get()
        D[k] if k in D, else d
        与dict['key']区别
        >>> d = {"lang":"python"}
        >>> newd = d.get("name","qiwsir")
        >>> newd
        'qiwsir'
        >>> d
        {'lang': 'python'}

    dict.setdefault()
        D.setdefault(k[,d]) -> D.get(k,d), also set D[k]=d if k not in D
        >>> d
        {'lang': 'python'}
        >>> 
        >>> d.setdefault("name","arthur")
        'arthur'
        >>> d
        {'lang': 'python', 'name': 'arthur'}

    items()

        >>> dd = {"name":"qiwsir", "lang":"python", "web":"www.itdiffer.com"}
        >>> 
        >>> dd_kv = dd.items()
        >>> 
        >>> dd_kv
        [('lang', 'python'), ('web', 'www.itdiffer.com'), ('name', 'qiwsir')]

大字典循环
    for k,v in d.iteritems():
    代替
    for k,v in d.items():
    iteritems:迭代器,优化内存
