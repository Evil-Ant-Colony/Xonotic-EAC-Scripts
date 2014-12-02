#!/usr/bin/python
import sys
import socket

if len(sys.argv) < 3:
	print >> sys.stderr, "Wrong invocation of udp.py"
	sys.exit(1);

address = sys.argv[1]
port    = int(sys.argv[2])
payload = sys.stdin.read()
readsize= 1024

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM);
sock.bind((address,0))
sock.settimeout(0.1)
sock.sendto(payload, (address, port))

try:
	(data,addr) = sock.recvfrom(1024)
	print data
except:
	print >> sys.stderr, "Connection failed"
