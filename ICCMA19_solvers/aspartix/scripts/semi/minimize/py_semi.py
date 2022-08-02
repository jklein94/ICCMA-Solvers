# call python3 py_semi.py tmp.txt

import os
import sys

e=os.path.dirname(os.path.abspath(__file__))
try:
	fi = open(e+'/'+sys.argv[1],'r')
	setlist=[]
	models=[]
	for line in fi:
		tmp=line.split()
		models.append([x for x in tmp if x.startswith('in')])
		setlist.append([x for x in tmp if x.startswith('undec')])
	fi.close()
	
	test=list(filter(lambda f:not any(set(f)>set(g) for g in setlist), setlist))
	new_list=[1 if x in test else 0 for x in setlist]
	
#	c=0
	for i in range(len(new_list)):
		if new_list[i]:
#			c=c+1
#			print('Answer',c,'\n',*models[i])
			print(*models[i])
	print("FIN")
except FileNotFoundError:
	print("tmp-file not found")
