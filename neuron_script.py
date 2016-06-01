import catmaid # pretty stupid name
import json
import os

sep = os.sep
base_dir = "Z:"+ sep + "Data" + sep + "simulation" + sep + "tracing"
skeleton_dir = os.path.join(base_dir, 'skeletons')

# Make our base directory
if not os.path.exists(base_dir):
    os.makedirs(base_dir)

# Make a directory for our skeletons, nested one deep in our base directory.
# We'll be saving individual skeletons as JSON files here.
if not os.path.exists(skeleton_dir):
	os.mkdir(skeleton_dir)

# Get the connection to our Postgre database
thesource = catmaid.get_source()

# Save out all the annotations for our skeletons
annotations_dict = thesource._skel_source.fetchJSON('http://catmaid2.hms.harvard.edu/6/neuron/table/query-by-annotations')
with open(os.path.join(base_dir, 'annotations.json'), 'w') as f:
	json.dump(annotations_dict, f)

# Pull connectors for all neurons in the project and save them to a json file called connectors
connectors = catmaid.algorithms.population.network.find_conns(thesource.all_neurons_iter())
with open(os.path.join(base_dir,'connectors.json'), 'w') as f:
	json.dump(connectors, f)

# For every skeleton, get a dictionary representation, and save it to a JSON file
# in our skeletons directory
skeleton_ids = thesource.skeleton_ids()
for skeleton_id in skeleton_ids:
    this_skeleton = thesource.get_skeleton(skeleton_id)
    with open(os.path.join(skeleton_dir, "%d.json" % skeleton_id), "w") as f:
    	json.dump(this_skeleton, f)
