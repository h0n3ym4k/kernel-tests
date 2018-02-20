#!/bin/bash

source ../../utils/root-check.sh
source ../../utils/build-deps.sh

check_root
is_root=$?
if [ $is_root -ne 0 ]; then
	exit 3
fi

# Ensure we have curl and kernel-devel
check_dep curl
check_dep kernel-devel
check_dep elfutils-libelf-devel

baseurl='http://http.download.nvidia.com/XFree86/Linux-x86_64'
latest=`curl $baseurl/latest.txt | cut -d ' ' -f1`
installer="NVIDIA-Linux-x86_64-$latest"


if [ ! -f "$installer" ]
then
	curl -O "$baseurl/$latest/$installer.run"
	[ $? -eq 0 ] || exit 3
fi

sh $installer.run --extract-only --target tmp
pushd tmp/kernel
make modules > build.log
[ $? -eq 0 ] || exit 4
popd
rm -rf tmp

echo module version $latest built for `uname -r`
