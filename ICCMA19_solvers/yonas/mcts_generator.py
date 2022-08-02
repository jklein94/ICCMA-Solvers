from __future__ import division

from copy import deepcopy, copy
from mcts2 import mcts, a2_expansion
from functools import reduce
import operator
import numpy as np
import networkx as nx
import random
from numba import jit
import numba.types
import multiprocessing as mp
import time
import argumentationenumerator_a2
import sys

global_action_cache = {}

LEGAL_OUT     = 0
ILLEGAL_OUT   = 1
LEGAL_UNDEC   = 2
ILLEGAL_UNDEC = 3
LEGAL_IN      = 4
ILLEGAL_IN    = 5

IN            = 101
OUT           = 102
UNDEC         = 103

class ArgumentationEnumeratorStateMC():
    def __init__(self, path_to_framework = "", taboo_list = [], preferred_flag = False, stable_flag = False):
        #load graph
        args, atts = self.parseTGF(path_to_framework)
        G = nx.DiGraph()
        G.add_nodes_from(args)

        #get adjacency matrix
        for att in atts:
            G.add_edge(att[0], att[1])
        self.adj_matrix = nx.to_numpy_array(G)
        self.n = self.adj_matrix.shape[0]

        #set up ravelled version with attackers and attacks
        self.attacks_array   = np.full(((self.n + 1) * self.n),-1, dtype=np.int16)
        self.attackers_array = np.full(((self.n + 1) * self.n),-1, dtype=np.int16)
        for i in range(self.n): #rows
            cur_attack    = 1
            cur_attackers = 1
            for j in range(self.n): #columns
                cur_base = (i * self.n)
                if (self.adj_matrix[i,j] == 1):
                    self.attacks_array[cur_base + cur_attack] = j
                    cur_attack += 1 

                if (self.adj_matrix[j,i] == 1):
                    self.attackers_array[cur_base + cur_attackers] = j
                    cur_attackers += 1
            self.attacks_array[cur_base]   = cur_attack - 1
            self.attackers_array[cur_base] = cur_attackers - 1

        #set up name indexing
        self.idx_to_nodeid = {}
        self.nodeid_to_idx = {}
        for i,n in enumerate(G.nodes):
            self.idx_to_nodeid[i] = n
            self.nodeid_to_idx[n] = i

        #set up initial labelling
        self.labelling = np.zeros((self.adj_matrix.shape[0]), dtype=np.int8) #OUT,IN,LEGAL
        self.labelling[:] = ILLEGAL_IN
        self.nextMoves = self.markLegalIn()
        
        #set up taboo list
        self.taboo_list = set()


    def getPossibleActions(self):
        #if there are superillegal IN nodes return list of those
        #otherwise return illegal IN nodes
        #label all nodes legally/illegally IN/OUT/UNDEC
      
        #check which illegally IN nodes are also attacked by a legally IN or UNDEC node 
        #that consitutes list of superillegal IN nodes
        #return possibleActions(self.labelling, self.adj_matrix)
        return self.nextMoves
    
    def markLegalIn(self):
        return legalMarking(self.labelling, self.attackers_array, self.attacks_array, self.n)

    def takeAction(self, action, act_seq_id = None):
        #print("ACTION",action)
        
        #do transition
        s = copy(self)
        unique_key = act_seq_id
        if unique_key in global_action_cache:
            #print("hitting cache")
            s.labelling = np.copy(global_action_cache[unique_key][0]) 
            s.nextMoves = np.copy(global_action_cache[unique_key][1])
        else:
            s.labelling = getSLabelling(self.labelling, self.attackers_array, self.attacks_array, action, self.n)
            s.nextMoves = s.markLegalIn()
            #print(s.nextMoves)
            global_action_cache[unique_key] = (np.copy(s.labelling), np.copy(s.nextMoves))

        #print(s.labelling[action])
        return s


    def isTerminal(self):
        return terminalState(self.labelling)


    def getReward(self):
        #if the state is terminal return reward otherwise 0
        if self.isTerminal() == False:
            return 0
        #if the found labelling is in the taboo list return 0
        if self.stringRepresentation() in self.taboo_list:
            #print("TABOO")
            return 0

        #if the preferred flag is on and the found labelling is a subset of one in the taboo_list return 0

        #otherwise return cardinality of the found extension
        #print("RW",str(10* len(self.getExtension())))
        #print(self.stringRepresentation())
        return 10 * len(self.getExtension())

    def getExtension(self):
        #return the elements labelled IN
        return computeExtension(self.labelling, self.idx_to_nodeid)
        

    def stringRepresentation(self):
        l =self.getExtension()
        l.sort()
        return ','.join(l)


    #Utility function for parsing TGF
    def parseTGF(self, file):
        f = open(file, 'r')
        #\
        args = []
        atts = []
        hash_seen = False
        for idx, line in enumerate(f):

            line = line.strip()
            if line == '#':
                hash_seen = True
                continue
            if not hash_seen:
                args.append(line)
            else:
                atts.append(line.split(' '))
        
        return args, atts

