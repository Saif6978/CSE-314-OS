#!/usr/bin/bash

i=0
while (($i < 5)); do
  echo $i
  ((i++))
  # continue
  # echo "Hello"
done

i=0
until (($i >= 5)); do
  echo $i
  ((i++))
done


