#!/bin/bash
#
# Licensed under the terms of the GNU GPL License version 2

date=$(date +%s)
logdir=$(pwd)/logs
logfile=$logdir/kernel-test-$date.log.txt
verbose=n
testset=default
cleanrun=PASS
failedtests=None
commit=n
commithook=/usr/bin/true

if [ -f ./.config ]; then
	source ./.config
else
	echo "No .config file found. You can cp config.example .config and edit as needed for easier log submission"
fi

kver=$(uname -r)
release=$(cat /etc/redhat-release)

# Check for pre-requisites.
if [ ! -f /usr/bin/gcc ]; then
	echo Fedora kernel test suite needs gcc.
	exit
fi

# unset MALLOC_CHECK_ and MALLOC_PERTURB_.  Some tests might not work well
# with those active (like libhugetlbfs)
unset MALLOC_CHECK_
unset MALLOC_PERTURB_

if [ ! -d "$logdir" ] ; then
	mkdir $logdir
fi

args=y

while [ $args = y ]
do
        case "$1" in
	-v)
		#TO DO: Implement verbose behavior
		verbose=y
		shift 1
		;;
	-t)
		testset=$2
		shift 2
		;;
	*)
		args=n
	esac
done

case $testset in
minimal)
	dirlist="minimal"
	;;
default)
	dirlist="minimal default"
	;;
stress)
	dirlist="minimal default stress"
	;;
destructive)
	echo "You have specified the destructive test set"
	echo "This test may cause damage to your system"
	echo "Are you sure that you wish to continue?"
	read continue
	if [ $continue == 'y' ] ; then
		dirlist="minimal default destructive"
	else
		dirlist="minimal default"
		testset=default
	fi
	;;
performance)
	dirlist="performance"
	;;
*)
	echo "supported test sets are minimal, default, stress, destructive or performance"
	exit 1
esac


#Basic logfile headers
echo "Date: $(date)" > $logfile
echo "Test set: $testset" >> $logfile
echo "Kernel: $kver" >> $logfile
echo "Release: $release" >> $logfile
echo "Result: RESULTHOLDER" >> $logfile
echo "============================================================" >>$logfile



#Start running tests
echo "Test suite called with $testset"

for dir in $dirlist
do
	for test in $(find ./$dir/ -name runtest.sh)
	do
		testdir=$(dirname $test)
		pushd $testdir &>/dev/null
		#TO DO:  purpose file test name format
		testname=$testdir
		echo "Starting test $testname" >> $logfile

		if [ "$testset" == "performance" ]; then
			./runtest.sh >>$logfile
		else
			./runtest.sh &>>$logfile
			complete=$?
			case $complete in
			0)
				result=PASS
				;;
			3)
				result=SKIP
				;;
			*)
				result=FAIL
			esac
			printf "%-65s%-8s\n" "$testname" "$result"
			if [ "$result" == "FAIL" ]; then
				cleanrun=FAIL
				if [ "$failedtests" == "None" ]; then
					failedtests="$testname"
				else
					failedtests="$failedtests $testname"
				fi
			fi
		fi
		popd &>/dev/null
	done
done

# Fix up logfile headers
sed -i "s,RESULTHOLDER,$cleanrun\nFailed Tests: $failedtests,g" $logfile
printf "\n%-65s%-8s\n" "Test suite complete" "$cleanrun"

if [ "$commit" == "y" ]; then
	printf "\nYour log file is being submitted\n"
	$commithook
else
	printf "\nYour log file is located at: $logfile\n"
	printf "Submit your results to: https://apps.fedoraproject.org/kerneltest/\n"
fi


if [ "$cleanrun" == "FAIL" ]; then
	exit 1
else
	exit 0
fi
