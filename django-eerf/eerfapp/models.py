from django.db import models
#import django.utils.timezone
import datetime
import numpy as np
from eerfhelper import feature_functions

#===============================================================================
# Define custom fields here
#===============================================================================
class EnumField(models.Field):
    """
    A field class that maps to MySQL's ENUM type.

    Usage:

    Class Card(models.Model):
        suit = EnumField(choices=(('Clubs','Clubs), ('Diamonds','Diamonds'), ('Spades','Spades'), ('Hearts','Hearts')))

    c = Card()
    c.suit = 'Clubs'
    c.save()
    """
    def __init__(self, *args, **kwargs):
        kwargs['max_length'] = 104
        super(EnumField, self).__init__(*args, **kwargs)
        if not self.choices:
            raise AttributeError('EnumField requires `choices` attribute.')

    def db_type(self, connection):
        return "enum(%s)" % ','.join("'%s'" % k for (k, _) in self.choices)
        
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
        if value is not None and len(value)>0:
            if not hasattr(value, '__add__'):# or isinstance(value, basestring):
                value = np.frombuffer(value, dtype=float)
                value.flags.writeable = True
            if isinstance(value, basestring) and value not in ['EMPTY']:
                value = np.frombuffer(value, dtype=float)
                value.flags.writeable = True
        else:
            value = np.array([])
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
        
#===============================================================================
# Define custom models here.
#===============================================================================
    
class System(models.Model):
    """
    A quick identifier of the system. I cannot remember what this is useful for.
    """
    name = models.CharField(max_length=135, primary_key=True)
    value = models.CharField(max_length=135, blank=True)
    class Meta:
        db_table = u'system'
        
class Subject(models.Model):
    """
    A subject/animal/patient. Has detail_values_dict, a dict of its :model:`eerfd.SubjectDetailValue`.
    """
    subject_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=135, unique=True)
    id = models.CharField(max_length=135, null=True, blank=True)
    weight = models.PositiveIntegerField(null=True, blank=True)
    height = models.PositiveIntegerField(null=True, blank=True)
    birthday = models.DateField(null=True, blank=True)
    headsize = models.CharField(max_length=135, null=True, blank=True)
    sex = EnumField(choices=(('unknown','unknown'), ('male','male'), ('female','female'), ('unspecified','unspecified')))
    handedness = EnumField(choices=(('unknown','unknown'), ('right','right'), ('left','left'), ('equal','equal')))
    smoking = EnumField(choices=(('unknown','unknown'), ('no','no'), ('yes','yes')))
    alcohol_abuse = EnumField(choices=(('unknown','unknown'), ('no','no'), ('yes','yes')))
    drug_abuse = EnumField(choices=(('unknown','unknown'), ('no','no'), ('yes','yes')))
    medication = EnumField(choices=(('unknown','unknown'), ('no','no'), ('yes','yes')))
    visual_impairment = EnumField(choices=(('unknown','unknown'), ('no','no'), ('yes','yes'), ('corrected','corrected')))
    heart_impairment = EnumField(choices=(('unknown','unknown'), ('no','no'), ('yes','yes'), ('pacemaker','pacemaker')))
    class Meta:
        db_table = u'subject'
        
    def __unicode__(self):
        return self.name
    
    #===========================================================================
    # def get_periods(self):
    #    return self.data.filter(span_type=3)
    # def set_periods(self, periods):
    #    self.data.add(periods)
    # periods = property(get_periods, set_periods)
    # 
    # def get_or_create_recent_period(self,delay=9999):
    #    td = datetime.timedelta(hours=delay)
    #    periods = self.data.filter(span_type=3).filter(stop_time__gte=django.utils.timezone.now()-td).order_by('-stop_time')
    #    if periods.count() > 0:
    #        return periods[0]
    #    else:
    #        new_period = Datum.objects.create(subject=self, span_type='period')
    #        return new_period
    #===========================================================================
    def detail_values_dict(self):#return a dict of detail values.
        return dict([(item.detail_type.name,item.value) for item in self._detail_values.all()])
    def update_ddv(self,key,value):
        new_sdv = SubjectDetailValue.objects.get_or_create(subject=self, detail_type=DetailType.objects.get_or_create(name=key)[0])[0]
        new_sdv.value = value
        new_sdv.save()

class SubjectLog(models.Model):
    """
    One-to-many child of :model:`eerfd.Subject`.
    Contains an entry for significant changes to the subject.
    Some changes, e.g. to subject_detail_values, are auto-generated.
    """
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    #on_delete=models.CASCADE is the default. Note that this does not use the DBMS property but instead uses internal code.
    time = models.DateTimeField(null=True, blank=True, default=datetime.datetime.now)
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
    
