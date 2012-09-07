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
import numpy as np
from operator import attrgetter
from sqlalchemy import *
from sqlalchemy.orm import *
from sqlalchemy.orm.collections import attribute_mapped_collection
from sqlalchemy.ext.declarative import declarative_base, declared_attr, DeferredReflection
from sqlalchemy.ext.associationproxy import association_proxy
import EERF.APIextension.feature_functions

#The following gets or creates a model into the db but also persists it.
#Only use this method when we can describe all arguments.
def get_or_create(model, all=False, sess=None, **kwargs):
	#http://stackoverflow.com/questions/2546207/does-sqlalchemy-have-an-equivalent-of-djangos-get-or-create
	if not sess: sess=Session()
	if all:
		instance = sess.query(model).filter_by(**kwargs).all()
	else:
		instance = sess.query(model).filter_by(**kwargs).first()
	if instance: return instance
	else:
		instance = model(**kwargs)
		sess.add(instance)
		sess.commit() #commit right away to fire triggers.
		return instance

Base = declarative_base()

class System(Base):
	__tablename__	= 'system'
	__table_args__	= {'schema': 'eerf_settings', 'mysql_engine': 'InnoDB'}
	Name			= Column(String(45), primary_key=True)
	Value			= Column(String(45))
	
class Detail_type(Base):
	__table_args__	= {'schema': 'eerf_settings', 'mysql_engine': 'InnoDB'}
	__tablename__	= 'detail_type'
	detail_type_id	= Column(Integer, primary_key=True)
	Name			= Column(String(45))
	Description		= Column(String(100))
	DefaultValue	= Column(String(45))
	
class Feature_type(Base):
	__table_args__	= {'schema': 'eerf_settings', 'mysql_engine': 'InnoDB'}
	__tablename__	= 'feature_type'
	feature_type_id	= Column(Integer, primary_key=True)
	Name			= Column(String(45))
	Description		= Column(String(45))
	
Datum_type_has_feature_type	= Table("datum_type_has_feature_type", Base.metadata,
									Column('datum_type_id', Integer, ForeignKey("eerf_settings.datum_type.datum_type_id"), primary_key=True),
									Column('feature_type_id', Integer, ForeignKey("eerf_settings.feature_type.feature_type_id"), primary_key=True),
									schema="eerf_settings")

Datum_type_has_detail_type	= Table("datum_type_has_detail_type", Base.metadata,
									Column('datum_type_id', Integer, ForeignKey("eerf_settings.datum_type.datum_type_id"), primary_key=True),
									Column('detail_type_id', Integer, ForeignKey("eerf_settings.detail_type.detail_type_id"), primary_key=True),
									schema="eerf_settings")

class Datum_type(Base):
	__table_args__	= {'schema': 'eerf_settings', 'mysql_engine': 'InnoDB'}
	__tablename__	= 'datum_type'
	datum_type_id	= Column(Integer, primary_key=True)
	Name			= Column(String(45))
	Description		= Column(String(45))
	detail_types	= relationship("Detail_type",
								secondary=Datum_type_has_detail_type,
								primaryjoin = datum_type_id==Datum_type_has_detail_type.c.datum_type_id,
								secondaryjoin = Datum_type_has_detail_type.c.detail_type_id==Detail_type.detail_type_id,
								backref="datum_types")
	feature_types	= relationship("Feature_type",
								secondary=Datum_type_has_feature_type,
								primaryjoin = datum_type_id==Datum_type_has_feature_type.c.datum_type_id,
								secondaryjoin = Datum_type_has_feature_type.c.feature_type_id==Feature_type.feature_type_id,
								backref="datum_types")
	#what about attribute_mapped_collection or association_proxy?


#Now do subject tables. Remember we don't know the schema until the subject is created,
#so we can't specify the schema now. We can add the info to the metdata, and we can refer
#to foreign keys in the settings schema, but all within-foreign keys must not have a schema specified.

Datum_has_datum = Table("datum_has_datum", Base.metadata,
	Column("parent_datum_id", Integer, ForeignKey("datum.datum_id"), primary_key = True),
	Column("child_datum_id", Integer, ForeignKey("datum.datum_id"), primary_key = True))

