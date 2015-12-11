import metaknowledge as mk
import networkx as Nx
import os
os.chdir("/Users/Yanish/Documents/Fall_2015/Integ_475/final/Integ475Final")

RC = mk.RecordCollection ("data/")
coAuth = RC.coAuthNetwork()
Net = RC.coCiteNetwork()
Dat = RC.writeCSV(fname = "data/dat.csv")

Net=mk.drop_edges(Net, minWeight=3)
Nx.write_graphml(Net, "networks/net.graphml")
