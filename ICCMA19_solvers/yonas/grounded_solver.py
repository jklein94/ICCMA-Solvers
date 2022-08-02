import networkx as nx
import numpy as np
import sys
from numba import jit

#Utility function for parsing TGF
def parseTGF(file):
    f = open(file, 'r')
    
    args = []
    atts = []
    hash_seen = False
    for idx, line in enumerate(f):
        #print('id={},val={}'.format(idx,line))
        line = line.strip()
        if line == '#':
            hash_seen = True
            continue
        if not hash_seen:
            args.append(line)
        else:
            atts.append(line.split(' '))
    
    return args, atts
BLANK  = 0
IN     = 1
OUT    = 2

@jit(nopython=True)
def solve(adj_matrix):
    
    #set up labelling
    labelling = np.zeros((adj_matrix.shape[0]), np.int8)

    #find all unattacked arguments
    a = np.sum(adj_matrix, axis=0) == 0
    unattacked_args = np.nonzero(a)[0]
    #print(unattacked_args  )
    #label them in
    labelling[unattacked_args] = IN
    cascade = True
    while cascade:
        #find all outgoing attacks
        #print(np.nonzero(adj_matrix[unattacked_args,:]))
        new_attacks = np.unique(np.nonzero(adj_matrix[unattacked_args,:])[1])
        #print("NEW",new_attacks)
        new_attacks_l = np.array([i for i in new_attacks if labelling[i] != OUT])
        
        #label those out
        labelling[new_attacks_l] = OUT

        #find any arguments that have all attackers labelled out
        affected_idx = np.unique(np.nonzero(adj_matrix[new_attacks_l,:])[1])
        all_outs = []
        for idx in affected_idx:
            incoming_attacks = np.nonzero(adj_matrix[:,idx])[0]
            if(np.sum(labelling[incoming_attacks] == OUT) == len(incoming_attacks)):
                all_outs.append(idx)

        #label those in
        if len(all_outs) > 0:
            labelling[np.array(all_outs)] = IN
            unattacked_args = np.array(all_outs)
        else:
            cascade = False
    
    #print grounded extension     
    in_nodes = np.nonzero(labelling == IN)[0]
    return in_nodes

class DevNull:
    def write(self, msg):
        pass


if __name__=="__main__":
    #read file
    sys.stderr = DevNull()
    file_path  = sys.argv[1]
    problem    = sys.argv[2]
    additional = ""
    if len(sys.argv) > 3:
        additional = sys.argv[3]

    arguments, atts = parseTGF(file_path)

    #Create graph
    G = nx.DiGraph()
    G.add_nodes_from(arguments)

    for att in atts:
        G.add_edge(att[0], att[1])
        
    adj_matrix = nx.to_numpy_array(G)
    
    idx_to_nodeid = []
    nodeid_to_idx = dict()
    for i,n in enumerate(G.nodes):
        idx_to_nodeid.append(n)
        nodeid_to_idx[n] = i


    in_nodes = solve(adj_matrix)

    in_nodes_with_name = []
    for node in in_nodes:
        in_nodes_with_name.append(idx_to_nodeid[node])
    
    if problem == "DC-GR" or problem == "DS-CO":
        for node2 in in_nodes_with_name:
            if additional == node2:
                print ("YES")
                sys.exit()
        print ("NO")
    elif problem == "EE-GR" or problem == "SE-CO" or problem == "SE-GR":
        print ("[" + ','.join(in_nodes_with_name) + "]")