@jit(nopython=True)
def get_attackers(attackers_array, i, arr_size):
    base_num      = (i * arr_size)
    num_attackers = attackers_array[base_num]
    return attackers_array[base_num+1:base_num+1+num_attackers] 

@jit(nopython=True)
def get_attacks(attacks_array, i, arr_size):
    base_num      = (i * arr_size)
    num_attacks = attacks_array[base_num]
    return attacks_array[base_num+1:base_num+1+num_attacks]

@jit(nopython=True)
def num_label(labelling, label_type):
    if label_type == IN:
        return np.sum(labelling == LEGAL_IN) + np.sum(labelling == ILLEGAL_IN)
    if label_type == UNDEC:
        return np.sum(labelling == LEGAL_UNDEC) + np.sum(labelling == ILLEGAL_UNDEC)
    if label_type == OUT:
        return np.sum(labelling == LEGAL_OUT) + np.sum(labelling == ILLEGAL_OUT)        

@jit(nopython=True)
def is_out(labelling, arg):
    return (labelling[arg] == LEGAL_OUT or labelling[arg] == ILLEGAL_OUT)

@jit(nopython=True)
def is_undec(labelling, arg):
    return (labelling[arg] == LEGAL_UNDEC or labelling[arg] == ILLEGAL_UNDEC)

@jit(nopython=True)
def is_in(labelling, arg):
    return (labelling[arg] == LEGAL_IN or labelling[arg] == ILLEGAL_IN)

@jit(nopython=True)
def getSLabelling(labelling, attackers_array, attacks_array, action, arr_size):
    #print("Entering getSLabelling")
    slabelling = np.copy(labelling)
    #print(s.labelling[action])
    #flip node from IN to OUT
    slabelling[action] = LEGAL_OUT

    #test action
    attacking_ids = get_attackers(attackers_array, action, arr_size) 
    #print(idx)
    #print(self.labelling[idx, 0])
    arr = slabelling[attacking_ids]    
    if num_label(arr, IN) == 0:
        slabelling[action] = LEGAL_UNDEC #legal


    #find nodes that are now illegally OUT
    ids_to_test = get_attacks(attacks_array, action, arr_size)
    #print(ids_to_test)
    #ids = np.nonzero(adj_matrix[action,:])[0]
    #print(ids)
    #mark as UNDEC 
    for idx in ids_to_test:
        attacking_ids = get_attackers(attackers_array, idx, arr_size)
        #print(attacking_ids)
        #att_ids = np.nonzero(adj_matrix[:,idx])[0]
        #print(att_ids)
        #print(idx)
        #print(self.labelling[idx, 0])
        if is_out(slabelling,idx) == True: #OUT
            arr = slabelling[attacking_ids]
            if num_label(arr, IN) == 0:
                #print("labelling legal undec")
                slabelling[idx] = LEGAL_UNDEC #legal

    return slabelling

@jit(nopython=True)
def terminalState(labelling):
    #print("Entering getTerminalState")
    illegal_in_nodes =  np.nonzero(labelling == ILLEGAL_IN)[0]
    #print("IDS", illegal_in_nodes)
    #print("acts", self.getPossibleActions())
    #check if any arguments are illegally IN
    if len(illegal_in_nodes) > 0:
        #if yes then False
        return False
    else:
        #if no then True
        #print(self.labelling)
        return True

