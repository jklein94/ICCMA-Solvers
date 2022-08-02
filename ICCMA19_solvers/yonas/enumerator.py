import mcts_generator
from mcts_generator import randomPolicyWithTaboo, randomPolicyWithTabooAndEarlyTermination,randomPolicyWithTabooAndEarlyTerminationStable, randomPolicyWithTabooStable, ArgumentationEnumeratorStateMC
import multiprocessing as mp
from copy import deepcopy
from mcts2 import mcts
import sys
from grounded_solver import solve

TIME_LIMIT = 600000
OVERHEAD   = 60000
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
	file_path  = sys.argv[1]
	problem    = sys.argv[2]
	additional = ""
	if len(sys.argv) > 3:
	    additional = sys.argv[3]
	sys.stderr = DevNull()
	rollout_policy = randomPolicyWithTaboo

	if problem == "EE-ST" or problem == "EE-PR":
		rollout_policy = randomPolicyWithTabooStable

	if problem == "SE-PR" or problem == "SE-ST":
		rollout_policy = randomPolicyWithTabooAndEarlyTerminationStable

	mp.freeze_support() 
	initialState = ArgumentationEnumeratorStateMC(file_path, [])
	in_ids = solve(initialState.adj_matrix)
	initialState.labelling[in_ids] = LEGAL_IN
	states = [deepcopy(initialState) for i in range(mp.cpu_count())]

	mcts = mcts(timeLimit=TIME_LIMIT - OVERHEAD,rolloutPolicy=rollout_policy, explorationConstant = -3)

	manager = mp.Manager()
	shared_frameworks = manager.list()
	processes = []
	for i in range(mp.cpu_count()-1):
	    p = mp.Process(target=mcts.search, args=(states[i],shared_frameworks,))
	    processes.append(p)
	    p.start()

	for process in processes:
	    process.join()

	solutions = set()
	for sol in shared_frameworks:
	    solutions.add(sol)

	if problem == "EE-PR" or problem == "EE-ST" or problem == "EE-CO":
	    print ("[")
	    for s in solutions:
	    	print("\t[{}]".format(s)) 
	    print ("]")




