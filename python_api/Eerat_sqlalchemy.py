#Provide an interface to the database without requiring any SqlAlchemy like expressions.
#To use:
#	cd D:\Tools/EERAT/SQL_database/
#	from Eerat_sqlalchemy import *
#	s = Session()
#	subjects=s.query(Subject).all()

# SQLAlchemy learning.
#Use ORM to build classes
#http://docs.sqlalchemy.org/en/latest/orm/tutorial.html
#OR
#Use SQL Expression language to lightly wrap databases.
#http://docs.sqlalchemy.org/en/latest/core/tutorial.html
import numpy
from operator import attrgetter
from sqlalchemy import *
from sqlalchemy.orm import *
from sqlalchemy.ext.declarative import declarative_base, declared_attr
from sqlalchemy.ext.associationproxy import association_proxy
from sqlalchemy.orm.collections import attribute_mapped_collection
import feature_functions

#The following gets or creates a model into the db but also persists it.
#Only use this method when we can describe all arguments.
def get_or_create(model, **kwargs):
	#http://stackoverflow.com/questions/2546207/does-sqlalchemy-have-an-equivalent-of-djangos-get-or-create
	session=Session()
	instance = session.query(model).filter_by(**kwargs).first()
	if instance: return instance
	else:
		instance = model(**kwargs)
		session.add(instance)
		session.flush()
		return instance

class MyBase(object):
	_mapper_args = []
	__mapper_args__= {'always_refresh': True}
	__table_args__ = {'mysql_engine': 'InnoDB'}
	
	@declared_attr
	def __tablename__(cls):
		return cls.__name__.lower()
		
#	@declared_attr
#	def __table__(cls):
#		return Table(cls.__tablename__, metadata, autoload=True, autoload_with=engine)

	@classmethod
	def __mapper_cls__(cls, *args, **kw):
		cls._mapper_args.append((args, kw))
		
	@classmethod
	def prepare(cls, engine):
		for args, kw in cls._mapper_args:
			klass = args[0]
			klass.__table__ = table = Table(klass.__tablename__, cls.metadata, 
								extend_existing=True, autoload_replace=False,
								autoload=True, autoload_with=engine)
			klass.__mapper__ = mapper(klass, table, **kw)

Base = declarative_base(cls=MyBase)#Create declarative base class also inheriting base defined above.

	#	For composite proxying to dictionary-based collections.
	#	http://docs.sqlalchemy.org/en/latest/orm/extensions/associationproxy.html#composite-association-proxies
	#
	#class Parent(Base): ...
	#	children = association_proxy('middle_table_name','middle_class_value_attribute',
	#				creator = lambda k, v: MiddleClass(middle_class_key_attribute=k, middle_class_value_attribute=v))
	#NOTE that the middle_class_key_attribute and middle_class_value_attribute can themselves be proxies
	#
	#class MiddleClass(Base): ...
	#	parent = relationship(Parent, backref=backref("middle_table_name",
	#				collection_class = attribute_mapped_collection("middle_class_key_attribute"),
	#				cascade="all, delete-orphan"))
	#	child  = relationship("Child")
	#	middle_class_key_attribute = association_proxy('child_relationship_name', 'child_class_key_attribute')
	#	middle_class_value_attribute = association_proxy('child_relationship_name', 'child_class_value_attribute')

	# Define many-to-many relationships in the association tables using cascades in the backrefs
	# Define one-to-many relationships in the parent (one) table using direct cascades.
		
class Detail_type(Base):
	datum_types 		= association_proxy("datum_type_has_detail_type","datum_type")
	subject_types 		= association_proxy("subject_type_has_detail_type","subject_type")
	
class Feature_type(Base):
	datum_types 		= association_proxy("datum_type_has_feature_type","datum_type")

