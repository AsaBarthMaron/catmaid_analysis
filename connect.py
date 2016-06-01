__author__ = 'asa'

import catmaid


class Connection(object):
    def __init__(self):
        self.con = catmaid.connection.Connection('http://catmaid2.hms.harvard.edu',
                                                     'asa_b',
                                                     'allntracing',
                                                     'wfly1')
        self.src = catmaid.source.get_source(skel_source=self.con, cache=True)