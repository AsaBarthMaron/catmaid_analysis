import catmaid_tools
import connect
import neuron_tools

if __name__ == "__main__":

	db_connection = connect.Connection()

	annotations = catmaid_tools.query_annotations('LN', db_connection)
	annotations += catmaid_tools.query_annotations('Ln', db_connection)
	annotations += catmaid_tools.query_annotations('lN', db_connection)
	annotations += catmaid_tools.query_annotations('ln', db_connection)
	annotations = set(annotations)

	nnames = []
	for an in annotations:
	    nnames += neuron_tools.get_neurons_of_type(an, db_connection)

	nnames = set(nnames)
	f = open('/home/asa/Documents/LNs.txt', 'w')
	for n in nnames:
	  f.write("%s\n" % n)
	f.close()