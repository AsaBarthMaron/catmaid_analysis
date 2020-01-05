import connect
import neuron_tools
import numpy as np
import bargraph
import stacked

DB_CONNECTION = connect.Connection()
print "Fetching adjacency matrix"
ADJ = dict()
ADJ['matrix'], ADJ['sk_ids'] = DB_CONNECTION.con.adjacency_matrix()
ADJ['matrix'] = np.array(ADJ['matrix'], int)
NAME_TO_SID = neuron_tools.name_to_sid_map(DB_CONNECTION)
SID_TO_NAME = neuron_tools.sid_to_name_map(DB_CONNECTION)
print "Initialization complete"


class Neuron(object):
    """
    Neuron object holds synapse information and does analyses on their connections
    """
    def __init__(self, sid):
        self.sid = sid
        self.adj_index = ADJ['sk_ids'].index(self.sid)
        pre_slice = ADJ['matrix'][:, self.adj_index]
        post_slice = ADJ['matrix'][self.adj_index, :]
        self.contacts = dict()
        self.contacts['pre'] = self.get_contacts(pre_slice, ADJ['sk_ids'], post_slice)
        self.contacts['post'] = self.get_contacts(post_slice, ADJ['sk_ids'], pre_slice)
        self.get_contact_types()
        self.total_contacts = {'pre': dict(), 'post': dict()}
        self.get_mean_contacts('pre')
        self.get_mean_contacts('post')

    def get_contacts(self, adj_slice, sk_ids, other_slice=None):
        if other_slice is not None:
            # contact_ind = ((adj_slice + other_slice) > 1).nonzero()[0]
            contact_ind = (adj_slice + other_slice).nonzero()[0]
            self.ncontacts = contact_ind.shape[0]
        else:
            contact_ind = (adj_slice > 1).nonzero()[0]

        contacts = [sk_ids[i] for i in contact_ind]
        contacts = [SID_TO_NAME[sid] for sid in contacts]
        contacts = dict(zip(contacts, [adj_slice[i] for i in contact_ind]))
        return contacts

    def get_contact_types(self):
        self.contacts['pre'] = neuron_tools.get_types_of_neurons(self.contacts['pre'], DB_CONNECTION)
        self.contacts['post'] = neuron_tools.get_types_of_neurons(self.contacts['post'], DB_CONNECTION)

    def get_mean_contacts(self, io):
        for key, value in self.contacts[io].iteritems():

            if self.contacts[io][key] == []:
                self.total_contacts[io][key] = 0
            else:
                contacts = [partner[1] for partner in value]
                self.total_contacts[io][key] = reduce(lambda x, y: x+y, contacts)

    def mat_contacts(self):
        self.synmat = []
        self.contact_types = []
        for key, value in sorted(self.total_contacts['pre'].items()):
            self.synmat.append([value, self.total_contacts['post'][key]])
            self.contact_types.append(key)
        self.synmat = np.array(self.synmat)
        self.synmat = self.synmat.transpose()

        i_lorn = self.contact_types.index('Left ORN')
        i_rorn = self.contact_types.index('Right ORN')
        i_adj_lorn = i_lorn + 1
        self.synmat[:, [i_rorn, i_adj_lorn]] = self.synmat[:, [i_adj_lorn, i_rorn]]
        temp = str(self.contact_types[i_adj_lorn])
        self.contact_types[i_adj_lorn] = str(self.contact_types[i_rorn])
        self.contact_types[i_rorn] = temp

    def list_contacts(self):
        sortedkeys = [key for key in sorted(self.contacts['pre'].iterkeys())]
        i_lorn = sortedkeys.index('Left ORN')
        i_rorn = sortedkeys.index('Right ORN')
        i_adj_lorn = i_lorn + 1
        temp = str(sortedkeys[i_adj_lorn])
        sortedkeys[i_adj_lorn] = str(sortedkeys[i_rorn])
        sortedkeys[i_rorn] = temp
        pp_contacts = np.zeros((self.ncontacts, 3))
        i_all_partners = 0
        for i, key in enumerate(sortedkeys):
            for i_partner, partner in enumerate(self.contacts['pre'][key]):
                partner_data = np.array([partner[1], self.contacts['post'][key][i_partner][1], i])
                pp_contacts[i_all_partners, :] = partner_data
                i_all_partners += 1
        self.pp_contacts = (pp_contacts, sortedkeys, ('Presynaptic', 'Postsynaptic', 'key_index'))


    def barplot(self):
        self.mat_contacts()
        bargraph(self.synmat, blabels=self.contact_types, glabels=["Presynaptic", "Postsynaptic"])


class Population(object):
    """
    Population object holds references to neurons of a type
    """

    def __init__(self, annotation):
        """"Gets Neuron objects for all neurons of a particular annotation"""
        self.type = annotation
        self.nnames = neuron_tools.get_neurons_of_type(annotation, DB_CONNECTION)
        self.neurons = dict()
        print "Fetching neurons"
        for nname in self.nnames:
            self.neurons[nname] = Neuron(NAME_TO_SID[nname])
        print "Neurons fetched: %s" % self.nnames

    # def get_subset_contacts(self, subset):
    #
    #     for nname in subset:
    #         self.neurons[nname].get_contact_types()
    #         self.neurons[nname].total_contacts = dict()
    #         self.neurons[nname].get_mean_contacts('pre')
    #         self.neurons[nname].get_mean_contacts('post')

    def contacts_by_type(self):
        """Returns a tuple containing population contacts along with labels for each dimension
            1st dimension - pre/postsynaptic
            2nd dimension - contact partner type
            3rd dimension - neuron
        """
        for nname, neuron in self.neurons.iteritems():
            self.neurons[nname].mat_contacts()
        contact_types = self.neurons[self.nnames[0]].contact_types
        cmat_size = (2, len(contact_types), len(self.nnames))  # Hard coded! 2 is pre/post
        contacts = np.zeros(cmat_size)
        nnames = []
        for i_neuron, neuron in enumerate(sorted(self.neurons.items())):
            contacts[:, :, i_neuron] = neuron[1].synmat
            nnames.append(neuron[0])
        self.contacts_of_type = (contacts,
                                 ('Presynaptic', 'Postsynaptic'),
                                 contact_types,
                                 tuple(nnames))


    def barplot(self):
        contacts = self.contacts_of_type[0]
        glabels = self.contacts_of_type[1]
        blabels = self.contacts_of_type[2]
        plabels = self.contacts_of_type[3]
        bargraph.bargraph(contacts, blabels, glabels, plabels)

    def stacked_barplot(self):
        contacts = self.contacts_of_type[0]
        glabels = self.contacts_of_type[1]
        blabels = self.contacts_of_type[2]
        plabels = self.contacts_of_type[3]
        stacked.bargraph(contacts)

    def hist2d(self):
        contacts = self.contacts_of_type[0]
        plabels = self.contacts_of_type[3]