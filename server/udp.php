#!/usr/bin/env php
<?php

if ( count($argv) < 0 )
{
	fprintf (STDERR, "Wrong invocation of udp.php");
	exit(1);
}

$address = $argv[1];
$port    = $argv[2];
$payload = fgets(STDIN);
$readsize= 1024;
$read_address = empty($argv[3]) ? $address : $argv[3];
$read_port = $port;

$socket = socket_create(AF_INET, SOCK_DGRAM, SOL_UDP);
socket_bind($socket, $address);
socket_getsockname($socket,$read_address,$read_port);
socket_set_timeout($socket,0,1000);
socket_sendto($socket, $payload, strlen($payload), 0, $address, $port);


@socket_recvfrom($socket, $data, $readsize, MSG_DONTWAIT, $read_address, $read_port);
print($data);