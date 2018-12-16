#!/usr/bin/env python
#coding=utf8

a = "this isn't a word, right?"
a = a.replace("'", " ")
a = a.replace(".", " ")
a = a.replace("?", " ")
a = a.replace(",", "")

print a


###### maketrans 替换replace
# .replace can be fine. This is faster:
from string import maketrans
tab = maketrans("'.?", "   ")
a = "this isn't a word, right."
afilt = a.translate(tab, ",")
print afilt
