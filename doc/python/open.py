open

"""
操作文件
help(file.read)
"""

    模式
        r 以读方式打开文件,可读取文件信息.
        w 以写方式打开文件,可向文件写入信息.如文件存在,则清空该文件,再写入新内容
        a 以追加模式打开文件(即一打开文件,文件指针自动移到文件末尾),如果文件不存在则创建
        a+ 以读写方式打开文件,并把文件指针移到文件尾.

        read
            >>> f = open("/root/130.txt")
            >>> for line in f:
            ...     print line
            ... 
            learn python
            
            http://qiwsir.github.io
            
            qiwsir@gmail.com
            
            >>> f = open("/root/130.txt")
            >>> for line in f:
            ...     print line, # 去掉空格
            ... 
            learn python
            http://qiwsir.github.io
            qiwsir@gmail.com
        write
            >>> nf = open("/root/131.txt", "w")
            >>> nf.write("This is a file")
            >>> nf.close()

    使用with

        >>> with open("130.txt","a") as f:
        ...     f.write("\nThis is about 'with...as...'")
        ... 
        >>> 
        >>> 
        >>> 
        >>> with open("130.txt","r") as f:
        ...     print f.read()
        ... 
        learn python
        http://qiwsir.github.io
        qiwsir@gmail.com
        
        This is about 'with...as...'

    read, readline, readlines
        
        read：如果指定了参数size,就按照该指定长度从文件中读取内容,否则,就读取全文.被读出来的内容,全部塞到一个字符串里面.这样有好处,就是东西都到内存里面了,随时取用,比较快捷;"成也萧何败萧何",也是因为这点,如果文件内容太多了,内存会吃不消的.文档中已经提醒注意在"non-blocking"模式下的问题,关于这个问题,不是本节的重点,暂时不讨论.
        readline：那个可选参数size的含义同上.它则是以行为单位返回字符串,也就是每次读一行,依次循环,如果不限定size,直到最后一个返回的是空字符串,意味着到文件末尾了(EOF).
        readlines：size同上.它返回的是以行为单位的列表,即相当于先执行 readline() ,得到每一行,然后把这一行的字符串作为列表中的元素塞到一个列表中,最后将此列表返回.

        Tips
            如果文件太大,就不能用 read() 或者 readlines() 一次性将全部内容读入内存,可以使用while循环和 readline() 来完成这个任务.
            或者使用fileinput
                >>> import fileinput
                >>> 
                >>> for line in fileinput.input("/root/130.txt"):
                ...     print line,
                ... 
                learn python
                http://qiwsir.github.io
                qiwsir@gmail.com
                
                This is about 'with...as...'