class Datum(Base):
	__table_args__		= {'mysql_engine': 'InnoDB'}
	__tablename__		= 'datum'
	datum_id			= Column(Integer, primary_key=True)
	datum_type_id		= Column(Integer, ForeignKey("eerf_settings.datum_type.datum_type_id"))
	Number				= Column(Integer)
	span_type			= Column(Enum(['trial','day','period']))
	IsGood				= Column(Boolean)
	StartTime			= Column(DateTime)
	EndTime				= Column(DateTime)
	#===========================================================================
	# feature_values 		= association_proxy("datum_feature_value","Value",
	#						creator = lambda k, v: Datum_feature_value(feature_name=k, Value=v))
	# detail_values 		= association_proxy("datum_detail_value","Value",
	#						creator = lambda k, v: Datum_detail_value(detail_name=k, Value=v))
	#===========================================================================
	#http://sqlalchemy.readthedocs.org/en/latest/orm/relationships.html#self-referential-many-to-many-relationship
	trials				= relationship("Datum", secondary=Datum_has_datum, lazy="dynamic",
							primaryjoin= datum_id==Datum_has_datum.c.parent_datum_id,
							secondaryjoin = datum_id==Datum_has_datum.c.child_datum_id,
							backref=backref("periods", lazy="joined"))
	
	#===========================================================================
	# def _get_store(self):
	#	temp_store = self._store
	#	temp_x = temp_store.x_vec
	#	temp_data = temp_store.erp
	#	if temp_x:
	#		temp_x = np.frombuffer(temp_x, dtype=float)
	#		temp_x.flags.writeable = True
	#	if not hasattr(temp_x,'shape'): temp_x = np.ndarray((0),dtype=float)
	#	if temp_data:
	#		temp_data = np.frombuffer(temp_data, dtype=float)
	#		temp_data.flags.writeable = True
	#		temp_data = temp_data.reshape([temp_store.n_channels,temp_store.n_samples])
	#	if not hasattr(temp_data,'shape'): temp_data = np.ndarray((0),dtype=float)
	#	chan_labels = temp_store.channel_labels.split(',') if temp_store.channel_labels else list()
	#	return {'x_vec':temp_x, 'data':temp_data, 'channel_labels':chan_labels}
	# def _set_store(self, dict_in):
	#	#Take a dict input and set the storage item
	#	#ERP from numpyarray of [chans x samps] to database blob
	#	new_store = Datum_store(datum_id=self.datum_id)
	#	new_store.n_channels,new_store.n_samples=np.shape(dict_in['data'])
	#	new_store.x_vec=dict_in['x_vec'].tostring() #always float?
	#	new_store.erp=dict_in['data'].tostring() #always float?
	#	#self.erp=np.getbuffer(dict_in['data'])
	#	ch_lab = dict_in['channel_labels']
	#	temp_string = ch_lab if isinstance(ch_lab,str) else ",".join(dict_in['channel_labels'])
	#	new_store.channel_labels=temp_string.strip().replace(' ','')
	#	#TODO: Feature calculation should be asynchronous
	#	self._store = new_store
	#	#session = Session.object_session(self)
	#	#session.commit()
	#	#self.calculate_all_features()
	# store = property(_get_store, _set_store)
	#	#datum.store is a dict with keys 'x_vec', 'data', 'channel_labels'
	#	#x_vec and data are np.arrays. channel_labels is a list.
	#	#When setting store, it will accept a dict. channel_labels may be a comma-separated string.
	#	
	# #method definitions
	# def recalculate_child_feature_values(self):
	#	if self.span_type=='period':
	#		for tr in self.trials:
	#			tr.calculate_all_features();
	# 
	# def calculate_all_features(self):
	#	#TODO: It might be faster to calculate multiple features simultaneously per trial.
	#	#Should calculation of trial features such as residuals use period model prior to inclusion of the current trial?
	#	
	#	refdatum = None if self.span_type=='period' else self.periods[-1]#Assumes last parent is best parent.
	#	
	#	#TODO: Adding a feature to a type after an instance of the type exists does not create a default value.
	#	for fname in self.feature_values.iterkeys():
	#		self.calculate_value_for_feature_name(fname, refdatum=refdatum)
	#		
	#	#I would prefer not to need this... is there anything else that needs triggers or the db?
	#	#session=Session()
	#	#session = Session.object_session(self)
	#	#session.flush()
	#	#session.commit()
	#		
	# def calculate_value_for_feature_name(self, fname, refdatum=None):
	#	#use refdatum to get the required details.
	#	fxn=getattr(feature_functions,fname)
	#	self.feature_values[fname]=fxn(self, refdatum=refdatum)
	#	
	# def det_string(self):
	#	return self.datum_type.Name + " " + str(self.Number) + " " + str(self.StartTime) + " to " + str(self.EndTime)
	#===========================================================================
				
