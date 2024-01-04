#!/usr/bin/python
#  pylint: disable=missing-module-docstring,invalid-name
#
#
#


import sys

sys.path.append("..")
#  pylint: disable-next=wrong-import-position
from rhn.transports import Output

#  pylint: disable-next=wrong-import-position
from rhn.connections import HTTPConnection

if __name__ == "__main__":
    conn = HTTPConnection("localhost", 5555)
    o = Output(connection=conn)

    o.set_header("X-Test-1", "a")
    o.set_header("X-Test-2", ["a", "b", "c"])

    data = "0123456789"

    o.process(data)

    headers, fd = o.send_http("fake.example.com")
