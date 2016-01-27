#!/bin/bash

#this makes a pg-format blocklist file from the given domains

domain_file="blocked_domains.txt"
domain_blocklist="domain_blocklist"
egrep -v "^#|^$" "$domain_file" | while read line
do
	ips=$(nslookup "$line" | fgrep -A 100 answer | fgrep 'Address' | egrep -o "([0-9]*\.)*[0-9]*")
	for ip in $ips
	do
		echo "$line:$ip-$ip"
	done
done | egrep -v "^$"
#done | egrep -v "^$" > "$domain_blocklist"
#gzip "$domain_blocklist"

