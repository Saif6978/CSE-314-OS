#!/usr/bin/bash

languages=(c cpp java python js)

echo "languages =" ${languages[@]}
echo "languages[1] =" ${languages[1]}
echo "len(languages) =" ${#languages[@]}

# Append
languages+=(zig rust)
echo "After insertion" "${languages[@]}"

# Deletion
unset languages[1]
echo "After deletion" "${languages[@]}"