def computeExtension(labelling, idx_to_nodeid):
    elms = np.nonzero(labelling == LEGAL_IN)[0]
    return [idx_to_nodeid[arg] for arg in elms]

@jit(nopython=True)
def legalMarking(labelling : int, attackers_array, attacks_array, arr_size):
    #print("Entering legalMarking")
    illegal_in_nodes = []
    super_illegal_in_nodes = []

    for i in range(arr_size):
        attacking_ids = get_attackers(attackers_array, i, arr_size) 
        if is_in(labelling,i) == True: #IN

            if num_label(labelling[attacking_ids], OUT)  == len(attacking_ids):
                labelling[i] = LEGAL_IN #legal
            else:
                labelling[i] = ILLEGAL_IN #illegal
                illegal_in_nodes.append(i)
                for j in attacking_ids:
                    if ( labelling[j] == LEGAL_IN or labelling[j] == LEGAL_UNDEC):
                        super_illegal_in_nodes.append(i)
                        break

    #return illegal_in_nodes
    #print("i",illegal_in_nodes)
    #print("si",super_illegal_in_nodes)
    if len(super_illegal_in_nodes) > 0:
        return super_illegal_in_nodes
    else:
        return illegal_in_nodes


#@jit(nopython=True)
'''

    illegal_in_nodes = []
    super_illegal_in_nodes = []
    for i in ids_of_in_nodes:
        if labelling[i,2] == 0:
            illegal_in_nodes.append(i)
            attacking_ids = np.nonzero(adj_matrix[:,i])[0]
            for j in attacking_ids:
                if (labelling[j,1] == 1 or (labelling[j,1] == 0 and labelling[j,0] == 0)) and labelling[j,2] == 1:
                    super_illegal_in_nodes.append(i)
                    break

    #print(self.labelling[illegal_nodes])
    #print(self.labelling[np.nonzero(self.labelling[illegal_nodes,1])[0]])
    if len(super_illegal_in_nodes) > 0:
        return super_illegal_in_nodes
    else:
        return illegal_in_nodes'''

def act(state, action_name):
    state.getPossibleActions()
    idx = state.nodeid_to_idx[action_name]
    print(idx)
    return state.takeAction(idx) 

def fixup_extension(labelling, adj_matrix, illegal_undecs):
    ids_of_in_nodes = np.nonzero(labelling[:,1])[0]
    #print("in", ids_of_in_nodes)
    nodes_in_nodes_attack  = np.unique(np.nonzero(adj_matrix[ids_of_in_nodes,:])[1])
    #print("att", nodes_in_nodes_attack)
    partially_protected    = np.unique(np.nonzero(adj_matrix[nodes_in_nodes_attack,:])[1])
    #print("prot", partially_protected)
    for n in partially_protected:
        if not n in ids_of_in_nodes:
            #print("n",n)
            attacking_ids = np.nonzero(adj_matrix[:,n])[0]
            if all([ a in nodes_in_nodes_attack for a in attacking_ids]):
                print("adding", n)
                labelling[n,1] = 1 #add to extension

def randomPolicyWithTaboo(state, shared_frameworks = None, argument = None):
    act_seq = 'A'
    while not state.isTerminal():
        try:
            action = random.choice(state.getPossibleActions())
        except IndexError:
            raise Exception("Non-terminal state has no possible actions: " + str(state))
        state = state.takeAction(action,  act_seq)
        act_seq += str(action)
    extension = state.stringRepresentation()    
    if extension not in state.taboo_list:
        state.taboo_list.add(extension)
        illegal_undecs = find_illegal_undecs(state.labelling, state.attackers_array, state.attacks_array, state.n)
        #print("i1", illegal_undecs, extension)
        if len(illegal_undecs) == 0:
            #print("HERE")
            extension = state.stringRepresentation()
            if shared_frameworks != None:
                    shared_frameworks.append(extension)
            state.taboo_list.add(extension)
            #print(state.stringRepresentation())