class Datum_store(Base):
	__table_args__		= {'mysql_engine': 'InnoDB'}
	__tablename__		= 'datum_store'
	datum_id			= Column(Integer, ForeignKey("datum.datum_id"), primary_key=True)
	x_vec				= Column(LargeBinary)
	erp					= Column(LargeBinary)
	n_channels			= Column(SmallInteger)
	n_samples			= Column(SmallInteger)
	channel_labels		= Column(Text)
	datum				= relationship("Datum"
							, backref=backref("_store", cascade="all, delete-orphan", uselist=False, lazy="joined")
							, innerjoin=True
							, lazy="joined"
							)

							
class Datum_detail_value(Base):
	__table_args__		= {'mysql_engine': 'InnoDB'}
	__tablename__		= 'datum_detail_value'
	datum_id			= Column(Integer, ForeignKey("datum.datum_id"), primary_key=True)
	detail_type_id		= Column(Integer, ForeignKey("eerf_settings.detail_type.detail_type_id"), primary_key=True)
	Value				= Column(VARCHAR(45))
	#===========================================================================
	# datum 				= relationship(Datum, backref=backref("datum_detail_value",
	#						collection_class=attribute_mapped_collection("detail_name"),
	#						cascade="all, delete-orphan", lazy="subquery")
	#						)
	# detail_type			= relationship(Detail_type, 
	#						backref=backref("datum_detail_value", cascade="all, delete-orphan")
	#						, lazy="joined")
	# detail_name			= association_proxy('detail_type','Name')
	#===========================================================================
	
class Datum_feature_value(Base):
	__table_args__		= {'mysql_engine': 'InnoDB'}
	__tablename__		= 'datum_feature_value'
	datum_id			= Column(Integer, ForeignKey("datum.datum_id"), primary_key=True)
	feature_type_id		= Column(Integer, ForeignKey("eerf_settings.feature_type.feature_type_id"), primary_key=True)
	Value				= Column(Float)
	#===========================================================================
	# datum 				= relationship(Datum, backref=backref("datum_feature_value",
	#						collection_class=attribute_mapped_collection("feature_name"),
	#						cascade="all, delete-orphan", lazy="subquery")
	#						)
	# feature_type		= relationship(Feature_type, 
	#						backref=backref("datum_feature_value", cascade="all, delete-orphan")
	#						, lazy="joined")
	# feature_name		= association_proxy('feature_type','Name')
	#===========================================================================
	
class Subject(Base):
	__tablename__	= 'subject'
	__table_args__	= {'schema': 'eerf_settings', 'mysql_engine': 'InnoDB'}
	Name			= Column(String(45), primary_key=True)
	Id				= Column(String(45))
	Birthday		= Column(DateTime)
	Weight			= Column(SmallInteger)
	Height			= Column(SmallInteger)
	Headsize		= Column(SmallInteger)
	Sex				= Column(SmallInteger)
	Handedness		= Column(SmallInteger)
	Smoking			= Column(SmallInteger)
	AlcoholAbuse	= Column(SmallInteger)
	DrugAbuse		= Column(SmallInteger)
	Medication		= Column(SmallInteger)
	VisualImpairment= Column(SmallInteger)
	HeartImpairment	= Column(SmallInteger)
	periods			= []
	
	def __init__(self,**kwargs):
		super(Subject, self)._declarative_constructor(**kwargs)
		sett_engine = create_engine("mysql://root@localhost/eerf_settings", echo=False)
		sub_engine = create_engine("mysql://root@localhost/eerf_subject_"+self.Name, echo=False)
		Session.configure(binds={
								System: sett_engine,
								Subject: sett_engine,
								Detail_type: sett_engine,
								Feature_type: sett_engine,
								Datum_type: sett_engine,
								Datum: sub_engine,
								Datum_store: sub_engine,
								Datum_detail_value: sub_engine,
								Datum_feature_value: sub_engine
								})
		
	def get_periods(self):
		return Session().query(Datum).filter(Datum.span_type=='period').all()
	def set_periods(self, periods): pass
		#If the engine is working properly, any created period should automatically go to the correct schema
	periods = property(get_periods, set_periods)

engine = create_engine("mysql://root@localhost/eerf_settings", echo=False)
Session = sessionmaker(bind=engine)