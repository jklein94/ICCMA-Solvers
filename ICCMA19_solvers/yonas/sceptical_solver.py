import mcts_generator
from mcts_generator import randomPolicyWithTaboo, randomPolicyWithTabooAndEarlyTermination, randomPolicyForSkepticalAcceptance, randomPolicyForSkepticalAcceptanceStable, randomPolicyForCredulousAcceptance, ArgumentationEnumeratorStateMC
import multiprocessing as mp
from copy import deepcopy
from mcts2 import mcts
import sys
import numpy as np
import math 
from grounded_solver import solve

TIME_LIMIT = 610000
OVERHEAD   = 10000
LEGAL_OUT     = 0
ILLEGAL_OUT   = 1
LEGAL_UNDEC   = 2
ILLEGAL_UNDEC = 3
LEGAL_IN      = 4
ILLEGAL_IN    = 5
class DevNull:
    def write(self, msg):
        pass

if __name__ == '__main__':  
	mp.freeze_support() 
	sys.stderr = DevNull()
	file_path  = sys.argv[1]
	problem    = sys.argv[2]
	additional = ""
	if len(sys.argv) > 3:
	    additional = sys.argv[3]
	else:
		exit()

	stable_flag = False
	preferred_flag = False
	rollout_policy = randomPolicyForSkepticalAcceptance

	if problem == "DS-ST":
		stable_flag = randomPolicyForSkepticalAcceptanceStable
	elif problem == "DS-PR":
		preferred_flag == True

	rollout_policy = randomPolicyForSkepticalAcceptance
	initialState = ArgumentationEnumeratorStateMC(file_path, [], preferred_flag, stable_flag)
	in_ids = solve(initialState.adj_matrix)
	initialState.labelling[in_ids] = LEGAL_IN


	n_cpus = mp.cpu_count() -1
	time_to_allocate = TIME_LIMIT - OVERHEAD
	arg_id = initialState.nodeid_to_idx[additional]
	attacking_args = np.nonzero(initialState.adj_matrix[:,arg_id])[0]
	attacking_arg_ids = [initialState.idx_to_nodeid[n] for n in attacking_args]
	n_attacking_args = len(attacking_args)

	#heuristics
	if additional in [initialState.idx_to_nodeid[i] for i in in_ids]:
		print("YES")
		exit()

	for idx in attacking_args:
		if idx in in_ids:
			print("NO")
			exit()
	
	#time math
	time_per_round = time_to_allocate
	if n_attacking_args > 0:
		cpu_to_arg_factor = float(n_cpus / n_attacking_args)
	else:
		print("YES")
		exit()

	rounds_needed = 1
	#print(n_attacking_args)


	if cpu_to_arg_factor < 1: # split across multiple rounds
		#print(cpu_to_arg_factor)
		rounds_needed  =  math.ceil(n_attacking_args / n_cpus)
		time_per_round =  time_to_allocate / rounds_needed

	#print(rounds_needed, time_per_round)
	states = [deepcopy(initialState) for i in range(mp.cpu_count())]

	mcts = mcts(timeLimit=time_per_round,rolloutPolicy=rollout_policy, explorationConstant = -3)
	args_covered = 0
	manager = mp.Manager()
	shared_frameworks = manager.list()

	for i in range(rounds_needed):
		processes = []
		#print("round",i)
		for j in range(args_covered, ((i+1) * n_cpus) ):
			if j < n_attacking_args:
			    p = mp.Process(target=mcts.search, args=(states[i],shared_frameworks,attacking_arg_ids[args_covered],))
			    processes.append(p)
			    p.start()
			    args_covered += 1

		for process in processes:
		    process.join()

		if shared_frameworks[0] == "DONE":
			break

