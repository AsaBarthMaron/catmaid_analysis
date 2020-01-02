
import catmaid


class Connection(object):
    def __init__(self):
        self.con = catmaid.connection.Connection('http://catmaid.hms.harvard.edu/catmaid3',
                                                     'asa_b',
                                                     'allntracing',
                                                     'wfly1_migrated')
        self.src = catmaid.source.get_source(skel_source=self.con, cache=True)