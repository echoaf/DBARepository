# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models

# Create your models here.



# DBA CMDB table
class t_machine_info(models.Model):
    Ftype = models.CharField('服务器类型', max_length=64)
    Fserver_host = models.CharField('IP', max_length=32)
    Fserver_port = models.IntegerField('端口', default=3306)
    Fstate = models.CharField('机器状态', max_length=16)
    Fcreate_time = models.DateTimeField('创建时间', auto_now=True)
    Fmodify_time = models.DateTimeField('更新时间', auto_now_add=True)

    #def delete(self,*args,**kwargs):
    #    if os.path.isfile(self.myfile.path):
    #        os.remove(self.myfile.path)
    #    super(fileModel, self).delete(*args,**kwargs)

    #def __str__(self):
    #    return self.Ftype

    #class Meta:
    #    verbose_name = u'主库地址配置'
    #    verbose_name_plural = u'主库地址配置'

    #def save(self, *args, **kwargs):
    #    pc = Prpcrypt()  # 初始化
    #    self.master_password = pc.encrypt(self.master_password)
    #    super(master_config, self).save(*args, **kwargs)



