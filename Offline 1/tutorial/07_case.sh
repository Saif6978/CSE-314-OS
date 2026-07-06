#!/usr/bin/bash


day=$(date +%w)

case $day in
  0)
    echo "Sunday"
    ;;
  1)
    echo "Monday"
    ;;
  2)
    echo "Tuesday"
    ;;
  3)
    echo "Wednesday"
    ;;
  4)
    echo "Thursday"
    ;;
  5)
    echo "Friday"
    ;;
  6)
    echo "Saturday"
    ;;
esac



case $day in
  4|5) echo "Yay! No BUET";;
  *) echo "All work and no play";;
esac


filename="backup_2026.tar.gz"

case "$filename" in
    *.jpg|*.png|*.gif) echo "Image";;
    *.tar.gz|*.tgz|*.zip) echo "Compressed archive";;
    report_??.txt) echo "Report_XY";;
    [a-z]*[0-9]) echo "Lowercase #### digit";;
    *) echo "Unknown file format.";;
esac
