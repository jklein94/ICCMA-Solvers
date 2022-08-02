from __future__ import division

from copy import deepcopy, copy
from mcts2 import mcts, a2_expansion, standard_expansion
from functools import reduce
import operator
import numpy as np
import networkx as nx
import random
from numba import jit
import numba.types
import multiprocessing as mp
import time
import mcts_generator
global_action_cache = {}
BLANK = 0
MUST_OUT = 1
IN = 2
OUT = 3
UNDEC = 4

class ArgumentationEnumeratorStateA2():
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

        #set up name indexing
        self.idx_to_nodeid = {}
        self.nodeid_to_idx = {}
        for i,n in enumerate(G.nodes):
            self.idx_to_nodeid[i] = n
            self.nodeid_to_idx[n] = i

        #set up initial labelling
        self.BLANK = 0
        self.MUST_OUT = 1
        self.IN = 2
        self.OUT = 3
        self.UNDEC = 4
        self.labelling = np.zeros((self.adj_matrix.shape[0]), dtype=np.int8) #OUT,IN,LEGAL
        self.labelling[:] = self.BLANK
        
        #set up taboo list
        self.taboo_list = set()

        #set up number of attackers reference
        self.num_attackers = np.sum(self.adj_matrix, axis=1)

    def getPossibleActions(self):
        #if there are superillegal IN nodes return list of those
        #otherwise return illegal IN nodes
        #label all nodes legally/illegally IN/OUT/UNDEC
      
        #check which illegally IN nodes are also attacked by a legally IN or UNDEC node 
        #that consitutes list of superillegal IN nodes
        #return possibleActions(self.labelling, self.adj_matrix)

        return getActions(self.labelling, self.adj_matrix, self.num_attackers) 
    
    
    def takeAction(self, action, mode=2):
        #print("ACTION",action)
        
        #do transition
        s = copy(self)
        s.labelling = np.copy(self.labelling)

        #do transition step
        #print("TA", action)
        #print(s.labelling)
        if mode == self.IN:
            
            s.labelling[action] = self.IN
            attacks   = np.nonzero(self.adj_matrix[action,:])[0]
            attackers = np.nonzero(self.adj_matrix[:,action])[0]

            s.labelling[attacks]   = self.OUT
            attackers              = [a for a in attackers if s.labelling[a] != self.OUT]
            s.labelling[attackers] = self.MUST_OUT
        else: #UNDEC
            s.labelling[action] = self.UNDEC

        #print(s.labelling)
        return s

    def getActionCount(self, action):
        blanks = np.nonzero(self.labelling == BLANK)[0]
        return len(blanks)

    def isTerminal(self):

        must_outs = np.nonzero(self.labelling == MUST_OUT)[0]
        for m in must_outs:
            attackers = np.nonzero(self.adj_matrix[:,m])[0]
            if len(self.labelling[attackers] == self.BLANK) == 0:
                return True

        blanks = (self.labelling == self.BLANK)
        return len(self.labelling[blanks]) == 0


    def getReward(self):
        
        #if the state is terminal return reward otherwise 0
        if self.isTerminal() == False:
            return 0
        #print(self.stringRepresentation())
        must_outs = (self.labelling == self.MUST_OUT)
        if len(self.labelling[must_outs]) > 0:
            #print(-len(self.labelling[must_outs]))
            return -len(self.labelling[must_outs])

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
        
        elms = np.where(self.labelling == self.IN)[0]
        #print(elms)
        return [self.idx_to_nodeid[arg] for arg in elms]
        

    def stringRepresentation(self):
        l =self.getExtension()
        #l.sort()
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
def getActions(labelling, adj_matrix, num_attackers):
    blanks = np.nonzero(labelling == BLANK)[0]
    #return blanks
    #print(blanks)
    random.shuffle(blanks)

    filtered_blanks = []
    for b in blanks:
        attackers = np.nonzero(adj_matrix[:,b])[0]
        att = labelling[attackers]
        filtered = [a for a in att if a == OUT or a == MUST_OUT]
        if len(filtered) == len(attackers):
            filtered_blanks.append(b)
    if len(filtered_blanks) > 0:
        return filtered_blanks
    maximal_blanks = [i for i in blanks if num_attackers[i] == np.amax(num_attackers[blanks])] #np.argmax()
    #print(maximal_blanks)
    return maximal_blanks

def randomPolicyWithTabooA2(state, shared_frameworks = None):
    act_seq = []
    while not state.isTerminal():
        try:
            action = random.choice(state.getPossibleActions())
        except IndexError:
            raise Exception("Non-terminal state has no possible actions: " + str(state))
        
        if random.random() < 0.5:
            state_type  = state.IN
        else:
            state_type  = state.BLANK 
        act_seq.append(action)
        #print("RA", action)
        #print(state_type)
        state = state.takeAction(action, state_type)
        #print(state.stringRepresentation())

    #print(act_seq)
    reward = state.getReward()

    if reward  > 0:
        if shared_frameworks != None:
            shared_frameworks.append(state.stringRepresentation())
        state.taboo_list.add(state.stringRepresentation())
        print(state.stringRepresentation())
        print(reward)
    
    
    return reward


if __name__ == '__main__':  
    initialState = mcts_generator.ArgumentationEnumeratorStateMC("./A/1/admbuster_1000.tgf")#./test_cases2/tgf/109649__200__11_12_65__35.tgf
    #initialState = ArgumentationEnumeratorStateA2("./A/1/BA_120_30_3.tgf")
    #mcts = mcts(timeLimit=60000,rolloutPolicy=randomPolicyWithTabooA2, expansionPolicy=a2_expansion, explorationConstant = 0.5)
    mcts = mcts(timeLimit=60000,rolloutPolicy=mcts_generator.randomPolicyWithTaboo, expansionPolicy=standard_expansion, explorationConstant = 0.5)
    mcts.search(initialState=initialState)