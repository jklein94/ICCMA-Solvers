from __future__ import division

import time
import math
import random
from numba import jit


def randomPolicy(state):
    while not state.isTerminal():
        try:
            action = random.choice(state.getPossibleActions())
        except IndexError:
            raise Exception("Non-terminal state has no possible actions: " + str(state))
        state = state.takeAction(action)
    return state.getReward()


class treeNode():
    def __init__(self, state, parent):
        self.state = state
        self.isTerminal = state.isTerminal()
        self.isFullyExpanded = self.isTerminal
        self.parent = parent
        self.numVisits = 0
        self.totalReward = 0
        self.rewardSquared = 0
        self.children = {}

def standard_expansion(node):
    actions = node.state.getPossibleActions()
    for action in actions:
        if action not in node.children.keys():
            newNode = treeNode(node.state.takeAction(action), node)
            node.children[action] = newNode
            if len(actions) == len(node.children):
                node.isFullyExpanded = True
            return [newNode]

    raise Exception("Should never reach here")

def a2_expansion(node):
    actions = node.state.getPossibleActions()
    for action in actions:
        if str(action) + "_IN" not in node.children.keys():
            newNode1 = treeNode(node.state.takeAction(action, node.state.IN), node)
            newNode2 = treeNode(node.state.takeAction(action, node.state.UNDEC), node)
            key1 = str(action) + "_IN"
            key2 = str(action) + "_UNDEC"
            node.children[key1] = newNode1
            node.children[key2] = newNode2
            #print(node.state.getActionCount(action))
            #print(len(node.children))
            if 2* len(actions) == len(node.children):
                #print("here")
                node.isFullyExpanded = True
            return [newNode1, newNode2]

    raise Exception("Should never reach here")

class mcts():
    def __init__(self, timeLimit=None, iterationLimit=None, explorationConstant=1 / math.sqrt(2),
                 rolloutPolicy=randomPolicy, expansionPolicy=standard_expansion):

        if timeLimit != None:
            if iterationLimit != None:
                raise ValueError("Cannot have both a time limit and an iteration limit")
            # time taken for each MCTS search in milliseconds
            self.timeLimit = timeLimit
            self.limitType = 'time'
        else:
            if iterationLimit == None:
                raise ValueError("Must have either a time limit or an iteration limit")
            # number of iterations of the search
            if iterationLimit < 1:
                raise ValueError("Iteration limit must be greater than one")
            self.searchLimit = iterationLimit
            self.limitType = 'iterations'
        self.explorationConstant = explorationConstant
        self.rollout = rolloutPolicy
        self.expand = expansionPolicy

    def search(self, initialState, shared_frameworks = None, argument = None):
        self.root = treeNode(initialState, None)
        self.n_rounds = 0
        if self.limitType == 'time':
            timeLimit = time.time() + self.timeLimit / 1000
            while time.time() < timeLimit:
                self.executeRound(shared_frameworks, argument)
                self.n_rounds += 1
                if len(shared_frameworks) > 0 and shared_frameworks[0] == "DONE":
                    return
        else:
            for i in range(self.searchLimit):
                self.executeRound(shared_frameworks, argument)
                self.n_rounds += 1
                if len(shared_frameworks) > 0 and shared_frameworks[0] == "DONE":
                    return
            #print(self.n_rounds)

        #bestChild = self.getBestChild(self.root, 0)
        #print("Rounds completed:",self.n_rounds)
        #if bestChild != None:
        #    return self.getAction(self.root, bestChild)
        #else:
        #exit()
        return None

    def executeRound(self, shared_frameworks = None, argument = None):
        nodes = self.selectNode(self.root)
        
        for node in nodes:
            reward = self.rollout(node.state, shared_frameworks, argument)
            self.backpropogate(node, reward)


    def selectNode(self, node):
        while not node.isTerminal:
            if node.isFullyExpanded:
                node = self.getBestChild(node, self.explorationConstant)
            else:
                return self.expand(node)
        return [node]

    

    def backpropogate(self, node, reward):
        while node is not None:
            node.numVisits += 1
            if reward == None: #DEBUG THIS
                reward = 0
            node.totalReward += reward
            node.rewardSquared += (reward * reward)
            node = node.parent

    def getBestChild(self, node, explorationValue):
        return retBestChild(node, explorationValue)

    def getAction(self, root, bestChild):
        for action, node in root.children.items():
            if node is bestChild:
                return action

@jit(nopython=False)
def retBestChild(node, explorationValue):
    bestValue = float("-inf")
    bestNodes = []
    for child in node.children.values():
        nodeValue = child.totalReward / child.numVisits + explorationValue * math.sqrt(
            2 * math.log(node.numVisits) / child.numVisits)
        D = 10000
        modification = math.sqrt((child.rewardSquared - child.numVisits * (child.totalReward/child.numVisits)**2 + D)/child.numVisits) #SP-MCTS modification
        nodeValue += modification
        if nodeValue > bestValue:
            bestValue = nodeValue
            bestNodes = [child]
        elif nodeValue == bestValue:
            bestNodes.append(child)
    #print("Best", bestNodes)

    return random.choice(bestNodes)