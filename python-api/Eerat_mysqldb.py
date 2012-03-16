#http://www.python.org/dev/peps/pep-0249/
#cd D:\Tools/EERAT/SQL_database/
#run Eerat_test.py

import MySQLdb

class Subject(Object):
	def __init__(self, subject_id=None, subject_type_id=None, Name=None, DateOfBirth=None, IsMale=None, Weight=None, Notes=None, species_type=None):
		self.subject_id = subject_id
		self.subject_type_id=subject_type_id
		self.Name=Name
		self.DateOfBirth=DateOfBirth
		self.IsMale=IsMale
		self.Weight=Weight
		self.Notes=Notes
		self.species_type=species_type
	
conn = MySQLdb.connect(host="localhost",user="root",db="eerat")
#.close(), .commit(), .rollback(), .cursor()
#.cursor has
	#.description
	#.rowcount
	#.callproc(procname[,parameters])
	#.close()
	#.execute(operation[,parameters])
	#.executemany(operation,seq_of_parameters)
	#.fetchone()
	#.fetchmany([size=cursor.arraysize])
	#.fetchall()
	#.nextset()
	#.arraysize
	#.setinputsizes(sizes)
	#.setoutputsize(size[,column])
cursor.execute ("SELECT subject_id, subject_type_id, Name, DateOfBirth, IsMale, Weight, Notes, species_type FROM subject")
temp_r = cursor.fetchall()
for ss in temp_r:
	new_subject = Subject(subject_id=ss[0], subject_type_id=ss[1], Name=ss[2], DateOfBirth=ss[3], IsMale=ss[4], Weight=ss[5], Notes=ss[6], species_type=ss[7])