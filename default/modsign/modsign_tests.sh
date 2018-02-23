#!/bin/bash
#
# Licensed under the terms of the GNU GPL License version 2

modsign_check_modules()
{
	
	# Grab a module to mess around with.  We'll pick one that is fairly
	# stand-alone and rarely used.
	cp /lib/modules/`uname -r`/kernel/fs/minix/minix.ko.xz .
	xz -d minix.ko.xz
	# Make sure we have the signed module marker
	cat ./minix.ko | strings | grep "~Module signature appended~" &> /dev/null
	if [ "$?" -ne "0" ]
	then
		echo "Module not signed"
		return 1
	fi

	# Now check to see if it's signed with a Fedora cert
	# FIXME: This isn't actually an exhaustive check.  It doesn't verify
	# the signature embedded is for the key that is loaded into the
	# running kernel.  A module from some other signed kernel would still
	# pass here, but would fail to load later, etc.
	#
	# Need to write some code to actually extract the sig itself and
	# compare.
	cat ./minix.ko | strings | grep "Fedora kernel signing key" &> /dev/null
	if [ "$?" -ne "0" ]
	then
		echo "Module not signed"
		return 1
	fi

	# Make sure it isn't already loaded
	lsmod | grep minix
	if [ $? == "0" ]
	then
		"Module already in use.  Skipping"
		return 3
	fi

	fail=0
	insmod ./minix.ko
	if [ "$?" -ne "0" ]
	then
		echo "Signed module failed to load"
		fail=1
	else
		echo "Successfully loaded signed module"
	fi
	
	rmmod minix
	rm ./minix.ko
	return ${fail}
}

modsign_unsigned()
{
	# Grab a module to mess around with.  We'll pick one that is fairly
	# stand-alone and rarely used.
	cp /lib/modules/`uname -r`/kernel/fs/minix/minix.ko.xz .
	xz -d minix.ko.xz
	strip -g ./minix.ko
	
	# Make sure it isn't already loaded
	lsmod | grep minix
	if [ $? == "0" ]
	then
		"Module already in use.  Skipping"
		return 3
	fi
	insmod ./minix.ko
	loaded=$?
	
	fail=0
	if [ "$1" == "N" ]
	then
		if [ ${loaded} -ne "0" ]
		then
			echo "Unsigned module load failed"
			fail=1
		else
			echo "Successfully loaded unsigned module"
			rmmod minix
		fi
	else
		if [ ${loaded} -ne "0" ]
		then
			echo "Unsigned module load failed in enforcing mode"
		else
			echo "Unsigned module loaded in enforcing mode"
			rmmod minix
			fail=1
		fi
	fi

	# cleanup
	rm ./minix.ko

	return ${fail}
}			

modsign_third_party()
{
	return 0
}		

# Figure out if modsign is enabled in this kernel
modsign=0
if [ -f /proc/keys ]
then
	cat /proc/keys | grep builtin_trusted_keys &> /dev/null
	if [ $? -ne "0" ]
	then
		echo Module signing not enabled
		exit 3
	fi
	keyring=`cat /proc/keys | grep builtin_trusted_keys | cut -f 1 -d " "`
	keyctl list 0x${keyring} | grep "Fedora kernel signing key" &> /dev/null
	if [ $? == "0" ]
	then
		modsign=1
	else
		echo "Module signing enabled but no key listed"
		exit 1
	fi
fi

if [ ${modsign} -ne "1" ]
then
	echo "Module signing not enabled.  I have no idea why but whatever"
	exit 1
fi

# OK, now for some fun stuff.

# Are we in enforcing?

enforcing=`cat /sys/module/module/parameters/sig_enforce`

# SecureBoot should enforce requirement of valid module signatures regardless of sig_enforce.
# Check that SecureBoot is enabled in EFI variables
secureboot=`od -An -t u1 /sys/firmware/efi/efivars/SecureBoot-* 2>/dev/null | awk ' { print $5 } '`
if [ "$secureboot" == "1" ]
then
        enforcing="Y"
fi

# Make sure we actually have signed modules and that they load
modsign_check_modules

# Run some tests to see if we let unsigned modules load, etc
modsign_unsigned ${enforcing}
modsign_third_party ${enforcing}
