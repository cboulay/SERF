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
		#sess.flush()
		sess.commit() #commit right away to fire triggers.
		return instance

class MyMixin(object):
    @declared_attr
    def __tablename__(cls):
        return cls.__name__.lower()
    __table_args__ = {'mysql_engine': 'InnoDB'}
    __mapper_args__= {'always_refresh': True}
    
Base = declarative_base(cls=MyMixin)

class SettingsBase(DeferredReflection, Base):
	__abstract__ = True
	__table_args__ = {'mysql_engine': 'InnoDB', 'schema':'eerf_settings'}

class SubjectBase(DeferredReflection, Base):
    __abstract__ = True

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

class System(SettingsBase):
	pass

class Detail_type(SettingsBase):
	pass
	
class Feature_type(SettingsBase):
	pass

class Datum_type_has_detail_type(SettingsBase):
	pass
#	datum_type 			= relationship(Datum_type, 
#							backref=backref("datum_type_has_detail_type", cascade="all, delete-orphan"))
#							,collection_class = attribute_mapped_collection("detail_name")
#							))
#	detail_type 		= relationship(Detail_type, 
#							backref=backref("datum_type_has_detail_type", cascade="all, delete-orphan"))
#	_datum_name 		= association_proxy("datum_type","Name")
#	_detail_name 		= association_proxy("detail_type","Name")
#	
class Datum_type_has_feature_type(SettingsBase):
	pass
#	datum_type 			= relationship(Datum_type, 
#							backref=backref("datum_type_has_feature_type", cascade="all, delete-orphan"
#							,collection_class = attribute_mapped_collection("feature_name")
#							))
#	feature_type 		= relationship(Feature_type, 
#							backref=backref("datum_type_has_feature_type", cascade="all, delete-orphan"))
#	_datum_name 		= association_proxy("datum_type","Name")
#	_feature_name 		= association_proxy("feature_type","Name")

class Datum_type(SettingsBase):
	datum_type_id		= Column(Integer, primary_key=True)
	detail_types		= relationship(Detail_type
							, secondary="eerf_settings.datum_type_has_detail_type"
							, backref="datum_types")
	feature_types		= relationship(Feature_type
							, secondary="eerf_settings.datum_type_has_feature_type"
							, backref="datum_types")
	
Datum_has_datum = Table("datum_has_datum", SubjectBase.metadata,
	Column("parent_datum_id", Integer, ForeignKey("datum.datum_id"), primary_key = True),
	Column("child_datum_id", Integer, ForeignKey("datum.datum_id"), primary_key = True))

class Datum(SubjectBase):
	#===========================================================================
	# feature_values 		= association_proxy("datum_feature_value","Value",
	#						creator = lambda k, v: Datum_feature_value(feature_name=k, Value=v))
	# detail_values 		= association_proxy("datum_detail_value","Value",
	#						creator = lambda k, v: Datum_detail_value(detail_name=k, Value=v))
	#===========================================================================
	#http://sqlalchemy.readthedocs.org/en/latest/orm/relationships.html#self-referential-many-to-many-relationship
	datum_id			= Column(Integer, primary_key=True) #Must be explicit for mapper to work.
	datum_type_id		= Column(Integer, ForeignKey("eerf_settings.datum_type.datum_type_id"))
	trials				= relationship("Datum", secondary=Datum_has_datum, lazy="dynamic",
							primaryjoin= datum_id==Datum_has_datum.c.parent_datum_id,
							#primaryjoin = datum_id == Datum_has_datum.parent_datum_id,
							secondaryjoin = datum_id==Datum_has_datum.c.child_datum_id,
							backref=backref("periods", lazy="joined"))
	datum_type			= relationship("Datum_type", lazy="joined")
	
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
				
class Datum_store(SubjectBase):
	datum				= relationship(Datum
							, backref=backref("_store", cascade="all, delete-orphan", uselist=False, lazy="joined")
							, innerjoin=True
							, lazy="joined"
							)

							
class Datum_detail_value(SubjectBase):
	pass
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
	
class Datum_feature_value(SubjectBase):
	pass
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

	
class Subject_detail_value(SubjectBase):
	pass
	#===========================================================================
	# detail_type = relationship(Detail_type, 
	#						backref=backref("subject_detail_value", cascade="all, delete-orphan")
	#						, lazy="joined"
	#						)
	# detail_name 		= association_proxy("detail_type", "Name")
	#===========================================================================

class Subject(object):
	def __init__(self, name='template'):
		self.name = name;
		settings_engine = create_engine("mysql://root@localhost/eerf_settings", echo=False)
		SettingsBase.prepare(settings_engine)
		
		subject_engine = create_engine("mysql://root@localhost/eerf_subject_template", echo=False)
		SubjectBase.prepare(subject_engine)
		
		Session = scoped_session(sessionmaker(autoflush=True, binds={
                                        System: settings_engine,
                                        Detail_type: settings_engine,
                                        Feature_type: settings_engine,
                                        Datum_type: settings_engine,
                                        Datum_type_has_detail_type: settings_engine,
                                        Datum_type_has_feature_type: settings_engine,
                                        Datum: subject_engine,
                                        Datum_store: subject_engine,
                                        Datum_detail_value: subject_engine,
                                        Datum_feature_value: subject_engine,
                                        Subject_detail_value: subject_engine
                                        }))
		
		session = Session()
		session.query(Datum).all()