#!/usr/bin/bash

# This is a comment

echo "Hello world" # It can be inline

echo -e "print(\"hello world\")\nexit(5)" > main.py
python3 main.py

echo $?

rm main.py

(cd /)
ls

exit 41
