#! /bin/bash

# kernel testing: steps as currently (14-09-2021) recommended on
# https://fedoraproject.org/wiki/QA:Testcase_kernel_regression
sudo semanage boolean -m --on selinuxuser_execheap

sudo ./runtests.sh

sudo ./runtests.sh -t performance

sudo semanage boolean -m --off selinuxuser_execheap