class SubjectDetailValue(models.Model):
    subject = models.ForeignKey(Subject, related_name = "_detail_values", on_delete=models.CASCADE)
    detail_type = models.ForeignKey(DetailType)
    value = models.CharField(max_length=135, null=True, blank=True)
    class Meta:
        db_table = u'subject_detail_value'
        unique_together = ("subject", "detail_type")
    def __unicode__(self):
        return u"%s=%s" % (self.detail_type.name, self.value)

class Datum(models.Model):
    datum_id = models.AutoField(primary_key=True)
    subject = models.ForeignKey(Subject, related_name="data")
    number = models.PositiveIntegerField(null=False, default=0)
    #number = models.PositiveIntegerField(null=False, default=lambda: Datum.objects.latest('datum_id').number + 1)
    span_type = EnumField(choices=(('trial','trial'), ('day','day'), ('period','period')))
    is_good = models.BooleanField(null=False, default=True)
    start_time = models.DateTimeField(blank=True, null=True, default=datetime.datetime.now)
    stop_time = models.DateTimeField(blank=True, null=True, default=None)
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
        
    def save(self):
        if self.number==0:
            sub_dat = Datum.objects.filter(subject=self.subject).filter(span_type=self.span_type).order_by('-number')[0]
            self.number = sub_dat.number + 1 if sub_dat else 1
        if not self.stop_time:
            self.stop_time = (self.start_time + datetime.timedelta(seconds=1)) if self.span_type=='trial' else (self.start_time + datetime.timedelta(days=1))
        super(Datum, self).save()
        
    def __unicode__(self):
        return u"%s - %i" % (self.span_type, self.number)
    
    def feature_values_dict(self):#return a dict of detail values.
        return dict([(item.feature_type.name,item.value) for item in self._feature_values.all()])
    def update_dfv(self,key,value):
        new_dfv = DatumFeatureValue.objects.get_or_create(datum=self, feature_type=FeatureType.objects.get_or_create(name=key)[0])[0]
        new_dfv.value = value
        new_dfv.save()
        return value

    def detail_values_dict(self):#return a dict of detail values.
        return dict([(item.detail_type.name,item.value) for item in self._detail_values.all()])
    def update_ddv(self,key,value):
        new_ddv = DatumDetailValue.objects.get_or_create(datum=self, detail_type=DetailType.objects.get_or_create(name=key)[0])[0]
        new_ddv.value = value
        new_ddv.save()
    #===========================================================================
    # def copy_details_from(self,ref_datum):
    #    ref_details = ref_datum.detail_values_dict()
    #    for kk in ref_details:
    #        if kk in ['BG_start_ms','BG_stop_ms'] or\
    #            (kk in ['MEP_start_ms','MEP_stop_ms','MEP_chan_label']) or\
    #            (kk in ['MR_start_ms','MR_stop_ms','HR_start_ms','HR_stop_ms','HR_chan_label']):
    #            self.update_ddv(kk,ref_details[kk])
    #    
    #===========================================================================
        
    def extend_stop_time(self):
        td = datetime.timedelta(minutes = 5) if self.span_type=='period' else datetime.timedelta(seconds = 1)
        new_time = datetime.datetime.now() + td
        if new_time>self.stop_time:
            self.stop_time = new_time
            
    def recalculate_child_feature_values(self):
        #REcalculate implies we want to calculate using period's details.
        if self.span_type=='period':
            my_trials = self.trials.all()
            return [tr.calculate_all_features(refdatum=self) for tr in my_trials]
    
    def calculate_all_features(self, refdatum=None):
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

class DatumFeatureValue(models.Model):
    datum = models.ForeignKey(Datum, related_name = "_feature_values", on_delete=models.CASCADE)
    feature_type = models.ForeignKey(FeatureType)
    value = models.FloatField(null=True, blank=True)
    class Meta:
        db_table = u'datum_feature_value'
        unique_together = ("datum", "feature_type")
    def __unicode__(self):
        return u"%s=%f" % (self.feature_type.name, self.value)

class DatumDetailValue(models.Model):
    datum = models.ForeignKey(Datum, related_name = "_detail_values", on_delete=models.CASCADE)
    detail_type = models.ForeignKey(DetailType)
    value = models.CharField(max_length=135, null=True, blank=True)
    class Meta:
        db_table = u'datum_detail_value'
        unique_together = ("datum", "detail_type")
    def __unicode__(self):
        return u"%s=%s" % (self.detail_type.name, self.value)