#!/usr/bin/bash

foo() {
  echo "Hello world"
  echo "Bye"
  return 41
}

msg=$(foo)
echo $?
echo "$msg"


bar() {
  echo "The first argument is: ${1}"
  echo "The second argument is: ${2:-default2}"
  echo "The total number of arguments passed is: $#"

  echo "Arguments:" "$@"
}

bar hello world of bash


