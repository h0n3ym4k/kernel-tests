#!/bin/bash
#
# Licensed under the terms of the GNU GPL License version 2

source ../../utils/root-check.sh
source ../../utils/build-deps.sh

check_root
is_root=$?
if [ $is_root -ne 0 ]; then
	exit 3
fi

# Clone and build LTP
check_dep autoconf
check_dep git
check_dep automake
check_dep make

set -e

if [ ! -d "ltp" ]; then
	git clone https://github.com/linux-test-project/ltp
fi
pushd ltp
make autotools
./configure
make all
popd

# Call the stress test scripts now
# Right now, these are kind of more "regression" rather than stress.  They can
# take some time, but they're executed sequentially.  Eventually we'll want to
# kick some combination of them off in parallel and let them run for a specific
# duration
./mmstress.sh
#./diostress.sh
./fsstress.sh
./ipcstress.sh
# XXXXXX


# Cleanup
rm -rf ltp
