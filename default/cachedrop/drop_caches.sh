#!/bin/sh

# Copyright (c) 2011 Red Hat, Inc. All rights reserved. This copyrighted material 
# is made available to anyone wishing to use, modify, copy, or
# redistribute it subject to the terms and conditions of the GNU General
# Public License v.2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Author: Zhouping Liu <zliu@redhat.com>

TMP_FILE=`mktemp /tmp/drop_XXXXXX`
TUNE_FILE=/proc/sys/vm/drop_caches

function verify_tune_value()
{
	if [ $# -ne 2 ]; then
		echo "Usage: verify_tune [TUNE_FILE] [TUNE_VALUE]"
		exit -1;
	fi

	TUNE_FILE=$1
	TUNE_VALUE=$2

	TEST_TUNE=`cat ${TUNE_FILE}`
	if [ ${TEST_TUNE} -ne ${TUNE_VALUE} ]; then
		echo "TestError: Set value to ${TUNE_FILE} Failed"
		exit -1
	fi
}

function free_pagecache()
{
	dd if=/dev/zero of=${TMP_FILE} bs=1024k count=100 > /dev/null
	sleep 1
	original_cache=`vmstat | awk '{print $6}'| sed -n '3p'`

	sync
	echo 1 > ${TUNE_FILE}
	# /proc/sys/vm/drop_caches is write only now
	# verify_tune_value ${TUNE_FILE} 1

	sleep 1
	new_pagecache=`vmstat | awk '{print $6}'| sed -n '3p'`
	if [ ${new_pagecache} -gt ${original_cache} ]; then
		echo "TestError: Can't free pagecache"
		echo "${new_cache} ${original_cache}"
		exit -1
	fi

	rm -rf ${TMP_FILE}
}

function free_dentries_inodes()
{
	for X in `seq 1 20`; do
		touch ${TMP_FILE}$X
		echo "TEST" > ${TMP_FILE}$X
	done
	sleep 2
	original_cache=`vmstat | awk '{print $6}'| sed -n '3p'`
	
	sync
	echo 2 > ${TUNE_FILE}
	# /proc/sys/vm/drop_caches is write only now
	# verify_tune_value ${TUNE_FILE} 2
	sleep 2

	new_cache=`vmstat | awk '{print $6}'| sed -n '3p'`
	if [ ${new_cache} -gt ${original_cache} ]; then
		echo "TestError: Can't free dentries and inodes"
		echo "${new_cache} ${original_cache}"
		exit -1
	fi

	rm -rf ${TMP_FILE}*
}

function free_pagecache_dentries_inodes()
{
	dd if=/dev/zero of=${TMP_FILE} bs=1024k count=10 > /dev/null
	for X in `seq 1 10`; do
		touch ${TMP_FILE}$X
		echo "TEST" > ${TMP_FILE}$X
	done
	sleep 2

	original_cache=`vmstat | awk '{print $6}'| sed -n '3p'`

	sync
	echo 3 > ${TUNE_FILE}
	# /proc/sys/vm/drop_caches is write only now
	# verify_tune_value ${TUNE_FILE} 3
	sleep 1
	
	new_cache=`vmstat | awk '{print $6}'| sed -n '3p'`
	if [ ${new_cache} -gt ${original_cache} ]; then
		echo "TestError: Can't free dentries and inodes and pagecache"
		echo "${new_cache} ${original_cache}"
		exit -1
	fi

	rm -rf ${TMP_FILE}*
}

function main()
{
	if ! [ -f ${TUNE_FILE} ]; then
		echo "Could not locate ${TUNE_FILE}"
		exit -1
	fi

	free_pagecache
	free_dentries_inodes
	free_pagecache_dentries_inodes

	echo "TestPASS: ${TUNE_FILE} PASS"
}

main
