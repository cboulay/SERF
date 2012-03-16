#http://www.sqlobject.org/SQLObject.html
#cd D:\Tools/EERAT/SQL_database/
#run Eerat_sqlobject.py
from sqlobject import *
from sqlobject.sqlbuilder import *
import MySQLdb
import numpy

connection = connectionForURI("mysql://root@localhost/eerat")
sqlhub.processConnection = connection

class SubjectType(SQLObject):
	class sqlmeta:
		fromDatabase = True
		idName = 'subject_type_id'
	Name = StringCol(alternateID=True, length=45)
	subjects = MultipleJoin('Subject') #one-to-many
		
class Subject(SQLObject):
	class sqlmeta:
		fromDatabase = True
		idName = 'subject_id'
	subject_type = ForeignKey('SubjectType')
	Name = StringCol(alternateID=True, length=45)
	data = MultipleJoin('Datum')

class Datum(SQLObject):
	class sqlmeta:
		fromDatabase = True
		idName = 'datum_id'
	subject = ForeignKey('Subject')
	#TODO: evoked <--> erp
	def _get_erp(self):
		erp={}
		#We need a list of channels and a list of time stamps.
		query = 'SELECT channel_id, t_ms+t_us/1000 as x, uV as y FROM evoked WHERE datum_id=' + str(self.id) + 	' ORDER BY channel_id, x'
		data = numpy.asarray(connection.queryAll(query))
		#Assume each channel is represented an equal number of times.
		chan_list = numpy.unique(data[:,0]).astype(int)
		n_chans=len(chan_list)
		n_samps = len(data)/n_chans
		data_out=numpy.reshape(data[:,2],[n_samps,n_chans]).astype(float)#Needs testing
		samp_times=data[0:n_samps,1].astype(float)
		erp['chan_ids']=chan_list
		erp['data']=numpy.vstack([samp_times,data_out.T])
		return erp
		
	def _set_erp(self, erp):
		#Expects erp dict with chan_ids and data, data is a numpy array of MxN where M is 1+n_chans and N is n_samples
		#n_chans,n_samps=numpy.shape(data_in)
		#n_chans = n_chans - 1
		chan_list=erp['chan_ids']
		sample_times=erp['data'][0,:]
		data_in=erp['data'][1:,:]
		connection.query('BEGIN')
		#query = 'INSERT INTO evoked (datum_id, channel_id, t_ms, t_us, uV) VALUES'
		for index, y in numpy.ndenumerate(data_in):
			query = 'INSERT INTO evoked (datum_id, channel_id, t_ms, t_us, uV) VALUES' + ' (' + str(self.id) + ',' + str(chan_list[index[0]]) + ',ROUND(' + str(sample_times[index[1]]) + ',0),ROUND(1000.0*(' + str(sample_times[index[1]]) + '%1),0),' + str(y) + ') ON DUPLICATE KEY UPDATE uV=VALUES(uV)'
			connection.query(query)
		connection.query('COMMIT')
		#query = query[:-1] + ' ON DUPLICATE KEY UPDATE uV=VALUES(uV)'
		#connection.query(query)
		#	query = query + ' (' + str(self.id) + ',' + str(chan_list[index[0]]) + ',ROUND(' + str(sample_times[index[1]]) + ',0),ROUND(1000.0*(' + str(sample_times[index[1]]) + '%1),0),' + str(y) + '),'
		
my_sub=Subject.selectBy(Name='CHAD_TEST').getOne()
my_trial=my_sub.data[1]
xvec = numpy.arange(-250,250)
sig = 100*numpy.random.ranf((2,500))
sig_xy = numpy.vstack([xvec,sig])
new_data={}
new_data['chan_ids']=range(1,3)
new_data['data']=sig_xy
#my_trial.erp=new_data