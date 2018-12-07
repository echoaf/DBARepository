# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from datetime import date
from django.http import HttpResponse
from django.contrib.auth.decorators import login_required
from django.shortcuts import render,redirect
from .models import fileModel
from .tables import fileTable


@login_required(login_url='/login/')
def index_view(request):
    today = str(date.today())
    word = "hello, today is " + today
    table = fileTable(fileModel.objects.all())
    return render(request,'index.html',{'baoshi':word,'biaoge':table})


def result_view(request):
    if request.method == 'POST':
        data=request.FILES['myfile']
        file = fileModel(myfile=data)
        file.save()
        return redirect('/')
    return HttpResponse("Sorry the uplaod is unsucessful.")


def delete_view(request,file_id):
    try:
        u=fileModel.objects.get(id=file_id)
        u.delete()
    except:
        pass
    return redirect('/')
