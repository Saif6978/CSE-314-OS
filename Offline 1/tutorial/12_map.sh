#!/usr/bin/bash

declare -A capital=(
  [Bangladesh]=Dhaka
  [China]=Beijing
  [Russia]=Moscow
)

echo "Keys =" "${!capital[@]}"
echo "Values =" "${capital[@]}"


if [[ ! -v capital[France] ]]; then
  echo "France not in key set of capital"
  capital[France]=Paris
  echo "${capital[France]}"
fi

unset capital[China]
echo "Keys =" "${!capital[@]}"
echo "Values =" "${capital[@]}"

