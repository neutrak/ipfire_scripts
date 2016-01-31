install:
	mkdir /root/scripts/
	cp -r firewall/ /root/scripts/
	ln -s /root/scripts/firewall/pg2ipset.py /usr/bin/pg2ipset.py
	echo "Info: To modify firewall blocklists, edit /root/scripts/firewall/load_blocklists.sh"
	echo "Info: To manually whitelist or blacklist domains, edit /root/scripts/firewall/exception_domains.txt or /root/scripts/firewall/blocked_domains.txt respectively"
	cp -r openvpn/ /root/scripts/
	echo "Info: For openvpn you will need to put an auth.txt file in /root/scripts/openvpn/"
	echo "Info: For openvpn you will need to put .ovpn files in /etc/openvpn/"
	
	echo "Info: For startup or automatic updating see the fcrontab and rclocal example files and update your fcrontab and /etc/sysconfig/rc.local files as desired"

uninstall:
	rm -r /root/scripts/firewall/
	rm -r /root/scripts/openvpn/
	rm /usr/bin/pg2ipset.py

