#!/bin/bash

#copy auth credentials to the right spot
cp /root/programs/ipfire_scripts/openvpn/auth.txt /etc/openvpn/
#change directory to where the script expects the auth file to be
cd /etc/openvpn/

#by default get the files in /etc/openvpn
#files="/etc/openvpn/*.ovpn"

#get the US and CA tcp configurations only
#files=(/etc/openvpn/us*.*tcp443.ovpn /etc/openvpn/ca*.*tcp443.ovpn)

#US configurations only
files=(/etc/openvpn/us*.*tcp443.ovpn /etc/openvpn/us*.*udp1194.ovpn)

#if a particular file or list of files was specified, then use those
if [ "$#" -ge 1 ]
then
	unset files
	files=("$@")
fi

#selected file to actually use for a connection
#choose at random from our list of possible files
sel_file="${files[$(($RANDOM%(${#files[@]})))]}"

#update the file we're going to use with automatic authentication

#use the stored auth credentials to connect to this server
cat "${sel_file}" | sed 's/auth-user-pass$/auth-user-pass auth\.txt/g' > "${sel_file}_authfixed"
mv "${sel_file}_authfixed" "$sel_file"

#kill any existing openvpn connections
killall openvpn

#verbose
echo "Connecting to server defined by ${sel_file}"
echo "..."

#create the openvpn connection, with stored login credentials
openvpn "${sel_file}" &

#route ALL traffic through the new tun0 interface
iptables -t nat -A POSTROUTING -s 0.0.0.0/0 -o tun0 -j MASQUERADE

#change directory back to wherever this was run from
cd -