def randomPolicyWithTabooStable(state, shared_frameworks = None, argument = None):
    act_seq = 'A'
    while not state.isTerminal():
        try:
            action = random.choice(state.getPossibleActions())
        except IndexError:
            raise Exception("Non-terminal state has no possible actions: " + str(state))
        state = state.takeAction(action,  act_seq)
        act_seq += str(action)
    
    extension = state.stringRepresentation()    
    
    if extension not in state.taboo_list:
        state.taboo_list.add(extension)
        undec_no = np.sum(state.labelling == LEGAL_UNDEC) + np.sum(state.labelling == ILLEGAL_UNDEC) 
        if undec_no == 0:
            #print("HERE")
            #print(state.labelling)
            extension = state.stringRepresentation()
            if shared_frameworks != None:
                shared_frameworks.append(extension)
            state.taboo_list.add(extension)
            #print(state.stringRepresentation())

def randomPolicyWithTabooAndEarlyTerminationStable(state, shared_frameworks = None, argument = None):
    act_seq = 'A'
    while not state.isTerminal():
        try:
            action = random.choice(state.getPossibleActions())
        except IndexError:
            raise Exception("Non-terminal state has no possible actions: " + str(state))
        state = state.takeAction(action,  act_seq)
        act_seq += str(action)
        
    extension = state.stringRepresentation()    
    if extension not in state.taboo_list:
        state.taboo_list.add(extension)
        undec_no = np.sum(state.labelling == LEGAL_UNDEC) + np.sum(state.labelling == ILLEGAL_UNDEC) 
        if undec_no == 0:
            extension = state.stringRepresentation()
            if shared_frameworks != None:
                shared_frameworks.append(extension)
            
            state.taboo_list.add(extension)
            
            if shared_frameworks [0] != "DONE":    
                print("[{}]".format(extension))
                shared_frameworks[0] = "DONE"

        state.taboo_list.add(state.stringRepresentation())
        #print(state.stringRepresentation())    
    
    reward = state.getReward()
    #print( reward)
    
    return reward


def randomPolicyWithTabooAndEarlyTermination(state, shared_frameworks = None, argument = None):
    act_seq = 'A'
    while not state.isTerminal():
        try:
            action = random.choice(state.getPossibleActions())
        except IndexError:
            raise Exception("Non-terminal state has no possible actions: " + str(state))
        state = state.takeAction(action,  act_seq)
        act_seq += str(action)
    if state.stringRepresentation() not in state.taboo_list:
        if shared_frameworks != None:
            shared_frameworks.append(state.stringRepresentation())

        if shared_frameworks [0] != "DONE":
            print("[{}]".format(state.stringRepresentation()))
            shared_frameworks[0] = "DONE"

        state.taboo_list.add(state.stringRepresentation())
        #print(state.stringRepresentation())    
    
    reward = state.getReward()
    #print( reward)
    
    return reward

def randomPolicyForCredulousAcceptanceStable(state, shared_frameworks = None, argument = None):
    act_seq = 'A'
    while not state.isTerminal():
        try:
            action = random.choice(state.getPossibleActions())
        except IndexError:
            raise Exception("Non-terminal state has no possible actions: " + str(state))
        state = state.takeAction(action,  act_seq)
        act_seq += str(action)
    if state.stringRepresentation() not in state.taboo_list:
        undec_no = np.sum(state.labelling == LEGAL_UNDEC) + np.sum(state.labelling == ILLEGAL_UNDEC) 
        if undec_no == 0:
            if shared_frameworks != None:
                shared_frameworks.append(state.stringRepresentation())

            if shared_frameworks [0] != "DONE":
                if state.stringRepresentation().find( argument + ","  ) > 0  or state.stringRepresentation().find( "," + argument ) > 0:
                    print("YES")
                    shared_frameworks[0] = "DONE"

        state.taboo_list.add(state.stringRepresentation())
        #print(state.stringRepres())    

def randomPolicyForCredulousAcceptance(state, shared_frameworks = None, argument = None):
    act_seq = 'A'        
    while not state.isTerminal():
        try:
            action = random.choice(state.getPossibleActions())
        except IndexError:
            raise Exception("Non-terminal state has no possible actions: " + str(state))
        state = state.takeAction(action,  act_seq)
        act_seq += str(action)
    
    if state.stringRepresentation() not in state.taboo_list:
        if shared_frameworks != None:
            shared_frameworks.append(state.stringRepresentation())

        if shared_frameworks [0] != "DONE":
            if state.stringRepresentation().find( argument + ","  ) > 0  or state.stringRepresentation().find( "," + argument ) > 0:
                print("YES")
                shared_frameworks[0] = "DONE"

        state.taboo_list.add(state.stringRepresentation())
        #print(state.stringRepresentation())    

