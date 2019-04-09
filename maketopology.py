#Generate graph with watts-strogatz algorithm (outputs high cc random graph), then outputs vhd topology file for use with project to stdout

import random, math, sys
from math import floor
class Node:
	def __init__(self, id=0):
		self.id = 0
		self.successors = []

	def degree(self):
		return len(self.successors)

class WSGraph:
	def __init__(self, Nodecount = 128, Degree = 3):
		#Make nodes
		self.Nodes = []
		for id in range(Nodecount):
			self.Nodes.append(Node(id))

		#Make ring-edges (D per node)
		for id in range(Nodecount):
			for x in range(1, Degree+1):
				self.Nodes[id].successors.append(self.Nodes[(id+x) % Nodecount])
		return

	def N(self):
		return len(self.Nodes)

#Randomize some edges
	def randomize(self, p=0.05):
		N = self.N()
		random.seed()

		for id in range(N):
			Node = self.Nodes[id]
			#with probability p, replace the target of each outgoing edge with a random target
			for s in range(len(Node.successors)):
				if (p < random.random()):
					Replacement = self.Nodes[int(floor(random.random() * N))]
					while ((Replacement in Node.successors) or Replacement == Node):
						Replacement = self.Nodes[int(floor(random.random() * N))]
					Node.successors[s] = Replacement
		return

#Invert all edges
	def invert(self):
		N = self.N()
		Pred=[]
		for i in range(N):
			cn = self.Nodes[i]
			Pred.append([])
			Pred[i] = [p for p in self.Nodes if (cn in p.successors)] 
		
		for i in range(N):
			self.Nodes[i].successors = Pred[i]

	def adjacency(self):
		N = self.N()
		print "(",
		for i in range(N):
			print "(",
			for j in range(N):
				if self.Nodes[j] in self.Nodes[i].successors:
					print "true",
				else:
					print "false",
				if j < N-1:
					print ",",
			print ")", 
			if i < N-1:
				print ",",
		print ")",

	def edges(self):
		result = []
		N = self.N()
		for j in range(N):
			for i in range(N):
				if self.Nodes[j] in self.Nodes[i].successors:
					result.append((i,j))
		return result

#Generate random graph and output adjacency matrix
if len(sys.argv) < 4:
	print("Generates a Watts-Strogatz random graph with N nodes, Degree Deg, and edge randomization probability p\n")
	print("Usage: python maketopology.py N Deg p > myTopologyFileName.vhd")
	print("Include generated vhd file while compiling project")

else:
	N = int(sys.argv[1])
	D = int(sys.argv[2])
	p = float(sys.argv[3])

	N_Bits = int(math.ceil(math.log(N,2)))
	S_Bits = int(math.ceil(math.log(D+2,2)))

	G = WSGraph(N, D)
	G.randomize(p)
	G.invert()

	print("library IEEE;\nuse IEEE.std_logic_1164.all;\nuse IEEE.numeric_std.all;\nuse work.neuralnets.all;\npackage topology is\n\tconstant N : Integer :=" + str(N) +";\n\tconstant N_Bits : Integer :=" + str(N_Bits) +";\n\tconstant D : Integer := " + str(D+1) + ";\n\tconstant S_Bits : Integer := "+str(S_Bits)+";\n\t--the topology is defined here\n\tconstant Adj : ADJACENCY_MATRIX := ")
	G.adjacency()
	print(";\n")
	print("end topology;\n")



