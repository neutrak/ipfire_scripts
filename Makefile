install:
	@if [ -d /root/programs/ipfire_scripts ]; then echo "/root/programs/ipfire_scripts already exists..." ; else mkdir -p /root/programs/ipfire_scripts/ ; fi
	cp -r firewall/ /root/programs/ipfire_scripts/
	@if [ -a /usr/bin/pg2ipset.py ]; then echo "/usr/bin/pg2ipset.py already exists..." ; else ln -s /root/programs/ipfire_scripts/firewall/pg2ipset.py /usr/bin/pg2ipset.py ; fi
	@echo "Info: To modify firewall blocklists, edit /root/programs/ipfire_scripts/firewall/load_blocklists.sh"
	@echo "Info: To manually whitelist or blacklist domains, edit /root/programs/ipfire_scripts/firewall/exception_domains.txt or /root/programs/ipfire_scripts/firewall/blocked_domains.txt respectively"
	cp -r openvpn/ /root/programs/ipfire_scripts/
	@echo "Info: For openvpn you will need to put an auth.txt file in /root/programs/ipfire_scripts/openvpn/"
	@echo "Info: For openvpn you will need to put .ovpn files in /etc/openvpn/"
	
	@echo "Info: For startup or automatic updating see the fcrontab and rclocal example files and update your fcrontab and /etc/sysconfig/rc.local files as desired"

uninstall:
	#rm -r /root/programs/ipfire_scripts/firewall/
	#rm -r /root/programs/ipfire_scripts/openvpn/
	rm /usr/bin/pg2ipset.py