def randomPolicyForSkepticalAcceptance(state, shared_frameworks = None, argument = None):
    act_seq = 'A'
    while not state.isTerminal():
        try:
            action = random.choice(state.getPossibleActions())
        except IndexError:
            raise Exception("Non-terminal state has no possible actions: " + str(state))
        state = state.takeAction(action,  act_seq)
        act_seq += str(action)
   
    if state.stringRepresentation() not in state.taboo_list:
        if shared_frameworks != None:
            shared_frameworks.append(state.stringRepresentation())

        if shared_frameworks [0] != "DONE":
            if state.stringRepresentation().find( argument + ","  ) > 0  or state.stringRepresentation().find( "," + argument ) > 0:
                print("NO")
                shared_frameworks[0] = "DONE"

        state.taboo_list.add(state.stringRepresentation())
        #print(state.stringRepresentation())    
    

    reward = state.getReward()
    #print( reward)
    
    return reward

def randomPolicyForSkepticalAcceptanceStable(state, shared_frameworks = None, argument = None):
    act_seq = 'A'
    while not state.isTerminal():
        try:
            action = random.choice(state.getPossibleActions())
        except IndexError:
            raise Exception("Non-terminal state has no possible actions: " + str(state))
        state = state.takeAction(action,  act_seq)
        act_seq += str(action)
    
    if state.stringRepresentation() not in state.taboo_list:
        undec_no = np.sum(state.labelling == LEGAL_UNDEC) + np.sum(state.labelling == ILLEGAL_UNDEC) 
        if undec_no == 0:
            if shared_frameworks != None:
                shared_frameworks.append(state.stringRepresentation())

            if shared_frameworks [0] != "DONE":
                if state.stringRepresentation().find( argument + ","  ) > 0  or state.stringRepresentation().find( "," + argument ) > 0:
                    print("NO")
                    shared_frameworks[0] = "DONE"

            state.taboo_list.add(state.stringRepresentation())
            #print(state.stringRepresentation())    
    

    reward = state.getReward()
    #print( reward)
    
    return reward

def read_solution_file(path_to_framework):
    f = open(path_to_framework, 'r')
    input = f.read()
    input = input[1:-2]
    in_arr = input.split('],')
    #print(in_arr)
    sol_arr = [s[1:].split(',') for s in in_arr]
    for arr in sol_arr:
        arr.sort() 
    return ["[" + ','.join(arr) +"]" for arr in sol_arr]

def is_subset(a, b):
    
    for elm_a in a:
        elm_match = False
        for elm_b in b:
            #print(elm_a,"-", elm_b)
            if elm_a == elm_b:
                elm_match = True
        if elm_match == False:
            return False

    return True

@jit(nopython=True)
def find_illegal_undecs(labelling, attackers_array, attacks_array, arr_size):
    illegal_undecs = []
    for i in range(arr_size):
        if is_undec(labelling,i):
            attacking_ids = get_attackers(attackers_array, i, arr_size) 
            has_undec = False
            has_in    = False
            for att in attacking_ids:
                if labelling[att] == LEGAL_IN:
                    has_in = True
                elif labelling[att] == LEGAL_UNDEC:
                    has_undec = True
            if not (has_undec and not has_in) and labelling[i] == LEGAL_UNDEC:
                illegal_undecs.append(i)

    return illegal_undecs