class Datum(Base):
	#subject = relationship(Subject, backref=backref("data", cascade="all, delete-orphan"))
	#datum_type = relationship(Datum_type, backref=backref("data", cascade="all, delete-orphan"))
	#_store				= relationship(Datum_store, uselist=False, backref="datum")
	type_name			= association_proxy("datum_type","Name") #A shortcut to the type name.
	erp 				= association_proxy("_store","erp")
	x_vec				= association_proxy("_store","x_vec")
	n_channels 			= association_proxy("_store","n_channels")
	n_samples 			= association_proxy("_store","n_samples")
	channel_labels 		= association_proxy("_store","channel_labels")
	feature_values 		= association_proxy("datum_feature_value","Value",
							creator = lambda k, v: Datum_feature_value(feature_name=k, Value=v))
	detail_values 		= association_proxy("datum_detail_value","Value",
							creator = lambda k, v: Datum_detail_value(detail_name=k, Value=v))
	def _get_store(self):
		temp_x=self.x_vec
		temp_data=self.erp
		if temp_x and temp_data:
			temp_x=numpy.frombuffer(temp_x, dtype=float)
			temp_x.flags.writeable=True
			temp_data=numpy.frombuffer(temp_data, dtype=float)
			temp_data.flags.writeable=True
			temp_data=temp_data.reshape([self.n_channels,self.n_samples])
		return {'x_vec':temp_x, 'data':temp_data, 'channel_labels':self.channel_labels}
			
	def _set_store(self, dict_in):
		#Take a dict input and set the storage item
		#ERP from numpyarray of [chans x samps] to database blob
		self.n_channels,self.n_samples=numpy.shape(dict_in['data'])
		self.x_vec=dict_in['x_vec'].tostring() #always float?
		self.erp=dict_in['data'].tostring() #always float?
		#self.erp=numpy.getbuffer(dict_in['data'])
		self.channel_labels=dict_in['channel_labels'].strip().replace(' ','')
		self.calculate_all_features()
	store = property(_get_store, _set_store)
	
	def calculate_all_features(self):
		#Should calculation of trial features such as residuals use period model prior to inclusion of the current trial?
		
		session=Session()
		if self.datum_type=='period':
			for fname in self.feature_values.iterkeys():
				self.calculate_value_for_feature_name(fname, refdatum=None)
		else:
			#Use the parent period's detail values.
			period_id = session.query("period_id")\
				.from_statement("SELECT getParentPeriodIdForDatumId(:datum_id) AS period_id")\
				.params(datum_id=self.datum_id).one()
			refdatum = session.query(Datum).filter(Datum.datum_id==period_id).one()
			
			#First calculate the trial/day's values
			for fname in self.feature_values.iterkeys():
				self.calculate_value_for_feature_name(fname, refdatum=refdatum)
		
		#I would prefer not to need this... is there anything else that needs triggers or the db?
		session.flush()
			
	def calculate_value_for_feature_name(self, fname, refdatum=None):
		#use refdatum to get the required details.
		fxn=getattr(feature_functions,fname)
		self.feature_values[fname]=fxn(self, refdatum=refdatum)
				
class Datum_store(Base):
	datum				= relationship(Datum
							, backref=backref("_store", cascade="all, delete-orphan", uselist=False)
							, innerjoin=True
							, lazy="joined"
							)
	datum_type			= association_proxy("datum","type_name")

class Datum_type(Base):
	data 				= relationship(Datum
							, backref=backref("datum_type", lazy="joined")
							, cascade="all, delete-orphan"
							)
#	detail_types		= relationship(Datum_type_has_detail_type
#							, backref="datum_types"
#							)
#	feature_types		= relationship(Feature_type
#							, secondary="datum_type_has_feature_type"
#							, backref="feature_types"
#							)
	feature_types 		= association_proxy("datum_type_has_feature_type", "feature_type"
#							,creator = lambda k, v: Datum_type_has_feature_type(_feature_name=k, feature_type=v)
							)
	detail_types 		= association_proxy("datum_type_has_detail_type", "detail_type"
#							,creator = lambda k, v: Datum_type_has_detail_type(_detail_name=k, detail_type=v)
							)
							
class Datum_detail_value(Base):
	datum 				= relationship(Datum, backref=backref("datum_detail_value",
							collection_class=attribute_mapped_collection("detail_name"),
							cascade="all, delete-orphan", lazy="joined")
							, lazy="joined"
							)
	detail_type		= relationship(Detail_type, 
							backref=backref("datum_detail_value", cascade="all, delete-orphan")
							, lazy="joined"
							)
	detail_name		= association_proxy('detail_type','Name')
	
