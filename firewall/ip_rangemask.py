#!/usr/bin/python2.7

#calculate the number of bits that are shared
#in the prefix of the given two bytes
def shared_bits_in_byte(byte_a,byte_b):
	shared_bits=0
	#check each bit, and see if it is shared
	#stop on a non-shared bit
	for bit in [7,6,5,4,3,2,1,0]:
		if(((byte_a>>bit)&1) != ((byte_b>>bit)&1)):
			break
		else:
			shared_bits+=1
	return shared_bits

#get a minimal definition for the given range
#in the formation first/bit_count
def ip_rangemask(first,last):
	#how many prefix bits are shared by the first and last addresses
	shared_bits=0
	
	first_nums=first.split('.')
	last_nums=last.split('.')
	assert(len(first_nums)==4)
	assert(len(last_nums)==4)
	
	#for each byte of the ip address
	for n in xrange(0,len(first_nums)):
		#if the bytes are equal between first and last
		#then all bits in this byte are shared
		if(first_nums[n]==last_nums[n]):
			shared_bits+=8
		#otherwise between 8 and 0 bits of this byte are shared
		else:
			first_val=int(first_nums[n])
			last_val=int(last_nums[n])
			shared_bits+=shared_bits_in_byte(first_val,last_val)
			break
	
	return first+'/'+str(shared_bits)

#determine if for two ranges one is a subset of the other
#returns True/False status, and the value of the larger range
def shared_range(range_a,range_b):
	if(range_a.find('/')==-1 or range_b.find('/')==-1):
		return (False, range_a)
#	if(range_a==range_b):
#		return (True, range_a)
	range_a_bits=int(range_a.split('/')[1])
	range_b_bits=int(range_b.split('/')[1])
	
	range_a_ar=range_a.split('/')[0].split('.')
	range_b_ar=range_b.split('/')[0].split('.')
	assert(len(range_a_ar)==4)
	assert(len(range_b_ar)==4)
	
	#determine which range is larger
	max_range_bits=range_a_bits
	max_range_ar=range_a_ar
	#counterintuitively, the largest range has the SMALLEST prefix
	if(range_b_bits<range_a_bits):
		max_range_bits=range_b_bits
		max_range_ar=range_b_ar
	
	#compare up to max_range_bits
	#if all bits up to that point are equal,
	#than the smaller range is a subset of the larger range
	#otherwise the ranges each contain some unique elements
	shared_bits=0
	for n in xrange(0,len(max_range_ar)):
		#if the max has already been hit, then stop looking
		#the smaller range was a subset of the larger range
		if(shared_bits>=max_range_bits):
			break
		if(range_a_ar[n]==range_b_ar[n]):
			shared_bits+=8
		else:
			a_val=int(range_a_ar[n])
			b_val=int(range_b_ar[n])
			shared_bits+=shared_bits_in_byte(a_val,b_val)
			break
	
	return (shared_bits>=max_range_bits, '.'.join(max_range_ar)+'/'+str(max_range_bits))

#find among a list of ranges which are needed to identify the set as a whole
#this means removing subsets from the list and returning the remainder
#this algorithm has a roughly O(n^2) runtime, so watch out for large data sets
#(by pre-sorting I think I can probably improve that)
def shared_range_list(range_list,prog_output=False):
	range_list=sorted(range_list,key=lambda mask: int(mask.split('.')[0]))
	
	#the return list, which will contain a minimal subset of the range_list
	ret_list=[]
	
	#for unique IPs add a /32 mask for uniform handling later
	for n in xrange(0,len(range_list)):
		if(range_list[n].find('/')==-1):
			range_list[n]+='/32'
	
	#for each IP mask
	for n in xrange(0,len(range_list)):
		range_def=range_list[n].split('/')
		range_def_bits=int(range_def[1])
#		range_def_ar=range_def[0].split('.')
		
		#if this is a subset of any existing ip masks, then skip it
		is_subset=False
		for n2 in xrange(0,len(ret_list)):
			range_cmp_def=range_list[n2].split('/')
			range_cmp_def_bits=int(range_cmp_def[1])
#			range_cmp_def_ar=range_cmp_def[0].split('.')
			
			#if the inner loop range is smaller than the outer loop range
			#then the outer cannot possibly be a subset of the inner
			#(smaller prefix == larger range)
			#since this is the stored loop, this condition should always be false here
#			if(range_cmp_def_bits>range_def_bits):
#				continue

			shared,lg_range=shared_range(range_list[n],ret_list[n2])
			if(shared and (lg_range!=range_list[n] or range_cmp_def_bits==range_def_bits)):
				is_subset=True
				break
		if(is_subset):
			continue
		
		#for each IP mask /after/ the current, check if current is a subset
		for n2 in xrange(n+1,len(range_list)):
			range_cmp_def=range_list[n2].split('/')
			range_cmp_def_bits=int(range_cmp_def[1])
#			range_cmp_def_ar=range_cmp_def[0].split('.')
			
			#if the inner loop range is smaller than the outer loop range
			#then the outer cannot possibly be a subset of the inner
			#(smaller prefix == larger range)
			if(range_cmp_def_bits>range_def_bits):
				continue
			
			shared,lg_range=shared_range(range_list[n],range_list[n2])
			#if the first mask is a subset of the second, then skip this
			#when we get to the second in the outer loop, it will be added
			#thus including the first mask
			if(shared and (lg_range!=range_list[n] or range_cmp_def_bits==range_def_bits)):
				is_subset=True
				break
		#if this range is the largest range among shared ranges,
		#or is unique and not part of a shared range
		#then append the current mask
		#since it contains unique elements not found elsewhere
		if(not is_subset):
			ret_list.append(range_list[n])
			if(prog_output):
				if(range_list[n].endswith('/32')):
					print(range_list[n][0:len(ret_list[n])-len('/32')])
				else:
					print(range_list[n])
	
	#strip extraneous /32 suffixes
	for n in xrange(0,len(ret_list)):
		if(ret_list[n].endswith('/32')):
			ret_list[n]=ret_list[n][0:len(ret_list[n])-len('/32')]
	
	#return minimal unique definition for the entire range of ips given
	return ret_list

if(__name__=='__main__'):
	import sys
	if(len(sys.argv)<3):
		print('Usage: '+sys.argv[0]+' <start ip> <end ip>')
		print('Usage: '+sys.argv[0]+' --subset <start ip range> <end ip range>')
		print('Usage: '+sys.argv[0]+' --uniq <ip ranges>')
	elif(sys.argv[1]=='--uniq'):
		range_list=[]
		for n in xrange(2,len(sys.argv)):
			range_list.append(sys.argv[n])
		range_list=shared_range_list(range_list,prog_output=True)
#		for subnet in range_list:
#			print(subnet)
	elif(sys.argv[1]=='--subset'):
		if(len(sys.argv)<4):
			print('Usage: '+sys.argv[0]+' --subset <start ip range> <end ip range>')
		else:
			subset,large_range=shared_range(sys.argv[2],sys.argv[3])
			if(subset):
				print(large_range)
			else:
				print(sys.argv[2])
				print(sys.argv[3])
	else:
		print(ip_rangemask(sys.argv[1],sys.argv[2]))

