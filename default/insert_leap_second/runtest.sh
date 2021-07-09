#!/bin/sh
#
# Licensed under the terms of the GNU GPL License version 2

# Test inserting a leap second

# Make sure we can run this test successfully
source ../../utils/root-check.sh
check_root
is_root=$?
if [ "$is_root" -ne "0" ]; then
        exit 3
fi

#VirtualBox syncs time with the host and makes this test fail
if [ ! -f /usr/sbin/dmidecode ]; then
	echo "dmidecode was not installed, skipping."
	exit 3
fi
dmi=$(LANG=C /usr/sbin/dmidecode 2>&1)
if echo "$dmi" | grep -q 'Manufacturer: innotek GmbH'; then
	echo "This test does not work on Virtualbox guests"
	exit 3
fi

# build the test source (upstream is git://github.com/johnstultz-work/timetests.git)
if [ ! -f ./leap-a-day ]; then
	gcc -o leap-a-day leap-a-day.c
	if [ "$?" -ne "0" ]; then
		echo "leap-a-day build failed."
		exit 3
	fi
fi

# Check chronyd status and disable if enabled
if ! /usr/bin/systemctl status chronyd | grep -q active; then
	# We don't want to change the time without fixing it
	exit 3
else
	/usr/bin/systemctl stop chronyd
fi

# Run the test
# insert a leap second one time, and reset the time to within
# 10 seconds of midnight UTC.
./leap-a-day -s -i 1 | tee -a test.out
# Restart chronyd
/usr/bin/systemctl start chronyd
if ! grep -q TIME_WAIT test.out; then
	exit -1
fi
