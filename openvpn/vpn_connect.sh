#!/bin/bash

#copy auth credentials to the right spot
cp /root/scripts/openvpn/auth.txt /etc/openvpn/
#change directory to where the script expects the auth file to be
cd /etc/openvpn/

#by default get the files in /etc/openvpn
#files="/etc/openvpn/*.ovpn"

#get the two-digit US and CA tcp configurations only
files="/etc/openvpn/us??.*tcp443.ovpn /etc/openvpn/ca??.*tcp443.ovpn"

#if a particular file was specified, then use that
#otherwise choose at random
if [ "$?" -gt 1 ]
then
	files="$*"
fi

#get all the openvpn configurations we have available to us
ovpn_cnfgs=[]
n=0
for f in $files
do
	#use the stored auth credentials to connect to this server
	cat "$f" | sed 's/auth-user-pass$/auth-user-pass auth\.txt/g' > "${f}_authfixed"
	mv "${f}_authfixed" "$f"
	
	ovpn_cnfgs[$n]="$f"
	n=$(($n+1))
done

#kill any existing openvpn connections
killall openvpn

#create the openvpn connection, with stored login credentials
#using a random ovpn configuration file
#cat /root/scripts/openvpn/auth.txt | openvpn ${ovpn_cnfgs[$(($RANDOM%$n))]} &
openvpn ${ovpn_cnfgs[$(($RANDOM%$n))]} &

#route ALL traffic through the new tun0 interface
iptables -t nat -A POSTROUTING -s 0.0.0.0/0 -o tun0 -j MASQUERADE

#change directory back to wherever this was run from
cd -


