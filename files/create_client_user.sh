#!/bin/bash -e

user=$1
password=$2

if scli --query_user --username $user ; then
  # user already exists. exiting.
  exit
fi

if ! output=`scli --add_user --username $user --user_role FrontEndConfigure` ; then
  echo "$output"
  exit 1
fi
default_password=`echo $output | grep -Po " '[a-zA-Z0-9]*'$" | xargs`

scli --login --username $user --password $default_password
scli --set_password --old_password $default_password --new_password $password
scli --login --username $user --password $password
scli --logout
