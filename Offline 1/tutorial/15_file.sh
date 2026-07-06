#!/usr/bin/bash


while IFS= read -r line; do
  echo "LINE: $line"
done < "readme.txt"

content=$(<"readme.txt")
echo "$content"

mapfile lines < "readme.txt"
echo "L0: ${lines[0]}"


