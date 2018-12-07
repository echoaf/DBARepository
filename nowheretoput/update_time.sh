#!/bin/bash


while ((1))
do 
    echo "replace into synchronization_db.t_synchronization values (1,now());"| mysql -uadmin_user -predhat -h172.16.112.12 -P10000
    sleep 0.1
done