def test_labelling(labelling, adj_matrix):

    for i in range(adj_matrix.shape[0]):
        attacking_ids = np.nonzero(adj_matrix[:,i])[0]
        if labelling[i,1] == 1: #IN
            if np.sum(labelling[attacking_ids, 0]) == len(attacking_ids):
                if labelling[i,2] == 0: #legal
                    print("INCORRECTLY LABELLED ILLEGAL IN")
                    return False
            elif np.sum(labelling[attacking_ids, 0]) < len(attacking_ids):
                if labelling[i,2] == 1: #legal
                    print("INCORRECTLY LABELLED LEGAL IN")
                    return False
        elif labelling[i,0] == 1: #OUT
            out = False
            for att in attacking_ids:
                if labelling[att,1] == 1 and labelling[att,2] == 1:
                    out = True
            if out and labelling[i,2] == 0:
                print("INCORRECTLY LABELLED ILLEGAL OUT")
                return False
            elif not out and labelling[i,2] == 1:
                print("INCORRECTLY LABELLED LEGAL OUT")
                return False

        else: #UNDEC
            has_undec = False
            has_in    = False
            for att in attacking_ids:
                if labelling[att,1] == 1 and labelling[att,2] == 1:
                    has_in = True
                elif labelling[att,0] == 0 and labelling[att,1] == 0 and labelling[att,2] == 1:
                    has_undec = True
            if has_undec and not has_in and labelling[i,2] == 0:
                print("INCORRECTLY LABELLED ILLEGAL UNDEC")
                return False
            elif not (has_undec and not has_in) and labelling[i,2] == 1:
                print("has_undec", has_undec)
                print("has_in", has_in)
                print("INCORRECTLY LABELLED LEGAL UNDEC")
                return False
                

if __name__ == '__main__':  
    mp.freeze_support() 
    initialState = ArgumentationEnumeratorStateMC(sys.argv[1])
    #initialState = ArgumentationEnumeratorStateMC("./A/1/rockland-county-department-of-public-transportation_20121220_2018.gml.20.tgf")#./A/1/admbuster_1000.tgf
    #initialState = argumentationenumerator_a2.ArgumentationEnumeratorStateA2("./test_cases2/tgf/109649__200__11_12_65__35.tgf")
    #rockland-county-department-of-public-transportation_20121220_2018.gml.20.tgf
    states = [deepcopy(initialState) for i in range(mp.cpu_count())]
    rolloutPolicy =randomPolicyWithTaboo
    if sys.argv[3] == "stable":
        rolloutPolicy = randomPolicyWithTabooStable
    print("Using", mp.cpu_count(), " cpus")
    #mcts = mcts(timeLimit=600000,rolloutPolicy=argumentationenumerator_a2.randomPolicyWithTabooA2, expansionPolicy=a2_expansion, explorationConstant = 0.3)
    mcts = mcts(timeLimit=5000,rolloutPolicy=rolloutPolicy, explorationConstant = -3)
    t = time.time()  
    
    #shared_frameworks = mp.Queue()
    #shared_frameworks =[]
    processes = []
    for i in range(3):#
        manager = mp.Manager()
        shared_frameworks = manager.list()
        p = mp.Process(target=mcts.search, args=(states[i],shared_frameworks,))
        processes.append((p, shared_frameworks))
        p.start()

    solutions = set()
    for process in processes:
        print("Joining:", process)
        process[0].join()
        for sol in process[1]:
            #sol = shared_frameworks.get()
            solutions.add(sol)
            print(sol)
    print("took: ", time.time() - t)
    
    print("testing solutions:")
    
    


    base_arr = [s.split(',') for s in solutions]
    idx_to_remove = []
    #for t in range(len(base_arr)):
    #    for j in range(t+1, len(base_arr)):
    #        if is_subset(base_arr[t], base_arr[j]):
    #            idx_to_remove.append(t)

    test_arr = ["[" + ','.join(base_arr[e]) + "]" for e in range(len(base_arr)) if e not in idx_to_remove]
    answers = read_solution_file(sys.argv[2])
    
    for sol_to_test in test_arr:
        #print(sol_to_test)
        if sol_to_test in answers:
            print("Found match:", sol_to_test)
        else:
            print("Failed match:", sol_to_test)
            '''for a in answers:
                tmp_ans = a[1:-1].split(',')
                tmp_sol = sol_to_test[1:-1].split(',')
                #print(tmp_arr)
                if is_subset(tmp_sol, tmp_ans):
                    print("Subset found!")
                    print(tmp_sol)
                    print(tmp_ans)'''

    #print(answers)
    #print(str(solutions))
