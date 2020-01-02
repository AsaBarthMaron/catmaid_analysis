
import connect
import csv


# db_connection = connect.Connection()


def name_to_nid_map(db_connection=None, neuron_type = 'all'):
    if db_connection is None:
        db_connection = connect.Connection()
    annotation_list = db_connection.con.annotations()
    nids = [i[3] for i in annotation_list]
    nnames = [i[0] for i in annotation_list]
    name_to_id = dict(zip(nnames, nids))
    return name_to_id


def name_to_sid_map(db_connection=None, neuron_type = 'all'):
    if db_connection is None:
        db_connection = connect.Connection()
    name_to_nid = name_to_nid_map(db_connection)
    nid_to_sid = db_connection.con.nid_to_sid_map()
    name_to_sid = {name: nid_to_sid[nid][0] for (name, nid) in name_to_nid.iteritems()}
    return name_to_sid


def sid_to_name_map(db_connection=None, neuron_type = 'all'):
    if db_connection is None:
        db_connection = connect.Connection()
    name_to_sid = name_to_sid_map(db_connection)
    sid_to_name = {sid: name for (name, sid) in name_to_sid.iteritems()}
    return sid_to_name


def get_neurons_of_type(annotation, db_connection=None):
    """Returns a list of neuron names for neurons containing a specified annotation.
        example annotations: 'DM6 ORN', 'Left ORN', 'Right ORN', 'LN', 'DM6 PN'
    """
    if db_connection is None:
        db_connection = connect.Connection()
    annotation_list = db_connection.con.annotations()
    if annotation != 'all':
        nnames = [neuron[0] for neuron in annotation_list if annotation in [annot['name'] for annot in neuron[1]]]
    elif annotation == 'all':
        nnames = [neuron[0] for neuron in annotation_list]
    return nnames


def get_types_of_neurons(neurons, db_connection=None):
    """Takes a dictionary or list of neurons, and returns
    """
    if db_connection is None:
        db_connection = connect.Connection()
    left_orns = get_neurons_of_type('Left ORN', db_connection)
    right_orns = get_neurons_of_type('Right ORN', db_connection)
    pns = get_neurons_of_type('DM6 PN', db_connection)
    lns = get_neurons_of_type('LN', db_connection)
    plns = get_neurons_of_type('potential LN', db_connection )
    neuron_types = {'Left ORN': [], 'Right ORN': [], 'DM6 PN': [], 'LN': [], 'Other': []}
    if isinstance(neurons, dict):
        neurons = neurons.iteritems()
    for n in neurons:
        if isinstance(n, (list, tuple)):
            nname = n[0]
        elif isinstance(n, (str, unicode)):
            nname = n
        if nname in left_orns:
            neuron_types['Left ORN'].append(n)
        elif nname in right_orns:
            neuron_types['Right ORN'].append(n)
        elif nname in pns:
            neuron_types['DM6 PN'].append(n)
        else:
            neuron_types['LN'].append(n)
    return neuron_types


def load_neurons_of_type(fp):
    """Loads and returns a list of skeleton ids of a specified neuron type.
        This is for when catmaid.connection.annotations was not working properly
    """
    with open(fp, 'rb') as f:
        reader = csv.reader(f)
        for row in reader:
            sk_ids = row
    return sk_ids
