#!/usr/bin/bash

true
echo $?

false
echo $?

echo "Hello world"
echo $?

(exit 41)
echo $?

test 5 -gt 1
echo $?

test 10 -lt 3
echo $?

test 10 -eq 10
echo $?

[ 5 -gt 1 ]
echo $?

((100 > 1))
echo $?

((100 < 1))
echo $?


