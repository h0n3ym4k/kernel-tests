#!/bin/sh

COUNT=$(find /sys -type f -perm 666 | ignore-files.sh | wc -l)

if [ "$COUNT" != "0" ]; then
	echo Found world-writable files in sysfs.
	find /sys -type f -perm 666 | ignore-files.sh
	exit -1
fi

exit 0
