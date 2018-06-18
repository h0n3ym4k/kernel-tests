#!/usr/bin/env python3
#
# Licensed under the terms of the GNU GPL License version 2

import getopt
import getpass
import sys

from fedora.client import OpenIdBaseClient

username = ''
password = ''
log = ''

argv = sys.argv[1:]
try:
    opts, args = getopt.getopt(argv,"hu:p:l:",["user=","password=", "logfile="])
except getopt.GetoptError:
    print('fedora_submit.py -u <fasuser> [-p <password>] -l <logfile>')
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print('fedora_submit.py -u <fasuser> [-p <password>] -l <logfile>')
        sys.exit()
    elif opt in ("-u", "--user"):
        username = arg
    elif opt in ("-p", "--password"):
        password = arg
    elif opt in ("-l", "--logfile"):
        log = arg

if username == '' or log == '':
    print('fedora_submit.py -u <fasuser> [-p <password>] -l <logfile>')
    sys.exit(2)
if password == '':
    password = getpass.getpass('FAS password: ')

submitclient = OpenIdBaseClient(
    base_url='https://apps.fedoraproject.org/kerneltest/',
    login_url='https://apps.fedoraproject.org/kerneltest/login',
    username=username,
)
 
submitclient.login(
    submitclient.username,
    password=password
)
 
req = submitclient.send_request(
    'https://apps.fedoraproject.org/kerneltest/upload/anonymous',
    verb='POST',
    auth=True,
    files= { 'test_result': ('logfile', open(log, 'rb'), 'text/x-log'),}
)
 
print(req.message)

