json

    JSON(JavaScript Object Notation)是一種由道格拉斯·克羅克福特構想設計、輕量級的資料交換語言,以文字為基礎,且易於讓人閱讀.儘管JSON是Javascript的一個子集,但JSON是獨立於語言的文本格式,並且採用了類似於C語言家族的一些習慣

    JSON建构于两种结构
        "名称/值"对的集合(A collection of name/value pairs).不同的语言中,它被理解为对象(object),纪录(record),结构(struct),字典(dictionary),哈希表(hashtable),有键列表(keyed list),或者关联数组 (associative array).
        值的有序列表(An ordered list of values).在大部分语言中,它被理解为数组(array).

    import json

    json.__all__
    
    json.dumps
        >>> data = [{"name":"qiwsir", "lang":("python", "english"), "age":40}]
        >>> data
        [{'lang': ('python', 'english'), 'age': 40, 'name': 'qiwsir'}]
        >>> 
        >>> import json
        >>> 
        >>> data_json = json.dumps(data)
        >>> 
        >>> data_json
        '[{"lang": ["python", "english"], "age": 40, "name": "qiwsir"}]'
        >>> type(data_json)
        <type 'str'>
        >>> type(data)
        <type 'list'>

    json.loads
        new_data = json.loads(data_json)

    适合阅读

        >>> data_j = json.dumps(data, sort_keys=True, indent=2)
        >>> 
        >>> print data_j
        [
          {
            "age": 40, 
            "lang": [
              "python", 
              "english"
            ], 
            "name": "qiwsir"
          }
        ]

    url
        http://www.cnblogs.com/coser/archive/2011/12/14/2287739.html
