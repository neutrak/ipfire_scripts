#!/bin/bash

#this attempts to re-establish openvpn connection if it is lost

#the VPN tunnel interface name
#tun0 is the default used by openvpn and is the most common configuration
#but if your tunnel interface is named something else then change that here
tun_if='tun0'

#define the is_vpn_online function
is_vpn_online() {
	if [ "$(ip addr | fgrep -o "${tun_if}")" != '' ]
	then
		echo "true"
	fi
	echo "false"
}

#if the VPN is offline
#NOTE: I know the == "false" string comparison is hacky; blame bash for not having proper boolean evaluation...
if [ "$(is_vpn_online)" == "false" ]
then
	#attempt to reconnect using the standard vpn_connect.sh script already included in this package
	#NOTE: /root/programs/ipfire_scripts is assumed to be the install directory
	/root/programs/ipfire_scripts/openvpn/vpn_connect.sh
fi

