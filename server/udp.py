#!/usr/bin/env python3
import sys
import socket

if len(sys.argv) < 3:
	print("Wrong invocation of udp.py", file=sys.stderr)
	sys.exit(1)

address = sys.argv[1]
port    = int(sys.argv[2])
payload = sys.stdin.buffer.read()
readsize= 1024

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM);
sock.bind((address,0))
sock.settimeout(0.1)
sock.sendto(payload, (address, port))

try:
	(data,addr) = sock.recvfrom(1024)
	sys.stdout.buffer.write(data)
except:
	print("Connection failed", file=sys.stderr)
