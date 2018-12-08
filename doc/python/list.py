列表

定义
    List是python中的苦力,什么都可以干.

方法
    帮助文档
        help(list.sort)
    len
    in
        "python" in ["python", "bash"]
    append
        list_a.append("b")
        la = [1, 2, 3]
        lb = ['a', 'b']
        la.append(lb)
        la
            [1, 2, 3, ['a','b']]
    extend
        la = [1, 2, 3]
        lb = ['a', 'b']
        la.extend(lb)
        la
            [1, 2, 3, 'a', 'b']
        append是整建制地追加,extend是个体化扩编
    index
         list.index(x):检索到该元素在列表中第一次出现的位置,如果不存在报错
    insert
        list.insert(i,x)
        a.insert(len(a), x) is equivalent to a.append(x).
    remove
        list.remove(x) 中的参数是列表中元素,即删除某个元素,且对列表原地修改,无返回值
    pop
        list.pop([i]) 中的i是列表中元素的索引值,可选.为空则删除列表最后一个,否则删除索引为i的元素.并且将删除元素作为返回值
    reverse
    sort

