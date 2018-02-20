#!/bin/sh
#
# Licensed under the terms of the GNU GPL License version 2

COUNT=$(find /sys -type f -perm 666 | ./ignore-files.sh | wc -l)

if [ "$COUNT" != "0" ]; then
	echo Found world-writable files in sysfs.
	find /sys -type f -perm 666 | ./ignore-files.sh
	exit 4
fi

exit 0
