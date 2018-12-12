#!/bin/bash

action="$1"


if [ -z "$action" ];then
    action="en"
else
    action="ch"
fi

chmod a+x *.txt *.py *.sh

if [ "$action" = "en" ];then
    sed -i 's/“/"/g' *.txt *.py
    sed -i 's/”/"/g' *.txt *.py
    sed -i 's/，/,/g' *.txt *.py
    sed -i 's/。/./g' *.txt *.py
    sed -i 's/；/;/g' *.txt *.py
    sed -i 's/（/(/g' *.txt *.py
    sed -i 's/）/)/g' *.txt *.py
else
    echo 1
fi
