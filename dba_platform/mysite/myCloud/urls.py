#coding=utf8

from django.conf.urls import url
from . import views
from django.contrib.auth import views as authviews

urlpatterns = [
    url(r'^logout', authviews.logout, name='logout'),
    url(r'^login', authviews.login, name='login'),
    url(r'^delete/(?P<file_id>.+)$',views.delete_view,name='delete'),
    url(r'result.html', views.result_view),
    url(r'',views.index_view),
]
