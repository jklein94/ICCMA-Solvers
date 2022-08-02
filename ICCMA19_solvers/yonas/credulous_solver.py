import mcts_generator
from mcts_generator import randomPolicyWithTaboo, randomPolicyWithTabooAndEarlyTermination, randomPolicyForCredulousAcceptance,randomPolicyForCredulousAcceptanceStable, ArgumentationEnumeratorStateMC
import multiprocessing as mp
from copy import deepcopy
from mcts2 import mcts
import sys
from grounded_solver import solve
import numpy as np

TIME_LIMIT = 1200000
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

	rollout_policy = randomPolicyForCredulousAcceptance
	if problem == "DC-ST":
		rollout_policy = randomPolicyForCredulousAcceptanceStable
	elif problem == "DC-PR":
		preferred_flag == True

	

	initialState = ArgumentationEnumeratorStateMC(file_path, [], preferred_flag, stable_flag)
	in_ids = solve(initialState.adj_matrix)
	initialState.labelling[in_ids] = LEGAL_IN
	states = [deepcopy(initialState) for i in range(mp.cpu_count())]

	#heuristics
	arg_id = initialState.nodeid_to_idx[additional]
	attacking_args = np.nonzero(initialState.adj_matrix[:,arg_id])[0]

	if additional in [initialState.idx_to_nodeid[i] for i in in_ids]:
		print("YES")
		exit()

	for idx in attacking_args:
		if idx in in_ids:
			print("NO")
			exit()

	mcts = mcts(timeLimit=TIME_LIMIT - OVERHEAD,rolloutPolicy=rollout_policy, explorationConstant = -3)

	manager = mp.Manager()
	shared_frameworks = manager.list()
	processes = []
	for i in range(mp.cpu_count()-1):
	    p = mp.Process(target=mcts.search, args=(states[i],shared_frameworks,additional,))
	    processes.append(p)
	    p.start()

	for process in processes:
	    process.join()

