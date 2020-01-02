#!/home/asa/anaconda/bin/python

import synapse_analysis

if __name__ == "__main__":

	LNs = synapse_analysis.Population('LN DM6')
	LNs.contacts_by_type()
	LNs.barplot()
	# LNs.stacked_barplot()


