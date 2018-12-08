#!/bin/bash

action="$1"


if [ -z "$action" ];then
    action="en"
else
    action="ch"
fi


if [ "$action" = "en" ];then
    sed -i 's/“/"/g' *.txt
    sed -i 's/”/"/g' *.txt
    sed -i 's/，/,/g' *.txt
    sed -i 's/。/./g' *.txt
    sed -i 's/；/;/g' *.txt
    sed -i 's/（/(/g' *.txt
    sed -i 's/）/)/g' *.txt
else
    echo 1
fi
