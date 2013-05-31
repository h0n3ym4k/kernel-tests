#!/bin/bash

install_dep() {
	yum install -y $1;
	rc=$?;
	if [ $rc -ne 0 ]
	then
		echo "Could not install $1"
		return 3
	fi
	return 0
}

check_dep() {
	rpm -q $1
	rc=$?
	if [ $rc -ne 0 ]
	then
		echo "Could not find $1.  Attempting to install"
		install_dep $1
		rc=$?
	fi
	return $rc
}
