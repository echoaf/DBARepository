# -*- coding: utf-8 -*-


from django.db import models

# Create your models here.
import os
class fileModel(models.Model):
    myfile = models.FileField()
    upload_date = models.DateField(auto_now_add=True)
    def delete(self,*args,**kwargs):
        if os.path.isfile(self.myfile.path):
            os.remove(self.myfile.path)
        super(fileModel, self).delete(*args,**kwargs)



#class t_mysql_user():
#    Fusername = CharField()
#    Fpassword = PasswordField()
#    Femail = EmailField()
