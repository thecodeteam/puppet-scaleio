#!/bin/bash -e

user=$1
password=$2
mdm_ips=${3:-""}

if [[ -z "${mdm_ips}" ]]; then
  mdm_opts=""
else
  mdm_opts="--mdm_ip ${mdm_ips}"
fi

if scli $mdm_opts --query_user --username $user ; then
  # user already exists. exiting.
  exit
fi

if ! output=`scli $mdm_opts --add_user --username $user --user_role FrontEndConfigure` ; then
  echo "$output"
  exit 1
fi
default_password=`echo $output | grep -Po " '[a-zA-Z0-9]*'$" | xargs`

scli $mdm_opts --login --username $user --password $default_password
scli $mdm_opts --set_password --old_password $default_password --new_password $password
scli $mdm_opts --login --username $user --password $password
scli $mdm_opts --logout