class Datum_feature_value(Base):
	datum 				= relationship(Datum, backref=backref("datum_feature_value",
							collection_class=attribute_mapped_collection("feature_name"),
							cascade="all, delete-orphan", lazy="joined")
							, lazy="joined"
							)
	feature_type		= relationship(Feature_type, 
							backref=backref("datum_feature_value", cascade="all, delete-orphan")
							, lazy="joined"
							)
	feature_name		= association_proxy('feature_type','Name')

class Subject(Base):
	data 				= relationship(Datum
							, backref=backref("subject", lazy="joined")
							, cascade="all, delete-orphan"
							, order_by="Datum.datum_id"
							)
	details 			= association_proxy("subject_detail_value", "Value"
							, creator = lambda k, v: Subject_detail_value(detail_name=k, Value=v)
							)
	def get_now_period_of_type(self,type):
		session=Session()
		per_id = session.query("period_id")\
			.from_statement("SELECT getNowPeriodIdForSubjectIdDatumTypeId(:subject_id,:datum_type_id) AS period_id")\
			.params(subject_id=self.subject_id,datum_type_id=type.datum_type_id).one()
			#.params(subject_id=my_subject.subject_id,datum_type_id=my_dat_type.datum_type_id)\
		if per_id[0]:
			return session.query(Datum).filter(Datum.datum_id==per_id[0]).one()
		else:
			return None
				
class Subject_type(Base):
	subjects 			= relationship(Subject, backref=backref("subject_type", lazy="joined")
							, cascade="all, delete-orphan")
#	detail_types		= relationship(Detail_type
#							, secondary="subject_type_has_detail_type"
#							, backref="subject_types"
#							)
	detail_types 		= association_proxy("subject_type_has_detail_type","detail_type")
	
	
class Subject_detail_value(Base):
	subject 			= relationship(Subject, backref=backref("subject_detail_value"
							, cascade="all, delete-orphan"
							, collection_class = attribute_mapped_collection("detail_name")
							, lazy="joined"
							)
							, lazy="joined"
							)
	detail_type = relationship(Detail_type, 
							backref=backref("subject_detail_value", cascade="all, delete-orphan")
							, lazy="joined"
							)
	detail_name 		= association_proxy("detail_type", "Name")

#
#Do I need the below association tables as association objects?
#
class Subject_type_has_detail_type(Base):
	subject_type 		= relationship(Subject_type, 
							backref=backref("subject_type_has_detail_type", cascade="all, delete-orphan"))
	detail_type 		= relationship(Detail_type, 
							backref=backref("subject_type_has_detail_type", cascade="all, delete-orphan"))
#	_subject_type_name 	= association_proxy("subject_type","Name")
#	_detail_name 		= association_proxy("detail_type","Name")
#	
class Datum_type_has_detail_type(Base):
	datum_type 			= relationship(Datum_type, 
							backref=backref("_datum_type_has_detail_type", cascade="all, delete-orphan"
#							,collection_class = attribute_mapped_collection("detail_name")
							))
	detail_type 		= relationship(Detail_type, 
							backref=backref("datum_type_has_detail_type", cascade="all, delete-orphan"))
#	_datum_name 		= association_proxy("datum_type","Name")
#	_detail_name 		= association_proxy("detail_type","Name")
#	
class Datum_type_has_feature_type(Base):
	pass
	datum_type 			= relationship(Datum_type, 
							backref=backref("datum_type_has_feature_type", cascade="all, delete-orphan"
#							,collection_class = attribute_mapped_collection("feature_name")
							))
	feature_type 		= relationship(Feature_type, 
							backref=backref("datum_type_has_feature_type", cascade="all, delete-orphan"))
#	_datum_name 		= association_proxy("datum_type","Name")
#	_feature_name 		= association_proxy("feature_type","Name")
		
engine = create_engine("mysql://root@localhost/eerat", echo=False)#echo="debug" gives a ton.
metadata = MetaData(bind=engine)#Base's metadata needs to reflect before I can call prepare.
metadata.reflect() #http://docs.sqlalchemy.org/en/latest/core/schema.html#reflecting-all-tables-at-once
Base.prepare(engine)
Session = scoped_session(sessionmaker(bind=engine, autocommit=True))