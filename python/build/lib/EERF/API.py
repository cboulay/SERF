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
from sqlalchemy.ext.declarative import declarative_base, DeferredReflection, declared_attr
from sqlalchemy.ext.associationproxy import association_proxy
from sqlalchemy.orm.collections import attribute_mapped_collection
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
		sess.commit()
		return instance

class MyBase(DeferredReflection):
	__mapper_args__= {'always_refresh': True}
	__table_args__ = {'mysql_engine': 'InnoDB'}
	
	@declared_attr
	def __tablename__(cls):
		return cls.__name__.lower()
			
Base = declarative_base(cls=MyBase)

class System(Base):
	pass

class Detail_type(Base):
	#Association proxy wasn't instantiating this properly without column definitions.
	detail_type_id	= Column(Integer, primary_key=True)
	Name			= Column(String(45))
	Description		= Column(String(45))
	
class Feature_type(Base):
	feature_type_id	= Column(Integer, primary_key=True)
	Name			= Column(String(45))
	Description		= Column(String(45))
	
#===============================================================================
# class Datum_has_datum(Base):
#	parent_datum_id		= Column(Integer, ForeignKey("datum.datum_id"), primary_key = True)
#	child_datum_id		= Column(Integer, ForeignKey("datum.datum_id"), primary_key = True)
#===============================================================================
Datum_has_datum = Table("datum_has_datum", Base.metadata,
	Column("parent_datum_id", Integer, ForeignKey("datum.datum_id"), primary_key = True),
	Column("child_datum_id", Integer, ForeignKey("datum.datum_id"), primary_key = True))

class Datum(Base):
	#subject = relationship(Subject, backref=backref("data", cascade="all, delete-orphan"))
	datum_id			= Column(Integer, primary_key=True)
	#http://sqlalchemy.readthedocs.org/en/latest/orm/relationships.html#self-referential-many-to-many-relationship
	trials				= relationship("Datum", secondary=Datum_has_datum, lazy="dynamic",
							primaryjoin= datum_id==Datum_has_datum.c.parent_datum_id,
							#primaryjoin = datum_id == Datum_has_datum.parent_datum_id,
							secondaryjoin = datum_id==Datum_has_datum.c.child_datum_id,
							backref=backref("periods", lazy="joined"))
	#===========================================================================
	# trials 			= relationship("Datum", order_by="Datum.Number", lazy="dynamic",
	#						backref=backref('period', remote_side=[datum_id], lazy="joined"))
	#===========================================================================
	#Datum_detail_value has a relationship backref'd here as _datum_feature_value
	#Now create an association proxy to _datum_feature_value to expose only Value
	detail_values 		= association_proxy("_datum_detail_value","Value",
							creator = lambda k, v: Datum_detail_value(detail_name=k, Value=v))
	feature_values 		= association_proxy("_datum_feature_value","Value",
							creator = lambda k, v: Datum_feature_value(feature_name=k, Value=v))
	#Now create an association proxy to _feautures to expose only Value as the 
	#_store				= relationship(Datum_store, uselist=False, backref="datum")
	
	#erp, x_vec, channel_labels should only be accessed through datum.store
	#erp 				= association_proxy("_store","erp")
	#x_vec				= association_proxy("_store","x_vec")
	#channel_labels 	= association_proxy("_store","channel_labels")
	#n_channels and n_samples should only be accessed through datum._store
	#n_channels 		= association_proxy("_store","n_channels")
	#n_samples 			= association_proxy("_store","n_samples")
	
	def _get_store(self):
		temp_store = self._store
		temp_x = temp_store.x_vec
		temp_data = temp_store.erp
		if temp_x:
			temp_x = np.frombuffer(temp_x, dtype=float)
			temp_x.flags.writeable = True
		if not hasattr(temp_x,'shape'): temp_x = np.ndarray((0),dtype=float)
		if temp_data:
			temp_data = np.frombuffer(temp_data, dtype=float)
			temp_data.flags.writeable = True
			temp_data = temp_data.reshape([temp_store.n_channels,temp_store.n_samples])
		if not hasattr(temp_data,'shape'): temp_data = np.ndarray((0),dtype=float)
		chan_labels = temp_store.channel_labels.split(',') if temp_store.channel_labels else list()
		return {'x_vec':temp_x, 'data':temp_data, 'channel_labels':chan_labels}
	def _set_store(self, dict_in):
		#Take a dict input and set the storage item
		#ERP from numpyarray of [chans x samps] to database blob
		new_store = Datum_store(datum_id=self.datum_id)
		new_store.n_channels,new_store.n_samples=np.shape(dict_in['data'])
		new_store.x_vec=dict_in['x_vec'].tostring() #always float?
		new_store.erp=dict_in['data'].tostring() #always float?
		#self.erp=np.getbuffer(dict_in['data'])
		ch_lab = dict_in['channel_labels']
		temp_string = ch_lab if isinstance(ch_lab,str) else ",".join(dict_in['channel_labels'])
		new_store.channel_labels=temp_string.strip().replace(' ','')
		#TODO: Feature calculation should be asynchronous
		self._store = new_store
		#session = Session.object_session(self)
		#session.commit()
		#self.calculate_all_features()
	store = property(_get_store, _set_store)
		#datum.store is a dict with keys 'x_vec', 'data', 'channel_labels'
		#x_vec and data are np.arrays. channel_labels is a list.
		#When setting store, it will accept a dict. channel_labels may be a comma-separated string.
		
	#method definitions
	def recalculate_child_feature_values(self):
		if self.span_type=='period':
			for tr in self.trials:
				tr.calculate_all_features();
	
	def calculate_all_features(self):
		#TODO: It might be faster to calculate multiple features simultaneously per trial.
		#Should calculation of trial features such as residuals use period model prior to inclusion of the current trial?
		
		refdatum = None if self.span_type=='period' else self.periods[-1]#Assumes last parent is best parent.
		
		#TODO: Adding a feature to a type after an instance of the type exists does not create a default value.
		for fname in self.feature_values.iterkeys():
			self.calculate_value_for_feature_name(fname, refdatum=refdatum)
			
		#I would prefer not to need this... is there anything else that needs triggers or the db?
		#session=Session()
		#session = Session.object_session(self)
		#session.flush()
		#session.commit()
			
	def calculate_value_for_feature_name(self, fname, refdatum=None):
		#use refdatum to get the required details.
		fxn=getattr(feature_functions,fname)
		self.feature_values[fname]=fxn(self, refdatum=refdatum)
		
	def det_string(self):
		return self.datum_type.Name + " " + str(self.Number) + " " + str(self.StartTime) + " to " + str(self.EndTime)
				
