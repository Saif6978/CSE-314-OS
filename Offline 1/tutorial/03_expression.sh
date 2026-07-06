#!/usr/bin/bash

expr 7 + 2
expr 7 - 2
expr 7 \* 2
expr 7 / 2

n=$(expr 7 + 2)
echo $n

n=$((7 * 2))
echo $n

((n = 7 / 2))
echo $n

