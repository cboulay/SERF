from EeratAPI.API import *
from OnlineAPIExtension import *
from sqlalchemy import desc
self = Session.query(Subject).all()[0]


def _recent_stream_for_dir(dir, maxdate=None):
        dir=os.path.abspath(dir)
        files=FileReader.ListDatFiles(d=dir)
        #The returned list is in ascending order, assume the last is most recent
        best_stream = None
        for fn in files:
            temp_stream = FileReader.bcistream(fn)
            temp_date = datetime.datetime.fromtimestamp(temp_stream.datestamp)
            if not best_stream\
                or (maxdate and temp_date<=maxdate)\
                or (not maxdate and temp_date > datetime.datetime.fromtimestamp(best_stream.datestamp)):
                best_stream=temp_stream
        return best_stream

dir_stub=Session.query(System).filter(System.Name=="bci_dat_dir").one().Value
mvic_dir=dir_stub + '/' + self.Name + '/' + self.Name + '888/'
period = None
bci_stream=_recent_stream_for_dir(mvic_dir,maxdate=period.EndTime if period else None)
sig,states=bci_stream.decode(nsamp='all', states=['FBValue'])
