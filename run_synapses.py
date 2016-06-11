#!/home/asa/anaconda/bin/python
__author__ = 'asa'

import synapse_analysis

LNs = synapse_analysis.Population('LN DM6')
LNs.contacts_by_type()
LNs.barplot()
# LNs.stacked_barplot()


