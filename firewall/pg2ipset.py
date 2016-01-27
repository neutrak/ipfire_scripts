#!/usr/bin/python2.7

#this is a port of the pg2ipset c utility
#written in python because there is a python2.7 interpreter on the box I want to run it on
#but not a c compiler (no idea /why/ not) and installing one would be a pain


import sys
import ip_rangemask
import subprocess

#get a list of ips which should /not/ be blocked even if they are included in a rule
def get_except_ips(filename='exception_domains.txt'):
	fp=open(filename,'r')
	fcontent=fp.read()
	fp.close()
	
	#for each exception domain
	except_ips=[]
	for line in fcontent.split("\n"):
		#ignore comment lines and blank lines
		if(line.startswith('#') or line==''):
			continue
		
		#get the ips associated with this domain from nslookup
		try:
			ips=subprocess.check_output('nslookup '+line+' | fgrep -A 100 answer | fgrep \'Address\' | egrep -o "([0-9]*\.)*[0-9]*"',shell=True).split("\n")
		except(subprocess.CalledProcessError):
			print('Err: IP not found for domain '+line+' (this could be a DNS or domain exception file error)')
			continue
		
		#add these to the overall exceptions
		for ip in ips:
			if(ip!=''):
				except_ips.append(ip)
	
	print('except_ips='+str(except_ips))
	
	#return all the ips associated with the domains given, sorted
	return sorted(except_ips)


#read a peerguardian-style blocklist file and transform it into an ipset filter
def pg2ipset(fin='-',fout='-',set_name='IPFILTER',verbose=False,new_cmd_syntax=True,rangemask=False,except_ips=[]):
	ifp=sys.stdin
	if(fin!='-'):
		ifp=open(fin,'r')
	
	ofp=sys.stdout
	if(fout!='-'):
		ofp=open(fout,'w')
	
	#firstly define this as a set
	if(not new_cmd_syntax):
		ofp.write('-N '+set_name+' iptreemap'+"\n")
	else:
		#destroy any existing set with this name
		ofp.write('destroy '+set_name+"\n")
		
		if(rangemask):
			#use a very large hash size to avoid collisions!
			#the larger these hashsize and maxelem numbers are the more memory it takes to operate,
			#but too small of a number will limit the ips that can be in a set
			ofp.write('create '+set_name+' hash:net hashsize 16384 maxelem 300000'+"\n")
		else:
			#use a very large hash size to avoid collisions!
			#the larger these hashsize and maxelem numbers are the more memory it takes to operate,
			#but too small of a number will limit the ips that can be in a set
			ofp.write('create '+set_name+' hash:ip hashsize 65536 maxelem 16777216'+"\n")
	#		ofp.write('create '+set_name+' hash:ip hashsize 16777216 maxelem 16777216'+"\n")
	#read each line of the input
	in_line=ifp.readline()
	while(in_line!=''):
		#tear out the range parameters from the line
		#everything before the first colon is metadata
		range_idx=in_line.find(':')
		
		#if there's a colon but it's not followed by a numeric character
		#then keep looking; this must have been part of the rule name
		while((range_idx>=0) and (range_idx+1<len(in_line))):
			if(in_line[range_idx+1].isdigit()):
				break
			#run find again for the delimeter but skip the previous instance
			range_idx=in_line.find(':',range_idx+1)
		if(range_idx>=0):
			range_idx+=1
			#range is start-end
			range_str=in_line[range_idx:]
			dash_idx=range_str.find('-')
			if(dash_idx>=0):
				#get the addresses of the start and end of the range
				from_addr=range_str[0:dash_idx]
				#newlines shouldn't be included in this
				#note that for rstrip characters are treated as an OR
				#so this strips all trailing \r OR \n chars
				to_addr=range_str[dash_idx+1:].rstrip("\r\n")
				if(not new_cmd_syntax):
					ofp.write('-A '+set_name+' '+from_addr+'-'+to_addr+"\n")
				elif(rangemask):
					rangemask_addr=ip_rangemask.ip_rangemask(from_addr,to_addr)
					#for each exception
					for ip in except_ips:
						#if this exception is part of the subnet being specified
						shared,larger=ip_rangemask.shared_range(ip+'/32',rangemask_addr)
						if(shared and (larger==rangemask_addr)):
							#TODO: split this into smaller subnets and omit the exception
							break
					#only add the rangemask if it didn't hit an exception
					#this is slightly less secure than ideal (misses some ips that should be blocked)
					#but is still way better than no blocking
					else:
						ofp.write('add '+set_name+' '+rangemask_addr+"\n")
				else:
					ofp.write('add '+set_name+' '+from_addr+'-'+to_addr+"\n")
		#skip lines that don't have delimiters,
		#they were badly formatted
		elif(verbose):
			sys.stderr.write('Badly formatted line: \"'+in_line.rstrip("\r\n")+'\"'+"\n")
		
		in_line=ifp.readline()
	#finalize the set
	if(not new_cmd_syntax):
		ofp.write('COMMIT'+"\n")
	else:
		ofp.write('quit'+"\n")
	
	
	if(ifp!=sys.stdin):
		ifp.close()
	if(ofp!=sys.stdout):
		ofp.close()

if(__name__=='__main__'):
	if((len(sys.argv)==2) and (sys.argv[1]=='-h' or sys.argv[1]=='--help')):
		print('Usage: '+sys.argv[0]+' [<input> [<output [<set name>]]]')
		print('Input should be a PeerGuardian-format blocklist (.p2p), blank or - reads from stdin')
		print('Output is suitable for ipset -R, blank or - prints to stdout')
		print('Set name is IPFILTER if not specified')
		print('Example: curl http://www.example.com/guarding.p2p | '+sys.argv[0]+' | ipset -')
		sys.exit(0)
	fin='-'
	fout='-'
	set_name='IPFILTER'
	if(len(sys.argv)>1):
		fin=sys.argv[1]
	if(len(sys.argv)>2):
		fout=sys.argv[2]
	if(len(sys.argv)>3):
		set_name=sys.argv[3]
	
	pg2ipset(fin,fout,set_name,rangemask=True,except_ips=get_except_ips())
	



