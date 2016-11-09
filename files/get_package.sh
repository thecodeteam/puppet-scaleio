#!/bin/bash -e

ftp_url="$1"
name="$2"
if [[ -z "$name" || -z "$ftp_url" ]] ; then
  exit 0
fi

osfamily=$(facter osfamily)
ext='rpm'
pkg_ext='rpm'
if [[ "$osfamily" == 'Debian' ]] ; then
  ext='deb|tar'
  pkg_ext='deb'
fi

rm -rf "/tmp/$name"
mkdir -p "/tmp/$name"
cd "/tmp/$name"
wget -t 2 -T 30 -q "$ftp_url/" -O index.html
pkg_name=`grep "$name[_-]" "index.html" | grep -P "$ext" | grep -o ">.*<" | sed "s/[><]//g"`
rm -f index.html
wget -t 2 -T 30 -q "$ftp_url/$pkg_name"
if echo "$pkg_name" | grep 'tar' ; then
  tar -xf "$pkg_name"
  siob_file=`ls | grep 'siob$'`
  ./siob_extract "$siob_file"
  rm -f *.tar *.siob* siob_extract
  pkg_name=`ls | grep 'deb'`
fi
mv "$pkg_name" "$name.$pkg_ext"
