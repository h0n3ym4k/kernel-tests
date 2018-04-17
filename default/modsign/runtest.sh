#!/bin/sh
#
# Licensed under the terms of the GNU GPL License version 2

source ../../utils/root-check.sh

check_root
is_root=$?
if [ "$is_root" -ne "0" ]; then
	exit 3
fi

keyctl &>/dev/null
if [ "$?" -eq "127" ]; then
	echo "keyutils must be installed for this test."
	exit 3
fi

# Run
./modsign_tests.sh
result=$?
if [ "$result" -ne "0" ]; then
	echo "Could not run tests"
	exit $result
fi
