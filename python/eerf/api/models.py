# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#     * Rearrange models' order
#     * Make sure each model has one field with primary_key=True
# Feel free to rename the models, but don't rename db_table values or field names.
#
# Also note: You'll have to insert the output of 'django-admin.py sqlcustom [appname]'
# into your database.

from django.db import models
import django.utils.timezone
import datetime
import numpy as np
from eerfx import feature_functions

#http://stackoverflow.com/questions/21454/specifying-a-mysql-enum-in-a-django-model
class EnumField(models.Field):
    """
    A field class that maps to MySQL's ENUM type.

    Usage:

    Class Card(models.Model):
        suit = EnumField(values=('Clubs', 'Diamonds', 'Spades', 'Hearts'))

    c = Card()
    c.suit = 'Clubs'
    c.save()
    """
    def __init__(self, *args, **kwargs):
        self.values = kwargs.pop('values')
        kwargs['choices'] = [(v, v) for v in self.values]
        kwargs['default'] = self.values[0]
        super(EnumField, self).__init__(*args, **kwargs)

    def db_type(self, connection):
        return "enum({0})".format( ','.join("'%s'" % v for v in self.values) )
    
#http://stackoverflow.com/questions/759288/how-do-you-put-a-file-in-a-fixture-in-django
class NPArrayBlobField(models.Field):
    description = "Store/retrieve numpy arrays as LONGBLOB"
    __metaclass__ = models.SubfieldBase
    #===========================================================================
    # def __init__(self, *args, **kwargs):
    #    super(NPArrayBlobField, self).__init__(*args, **kwargs)
    #===========================================================================
    def db_type(self, connection):
        return 'LONGBLOB'
    def to_python(self, value):#From database to python
        if value is not None:
            if not hasattr(value, '__add__') or isinstance(value, basestring):
                value = np.frombuffer(value, dtype=float)
                value.flags.writeable = True
        return value
    def get_db_prep_save(self, value, connection):#from python to database
        if value is not None:
            value = value.tostring()
        return value

#http://justcramer.com/2008/08/08/custom-fields-in-django/
class CSVStringField(models.TextField):
    description = "Stores a list as a comma-separated string into a Text column"
    __metaclass__ = models.SubfieldBase
    def to_python(self, value):
        if not value:
            value = []
        elif isinstance(value, list):
            return value
        else:
            value = value.split(',')
        return value
    
    def get_db_prep_value(self, value, connection, prepared=False):
        if not value:
            return
        return ','.join(unicode(s) for s in value)
    
    def value_to_string(self, obj):
        value = self._get_val_from_obj(obj)
        return self.get_db_prep_value(value)
    
class System(models.Model):
    name = models.CharField(max_length=135, primary_key=True)
    value = models.CharField(max_length=135, blank=True)
    class Meta:
        db_table = u'system'
        
class Subject(models.Model):
    subject_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=135, unique=True)
    id = models.CharField(max_length=135, null=True, blank=True)
    weight = models.PositiveIntegerField(null=True, blank=True)
    height = models.PositiveIntegerField(null=True, blank=True)
    birthday = models.DateField(null=True, blank=True)
    headsize = models.CharField(max_length=135, null=True, blank=True)
    sex = EnumField(values=('unknown', 'male', 'female', 'unspecified'))
    handedness = EnumField(values=('unknown', 'right', 'left', 'equal'))
    smoking = EnumField(values=('unknown', 'no', 'yes'))
    alcohol_abuse = EnumField(values=('unknown', 'no', 'yes'))
    drug_abuse = EnumField(values=('unknown', 'no', 'yes'))
    medication = EnumField(values=('unknown', 'no', 'yes'))
    visual_impairment = EnumField(values=('unknown', 'no', 'yes', 'corrected'))
    heart_impairment = EnumField(values=('unknown', 'no', 'yes', 'pacemaker'))
    class Meta:
        db_table = u'subject'
        
    def __unicode__(self):
        return self.name
    
    def get_periods(self):
        return self.data.filter(span_type=3)
    def set_periods(self, periods):
        self.data.add(periods)
    periods = property(get_periods, set_periods)
    
    def get_or_create_recent_period(self,delay=9999):
        td = datetime.timedelta(hours=delay)
        periods = self.data.filter(span_type=3).filter(stop_time__gte=django.utils.timezone.now()-td).order_by('-stop_time')
        if periods.count() > 0:
            return periods[0]
        else:
            new_period = Datum.objects.create(subject=self, span_type='period')
            return new_period
        

class SubjectLog(models.Model):
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    #on_delete=models.CASCADE is the default. Note that this does not use the DBMS property but instead uses internal code.
    time = models.DateTimeField(null=True, blank=True, auto_now=True)
    entry = models.TextField(blank=True)
    class Meta:
        db_table = u'subject_log'
        #unique_together = ("subject","time")
    def __unicode__(self):
        return u"%s - %s: %s..." % (self.subject.name, self.time, self.entry[0:min(40,len(self.entry))])
        
class DetailType(models.Model):
    detail_type_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=135, unique=True)
    description = models.CharField(max_length=300, blank=True)
    class Meta:
        db_table = u'detail_type'
        
    def __unicode__(self):
        return self.name

class FeatureType(models.Model):
    feature_type_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=135, unique=True)
    description = models.CharField(max_length=135, blank=True)
    class Meta:
        db_table = u'feature_type'
        
    def __unicode__(self):
        return self.name
        
