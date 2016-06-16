#!/usr/bin/env python

'''quick_adj.py: super quick script for fetching and saving adjacency matrix 
    and skeleton IDs/neuron names.'''
    
__author__   = "Asa Barth-Maron"

import connect
import numpy as np
import json


db_connection = connect.Connection()

adj = dict()
adj_m, adj['skids'] = db_connection.con.adjacency_matrix()
adj_m = np.array(adj_m, int)

# Go from sk_ids to neuron ids, necessary for name lookup in wiring_diagram
sid_to_nid = db_connection.con.sid_to_nid_map()
adj['nids'] = [sid_to_nid[sid] for sid in adj['skids']]

# Use wiring_diagram to get names from nids
annot_diag = db_connection.con.annotation_diagram()
nids = [i['id'] for i in annot_diag['nodes']]
nnames = [i['name'] for i in annot_diag['nodes']]
nid_to_nname = dict(zip(nids, nnames))

# Add neuron names to adj dict
adj['nnames'] = [nid_to_nname[nid] for nid in adj['nids']] 
# adj_nnames = adj['nnames']
# adj_nids = adj['nids']
# adj_skids = adj['skids']

with open('adjacency_matrix.json', 'w') as outfile:
    json.dump(adj, outfile)
sio.savemat('adj_m.mat', {'adj_m':adj_m})