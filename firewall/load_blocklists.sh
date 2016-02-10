#!/bin/bash

#shamelessly copied from http://www.maeyanie.com/2008/12/efficient-iptables-peerguardian-blocklist/
#with minor edits as needed

#quit if not connected to the internet
wget -q --spider http://www.google.com
if [ "$?" -ne 0 ]
then
	exit "$?"
fi

unset blocklists

#the following format is used for blocklist entries
# offset 0 -> url or local file path
# offset 1 -> blocklist name
# offset 2 -> ipset name to make
# offset 3 -> online or local?
# offset 4 -> filter through which to run the list (can be used to select only specific entries or exclude particular entries, etc.)


#blocklists[${#blocklists[@]}]='http://list.iblocklist.com/?list=xshktygkujudfnjfioro&fileformat=p2p&archiveformat=gz'
#blocklists[${#blocklists[@]}]='bluetack-microsoft'
#blocklists[${#blocklists[@]}]='MICROSOFT'
#blocklists[${#blocklists[@]}]='online'
#blocklists[${#blocklists[@]}]='cat'

blocklists[${#blocklists[@]}]='http://list.iblocklist.com/?list=llvtlsjyoyiczbkjsxpf&fileformat=p2p&archiveformat=gz'
blocklists[${#blocklists[@]}]='bluetack-spyware'
blocklists[${#blocklists[@]}]='SPYWARE'
blocklists[${#blocklists[@]}]='online'
blocklists[${#blocklists[@]}]='cat'

blocklists[${#blocklists[@]}]='http://list.iblocklist.com/?list=dgxtneitpuvgqqcpfulq&fileformat=p2p&archiveformat=gz'
blocklists[${#blocklists[@]}]='bluetack-ads'
blocklists[${#blocklists[@]}]='ADS'
blocklists[${#blocklists[@]}]='online'
blocklists[${#blocklists[@]}]='cat'

#blocklists[${#blocklists[@]}]='http://list.iblocklist.com/?list=imlmncgrkbnacgcwfjvh&fileformat=p2p&archiveformat=gz'
#blocklists[${#blocklists[@]}]='bluetack-edu'
#blocklists[${#blocklists[@]}]='EDU'
#blocklists[${#blocklists[@]}]='online'
#blocklists[${#blocklists[@]}]='cat'

blocklists[${#blocklists[@]}]='http://list.iblocklist.com/?list=ydxerpxkpcfqjaybcssw&fileformat=p2p&archiveformat=gz'
blocklists[${#blocklists[@]}]='bluetack-level1'
blocklists[${#blocklists[@]}]='LEVEL1'
blocklists[${#blocklists[@]}]='online'
blocklists[${#blocklists[@]}]='egrep -v -i "(VALVE CORP)|(VALVE SOFT)"'

blocklists[${#blocklists[@]}]='domain_blocklist.gz'
blocklists[${#blocklists[@]}]='manual-domains'
blocklists[${#blocklists[@]}]='MANUAL'
blocklists[${#blocklists[@]}]='local'
blocklists[${#blocklists[@]}]='cat'

blocklists[${#blocklists[@]}]='' #end of list signal

#change to the directory that stores the local blocklist file(s)
cd /root/scripts/firewall/
#cd /home/neutrak/programs/ipfire_scripts/firewall/ #testing

#for a stand-alone machine, add rules to the filter table
#default if no table is passed to iptables
#table='filter'

#for a router or firewall, add rules in the nat table
#table='nat'

case "$1" in
	load)
		#update local blocklist file
		./get_blocked_domains.sh > 'domain_blocklist' && gzip -f 'domain_blocklist'
		n=0
		while [ "${blocklists[$n]}" != '' ]
		do
			echo "Loading ${blocklists[$(($n+1))]}..."
			
			#remove the set from the active list in the kernel
			iptables -D INPUT -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
			iptables -D FORWARD -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
			iptables -D FORWARD -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			iptables -D OUTPUT -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			
			#for ipfire the custom* names are used instead
			iptables -D CUSTOMINPUT -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
			iptables -D CUSTOMFORWARD -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
			iptables -D CUSTOMFORWARD -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			iptables -D CUSTOMOUTPUT -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			
#			iptables -D OVPNINPUT -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
#			iptables -D OVPNOUTPUT -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			
			#for nat as well
#			iptables -t nat -D PREROUTING -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
#			iptables -t nat -D OUTPUT -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			
			#load the blocklist into an IPSet called whatever is specified by the array entry
			if [ "${blocklists[$(($n+3))]}" == 'online' ]
			then
				curl -L "${blocklists[$n]}" | gunzip -c | bash -c "${blocklists[$(($n+4))]}" | pg2ipset.py - - "${blocklists[$(($n+2))]}" | ipset -
			elif [ "${blocklists[$(($n+3))]}" == 'local' ]
			then
				zcat "${blocklists[$n]}" | bash -c "${blocklists[$(($n+4))]}" | pg2ipset.py - - "${blocklists[$(($n+2))]}" | ipset -
			fi
			
			#add iptables rules
			#This will cause anything a blocked IP sends you to mysteriously vanish as if you weren't even there,
			#while any of your programs which try to connect to a blocked IP are informed it won't work.
			#Adjust to your liking, as always; if you have ipt_TARPIT, this would be a great place.
			iptables -I INPUT -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
			iptables -I FORWARD -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
			iptables -I FORWARD -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			iptables -I OUTPUT -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			
			#for ipfire the custom* names are used instead
			iptables -I CUSTOMINPUT -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
			iptables -I CUSTOMFORWARD -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
			iptables -I CUSTOMFORWARD -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			iptables -I CUSTOMOUTPUT -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			
#			iptables -I OVPNINPUT -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
#			iptables -I OVPNOUTPUT -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			
			#for nat as well
#			iptables -t nat -I PREROUTING -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
#			iptables -t nat -I OUTPUT -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT

			
			n=$(($n+5))
		done
		;;
		
	update)
		#update local blocklist file
		./get_blocked_domains.sh > 'domain_blocklist' && gzip -f 'domain_blocklist'
		n=0
		while [ "${blocklists[$n]}" != '' ]
		do
			echo "Updating ${blocklists[$(($n+1))]}..."
			
			#loads the blocklist to "LEVEL1-NEW", and swap it with "LEVEL1" once it’s done loading
			#then deletes the old list, leaving no unprotected gap in the middle.
			if [ "${blocklists[$(($n+3))]}" == 'online' ]
			then
				curl -L "${blocklists[$n]}" | gunzip -c | bash -c "${blocklists[$(($n+4))]}" | pg2ipset.py - - "${blocklists[$(($n+2))]}"-NEW | ipset -
			elif [ "${blocklists[$(($n+3))]}" == 'local' ]
			then
				zcat "${blocklists[$n]}" | bash -c "${blocklists[$(($n+4))]}" | pg2ipset.py - - "${blocklists[$(($n+2))]}"-NEW | ipset -
			fi
			ipset -W "${blocklists[$(($n+2))]}" "${blocklists[$(($n+2))]}"-NEW
			ipset -X "${blocklists[$(($n+2))]}"-NEW
			
			n=$(($n+5))
		done
		;;
	
	stop)
		n=0
		while [ "${blocklists[$n]}" != '' ]
		do
			echo "Stopping ${blocklists[$(($n+1))]}..."
			
			#remove the set from the active list in the kernel
			iptables -D INPUT -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
			iptables -D FORWARD -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
			iptables -D FORWARD -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			iptables -D OUTPUT -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			
			#for ipfire the custom* names are used instead
			iptables -D CUSTOMINPUT -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
			iptables -D CUSTOMFORWARD -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
			iptables -D CUSTOMFORWARD -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			iptables -D CUSTOMOUTPUT -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			
#			iptables -D OVPNINPUT -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
#			iptables -D OVPNOUTPUT -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT

			#for nat as well
#			iptables -t nat -D PREROUTING -m set --match-set "${blocklists[$(($n+2))]}" src -j DROP
#			iptables -t nat -D OUTPUT -m set --match-set "${blocklists[$(($n+2))]}" dst -j REJECT
			
			#destroy the set
			ipset -X "${blocklists[$(($n+2))]}"
			
			n=$(($n+5))
		done
		;;
	
	download)
		mkdir "blocklists"
		n=0
		while [ "${blocklists[$n]}" != '' ]
		do
			echo "Downloading ${blocklists[$(($n+1))]}..."
			
			#download the file into the blocklists directory
			if [ "${blocklists[$(($n+3))]}" == 'online' ]
			then
				wget -O "blocklists/${blocklists[$(($n+1))]}.gz" "${blocklists[$n]}"
			elif [ "${blocklists[$(($n+3))]}" == 'local' ]
			then
				echo "Warning: ${blocklists[$(($n+1))]} is from a local file, and will not be downloaded"
			fi
			
			n=$(($n+5))
		done
		;;
	
	*)
		echo "Usage: $0 <load|update|stop|download>"
		;;
esac