class Datum(models.Model):
    datum_id = models.AutoField(primary_key=True)
    subject = models.ForeignKey(Subject, related_name="data")
    number = models.PositiveIntegerField(default=0)
    span_type = EnumField(values=('trial', 'day', 'period'))
    is_good = models.BooleanField(default=True)
    start_time = models.DateTimeField(auto_now=True, null=True)
    stop_time = models.DateTimeField(blank=True, null=True)
    #===========================================================================
    # _detail_types = models.ManyToManyField(DetailType, through="DatumDetailValue", related_name="+")#no need for a detail_type to know ALL its values.
    # _feature_types = models.ManyToManyField(FeatureType, through="DatumFeatureValue", related_name="+")
    #===========================================================================
    trials = models.ManyToManyField("self",
                                    db_table = u'datum_has_datum',
                                    symmetrical = False,
                                    limit_choices_to = {'span_type': 'trial'},
                                    related_name = "periods",
                                    )
    class Meta:
        db_table = u'datum'
        unique_together = ("subject", "number", "span_type")
        
    def __unicode__(self):
        return u"%s - %i" % (self.span_type, self.number)
    
    def detail_values_dict(self):#return a dict of detail values.
        return dict([(item.detail_type.name,item.value) for item in self._detail_values.all()])
    
    def update_ddv(self,key,value):
        new_ddv = DatumDetailValue.objects.get_or_create(datum=self, detail_type=DetailType.objects.get_or_create(name=key)[0])[0]
        new_ddv.value = value
        new_ddv.save()
        
    def copy_details_from(self,ref_datum):
        ref_details = ref_datum.detail_values_dict()
        for kk in ref_details:
            if kk in ['BG_start_ms','BG_stop_ms'] or\
                (kk in ['MEP_start_ms','MEP_stop_ms','MEP_chan_label']) or\
                (kk in ['MR_start_ms','MR_stop_ms','HR_start_ms','HR_stop_ms','HR_chan_label']):
                self.update_ddv(kk,ref_details[kk])
        
    def feature_values_dict(self):#return a dict of detail values.
        return dict([(item.feature_type.name,item.value) for item in self._feature_values.all()])
    def update_dfv(self,key,value):
        new_dfv = DatumFeatureValue.objects.get_or_create(datum=self, feature_type=FeatureType.objects.get_or_create(name=key)[0])[0]
        new_dfv.value = value
        new_dfv.save()
        return value
        
    def extend_stop_time(self):
        td = datetime.timedelta(minutes = 5) if self.span_type=='period' else datetime.timedelta(seconds = 1)
        new_time = django.utils.timezone.now() + td
        if new_time>self.stop_time:
            self.stop_time = new_time
            
    def recalculate_child_feature_values(self):
        #REcalculate implies we want to calculate using period's details,
        #as the trial already has its features calculated using its details.
        if self.span_type=='period':
            my_trials = self.trials.all()
            return [tr.calculate_all_features for tr in my_trials]
    
    def recalculate_all_features(self):
        refdatum = None if self.span_type=='period' else self.periods.order_by('-datum_id').all()[0]#Assumes last parent is best parent.
        return [self.calculate_value_for_feature_name(dfv.feature_type.name, refdatum=refdatum) for dfv in self._feature_values]            
            
    def calculate_value_for_feature_name(self, fname, refdatum=None):
        #import EERF.APIextension.feature_functions
        fxn=getattr(feature_functions,fname)#pulls the name of the function from the feature_functions module.
        return self.update_dfv(fname, fxn(self, refdatum=refdatum))

class DatumStore(models.Model):
    datum = models.OneToOneField(Datum, primary_key=True, related_name = "store", on_delete=models.CASCADE)
    x_vec = NPArrayBlobField(null=True, blank=True)
    erp = NPArrayBlobField(null=True, blank=True)
    #x_vec = models.TextField(blank=True)
    #erp = models.TextField(blank=True)
    n_channels = models.PositiveSmallIntegerField(null=True, blank=True)
    n_samples = models.PositiveIntegerField(null=True, blank=True)
    channel_labels = CSVStringField(null=True, blank=True)
    class Meta:
        db_table = u'datum_store'
        
    def __unicode__(self):
        return u"%i samples x %i channels" % (self.n_samples, self.n_channels) if self.n_samples else "EMPTY"
    
    def get_data(self):
        return self.erp.reshape((self.n_channels,self.n_samples))
    def set_data(self, values):
        self.erp = values
        self.n_channels,self.n_samples = values.shape
        self.save()
    data = property(get_data,set_data)
        
#===============================================================================
# class DatumHasDatum(models.Model):
#    parent_datum = models.ForeignKey(Datum, related_name="+")
#    child_datum = models.ForeignKey(Datum, related_name="+")
#    class Meta:
#        db_table = u'datum_has_datum'
#===============================================================================
        
class DatumDetailValue(models.Model):
    datum = models.ForeignKey(Datum, related_name = "_detail_values", on_delete=models.CASCADE)
    detail_type = models.ForeignKey(DetailType)
    value = models.CharField(max_length=135, null=True, blank=True)
    class Meta:
        db_table = u'datum_detail_value'
        unique_together = ("datum", "detail_type")
    def __unicode__(self):
        return u"%s=%s" % (self.detail_type.name, self.value)

class DatumFeatureValue(models.Model):
    datum = models.ForeignKey(Datum, related_name = "_feature_values", on_delete=models.CASCADE)
    feature_type = models.ForeignKey(FeatureType)
    value = models.FloatField(null=True, blank=True)
    class Meta:
        db_table = u'datum_feature_value'
        unique_together = ("datum", "feature_type")
    def __unicode__(self):
        return u"%s=%f" % (self.feature_type.name, self.value)