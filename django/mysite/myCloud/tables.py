#coding=utf8

import django_tables2 as tables
from .models import fileModel
from django_tables2.utils import A


class fileTable(tables.Table):
    myfile = tables.columns.FileColumn(attrs={'a': {'download': ''}})
    file_delete = tables.LinkColumn('delete', args=[A('id')],text='删除',verbose_name='操作')
    class Meta:
        model = fileModel

