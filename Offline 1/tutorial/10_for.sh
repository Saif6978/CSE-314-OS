#!/usr/bin/bash

for i in bash is easy
do
  echo $i
done

for i in {1..5}; do
  echo $i
done

for i in $(ls); do
  echo $i
done

for i in $(seq 1 2 6); do
  echo $i
done

sum=0
for ((i = 1; i <= 1000; i++)); do
  ((sum += i))
done

echo $sum