class Datum_store(Base):
	datum				= relationship(Datum
							, backref=backref("_store", cascade="all, delete-orphan", uselist=False, lazy="joined", passive_deletes=True)
							, innerjoin=True
							, lazy="joined"
							)

							
class Datum_detail_value(Base):
	#Need a relationship with detail_type so we know our Name
	dt					= relationship(Detail_type)
	#expose detail_type's Name attribute directly on this object.
	detail_name			= association_proxy('dt','Name')
	#Create a relationship with Datum and use a proxy to dictionary_based collection using detail_name as the key.
	datum 				= relationship(Datum, backref=backref("_datum_detail_value",
							collection_class=attribute_mapped_collection("detail_name"),
							cascade="all, delete-orphan", passive_deletes=True, lazy="subquery")
							)
	
	def __init__(self, *args, **kwargs):
		if 'detail_name' in kwargs:
			self.dt = get_or_create(Detail_type, Name=kwargs['detail_name'], sess=Session.object_session(self))
		if 'Value' in kwargs:
			self.Value = kwargs['Value']
	
class Datum_feature_value(Base):
	#Need a relationship with feature_type so we know our feature_type_name
	ft		= relationship(Feature_type, 
							backref=backref("datum_feature_value", cascade="all, delete-orphan", passive_deletes=True)
							, lazy="joined")
	#Expose self.feature_type.Name as self.feature_name
	feature_name		= association_proxy('ft','Name')
	#Create a relationship with Datum so it may access its feature values using feature_names as keys.
	datum 				= relationship(Datum, backref=backref("_datum_feature_value",
							collection_class=attribute_mapped_collection("feature_name"),
							cascade="all, delete-orphan", passive_deletes=True, lazy="subquery")
							)
	def __init__(self, *args, **kwargs):
		if 'feature_name' in kwargs:
			self.ft = get_or_create(Feature_type, Name=kwargs['feature_name'], sess=Session.object_session(self))
		if 'Value' in kwargs:
			self.Value = kwargs['Value']
	
class Subject(Base):
	data 				= relationship(Datum
							, backref=backref("subject")
							, cascade="all, delete-orphan"
							, order_by="Datum.datum_id"
							, lazy="dynamic"
							)
	periods				= relationship(Datum
							#, cascade="all, delete-orphan"
							, order_by="Datum.datum_id"
							, primaryjoin="and_(Subject.subject_id==Datum.subject_id, Datum.span_type=='period')"
							, lazy="joined")
		
#	def _get_periods(self):
#		session = Session.object_session(self)
#		periods = session.query(Datum).filter(\
#					Datum.subject_id==self.subject_id,\
#					Datum.span_type==3).order_by(Datum.Number).all()
#	def _set_periods(self): pass #Read-only. 
#	periods = property(_get_periods, _set_periods)
	
engine = create_engine("mysql://root@localhost/eerat", echo=False)#echo="debug" gives a ton.
metadata = MetaData(bind=engine)#Base's metadata needs to reflect before I can call prepare.
metadata.reflect() #http://docs.sqlalchemy.org/en/latest/core/schema.html#reflecting-all-tables-at-once
Base.prepare(engine)
Session = scoped_session(sessionmaker(bind=engine, autoflush=True))