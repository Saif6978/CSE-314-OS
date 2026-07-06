#!/usr/bin/bash

data="Apple,Banana,Orange"

OLD_IFS="$IFS"
IFS=","
for fruit in $data; do
    echo "Fruit: $fruit"
done
IFS="$OLD_IFS"

IFS="," read fruit1 fruit2 fruit3 <<< "$data"
echo $fruit3

