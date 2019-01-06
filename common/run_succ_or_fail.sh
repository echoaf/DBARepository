#!/bin/bash


function runSuccOrFail()
{
    local explanation=$1
    shift 1
    "$@"
    if [ $? != 0 ]; then
        echo "$explanation" 2>&1
        return 1
    fi
}


cmd="pwd"
result=$(runSuccOrFail "$cmd:exec is error" $cmd)
echo "$result"

