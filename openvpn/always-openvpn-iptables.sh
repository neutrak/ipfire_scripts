#!/bin/bash

#NOTE: these rules are specifically applicable in the ipfire environment
#for systems not running ipfire the interface names and table names will likely be different

#in terms of naming, the following applies:
#	red+ : the WAN interface(s) which routed traffic is sent to
#	tun+ : the VPN interface(s) which routed traffic is sent to when a VPN connection has already been established
#	CUSTOMFORWARD : the iptables FORWARD-ing table which we can add rules to
#	192.168.0.0/16 : the local LAN subnet

#accept all traffic that is destined for the tunnel interface
#as this is where outbound traffic is intended to go and so it should be allowed there
iptables -A CUSTOMFORWARD -o tun+ -j ACCEPT

#accept all traffic that is routed over red0 but will end up at a LAN endpoint
#as we want LAN traffic to continue to work as expected
iptables -A CUSTOMFORWARD -o red+ -d 192.168.0.0/16 -j ACCEPT

#for all other traffid destined for the WAN interface,
#hard drop it as it could leak information about where we are
#and we don't want that
iptables -A CUSTOMFORWARD -o red+ -j DROP


#the effect of these rules is that if the VPN tunnel is offline the firewall will stop routing to any non-local subnets or ip addresses
#thus preventing any potential leaks until VPN connection can be re-established

#NOTE: the openvpn program itself is not subject to these rules because that traffic originates from the firewall machine
#and therefore doesn't go to the FORWARD or CUSTOMFORWARD tables but instead ends up directly at OUTPUT
#therefore openvpn can reconnect without being blocked by the above rules

#NOTE: this does NOT attempt to re-establish VPN connection if it is dropped
#for that task a separate cron job is recommended (see always-openvpn-cron.sh)

