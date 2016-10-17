#!/bin/bash

# Snippet to ping gameserver directly using 'nc' utility
# Source: https://developer.valvesoftware.com/wiki/Source_Server_Queries

srvip=127.0.0.1
port=27015
timeout=1

srv_qry(){

	# Query A2A_PING from server
	rply=$(echo -ne "\xFF\xFF\xFF\xFF\x69\x00" | nc -nu -q 1 -w $timeout $srvip $port)

	# strip null chars
	rply=${rply:4:1}

	# If we get 'j' then server is up, otherwise it's down
	if [ "$rply" == "j" ]; then
		# do something if is up
	else
		# do something if is down
	fi

}
