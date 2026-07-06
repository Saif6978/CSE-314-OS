#!/usr/bin/bash

if true
then
  echo "true condition"
fi

if true; then
  echo "true again"
fi

if false; then
  echo "You cant see me"
fi

if ! echo "Hello"; then
  echo "World"
fi


n=5
if test $n -eq 5; then
  echo "n is 5"
fi

if [ $n -lt 10 ]; then
  echo "n is less than 10"
elif [ $n -eq 10 ]; then
  echo "n is 10"
else
  echo "n is more than 10"
fi

if [ $(expr $n + 2) -eq 7 ]; then
  echo "n + 2 is 7"
fi


if test $n -gt 2 && test $n -lt 8; then
  echo "2 < n < 8"
fi

if [ $n -gt 2 ] && [ $n -lt 8 ]; then
  echo "2 < n < 8"
fi


if [[ $n > 2 ]] && [[ $n < 8 ]]; then
  echo "2 < n < 8"
fi

if [[ 2 < $n && $n < 8 ]]; then
  echo "2 < n < 8"
fi


if [[ 2 -le $n && $n -le 8 ]]; then
  echo "2 <= n <= 8"
fi


if (( 2 <= $n && $n <= 8 )); then
  echo "2 <= n <= 8"
fi


