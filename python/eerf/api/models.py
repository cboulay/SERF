# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#     * Rearrange models' order
#     * Make sure each model has one field with primary_key=True
# Feel free to rename the models, but don't rename db_table values or field names.
#
# Also note: You'll have to insert the output of 'django-admin.py sqlcustom [appname]'
# into your database.

from django.db import models

#http://stackoverflow.com/questions/759288/how-do-you-put-a-file-in-a-fixture-in-django
class BlobValueWrapper(object):
    """Wrap the blob value so that we can override the unicode method.
    After the query succeeds, Django attempts to record the last query
    executed, and at that point it attempts to force the query string
    to unicode. This does not work for binary data and generates an
    uncaught exception.
    """
    def __init__(self, val):
        self.val = val

    def __str__(self):
        return 'blobdata'

    def __unicode__(self):
        return u'blobdata'

class BlobField(models.Field):
    """A field for persisting binary data in databases that we support."""
    __metaclass__ = models.SubfieldBase
    def db_type(self, connection):
        return 'LONGBLOB'

    def to_python(self, value):
        return value

    def get_db_prep_save(self, value):
        if value is None:
            return None
        else:
            return BlobValueWrapper(value)



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
    sex = models.PositiveSmallIntegerField(choices=((0,'unknown'),(1,'male'),(2,'female'),(3,'unspecified')), default=0)
    handedness = models.PositiveSmallIntegerField(choices=((0,'unknown'),(1,'right'),(2,'left'),(3,'equal')), default=0)
    smoking = models.PositiveSmallIntegerField(choices=((0,'unknown'),(1,'no'),(2,'yes')), default=0)
    alcohol_abuse = models.PositiveSmallIntegerField(choices=((0,'unknown'),(1,'no'),(2,'yes')), default=0)
    drug_abuse = models.PositiveSmallIntegerField(choices=((0,'unknown'),(1,'no'),(2,'yes')), default=0)
    medication = models.PositiveSmallIntegerField(choices=((0,'unknown'),(1,'no'),(2,'yes')), default=0)
    visual_impairment = models.PositiveSmallIntegerField(choices=((0,'unknown'),(1,'none'),(2,'yes'),(3,'corrected')), default=0)
    heart_impairment = models.PositiveSmallIntegerField(choices=((0,'unknown'),(1,'no'),(2,'yes'),(3,'pacemaker')), default=0)
    class Meta:
        db_table = u'subject'
        
    def __unicode__(self):
        return self.name
    
    def get_periods(self):
        return self.data.filter(span_type=3)
    def set_periods(self, periods):
        self.data.add(periods)
    periods = property(get_periods, set_periods)

class SubjectLog(models.Model):
    subject = models.ForeignKey(Subject)
    number = models.PositiveIntegerField()
    time = models.DateTimeField(null=True, blank=True)
    entry = models.TextField(blank=True)
    class Meta:
        db_table = u'subject_log'
        unique_together = ("subject","number")
        
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
        
class Datum(models.Model):
    datum_id = models.AutoField(primary_key=True)
    subject = models.ForeignKey(Subject, related_name="data")
    number = models.PositiveIntegerField(default=0)
    span_type = models.PositiveSmallIntegerField(choices=((1,'trial'),(2,'day'),(3,'period')), default=1)
    is_good = models.BooleanField(default=True)
    start_time = models.DateTimeField(auto_now=True, null=True)
    stop_time = models.DateTimeField(blank=True, null=True)
    _detail_types = models.ManyToManyField(DetailType, through="DatumDetailValue", related_name="+")#no need for a detail_type to know ALL its values.
    _feature_types = models.ManyToManyField(FeatureType, through="DatumFeatureValue", related_name="+")
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

class DatumStore(models.Model):
    datum = models.OneToOneField(Datum, primary_key=True, related_name = "store")
    x_vec = BlobField(null=True, blank=True)
    erp = BlobField(null=True, blank=True)
    #x_vec = models.TextField(blank=True)
    #erp = models.TextField(blank=True)
    n_channels = models.PositiveSmallIntegerField(null=True, blank=True)
    n_samples = models.PositiveIntegerField(null=True, blank=True)
    channel_labels = models.TextField(null=True, blank=True)
    class Meta:
        db_table = u'datum_store'
        
    def __unicode__(self):
        return u"%i samples x %i channels" % (self.n_samples, self.n_channels) if self.n_samples else "EMPTY"
        
#===============================================================================
# class DatumHasDatum(models.Model):
#    parent_datum = models.ForeignKey(Datum, related_name="+")
#    child_datum = models.ForeignKey(Datum, related_name="+")
#    class Meta:
#        db_table = u'datum_has_datum'
#===============================================================================
        
class DatumDetailValue(models.Model):
    datum = models.ForeignKey(Datum, related_name = "_detail_values")
    detail_type = models.ForeignKey(DetailType)
    value = models.CharField(max_length=135, null=True, blank=True)
    class Meta:
        db_table = u'datum_detail_value'
        unique_together = ("datum", "detail_type")
    def __unicode__(self):
        return u"%s=%s" % (self.detail_type.name, self.value)

class DatumFeatureValue(models.Model):
    datum = models.ForeignKey(Datum, related_name = "_feature_values")
    feature_type = models.ForeignKey(FeatureType)
    value = models.FloatField(null=True, blank=True)
    class Meta:
        db_table = u'datum_feature_value'
        unique_together = ("datum", "feature_type")
    def __unicode__(self):
        return u"%s=%f" % (self.feature_type.name, self.value)