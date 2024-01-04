#!/usr/bin/python
#  pylint: disable=missing-module-docstring,invalid-name
#
# tests uploads over SSL
#
#
# USAGE:  $0 SERVER SYSTEMID
# OUTPUT: return code = 0


import sys

sys.path.append("..")
#  pylint: disable-next=wrong-import-position
from rhn.rpclib import Server

SERVER = "xmlrpc.rhn.redhat.com"
HANDLER = "/XMLRPC"
system_id_file = "/etc/sysconfig/rhn/systemid"
try:
    SERVER = sys.argv[1]
    system_id_file = sys.argv[2]
#  pylint: disable-next=bare-except
except:
    pass


def get_test_server_https():
    #  pylint: disable-next=global-variable-not-assigned,global-variable-not-assigned
    global SERVER, HANDLER
    #  pylint: disable-next=consider-using-f-string
    return Server("https://%s%s" % (SERVER, HANDLER))


if __name__ == "__main__":
    #  pylint: disable-next=unspecified-encoding
    systemid = open(system_id_file).read()

    s = get_test_server_https()

    # Generate a huge list of packages to "delete"
    packages = []
    for i in range(3000):
        #  pylint: disable-next=consider-using-f-string
        packages.append(["package-%d" % i, "1.1", "1", ""])

    result = s.registration.delete_packages(systemid, packages[:1000])
    sys.exit(result)
