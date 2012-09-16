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
    name = models.CharField(max_length=135, primary_key=True, db_column='Name') # Field name made lowercase.
    value = models.CharField(max_length=135, db_column='Value', blank=True) # Field name made lowercase.
    class Meta:
        db_table = u'system'
        
class Subject(models.Model):
    subject_id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=135, unique=True, db_column='Name') # Field name made lowercase.
    id = models.CharField(max_length=135, db_column='Id', blank=True) # Field name made lowercase.
    weight = models.IntegerField(null=True, db_column='Weight', blank=True) # Field name made lowercase.
    height = models.IntegerField(null=True, db_column='Height', blank=True) # Field name made lowercase.
    birthday = models.DateField(null=True, db_column='Birthday', blank=True) # Field name made lowercase.
    headsize = models.CharField(max_length=135, db_column='Headsize', blank=True) # Field name made lowercase.
    sex = models.IntegerField(null=True, db_column='Sex', blank=True) # Field name made lowercase.
    handedness = models.IntegerField(null=True, db_column='Handedness', blank=True) # Field name made lowercase.
    smoking = models.IntegerField(null=True, db_column='Smoking', blank=True) # Field name made lowercase.
    alcoholabuse = models.IntegerField(null=True, db_column='AlcoholAbuse', blank=True) # Field name made lowercase.
    drugabuse = models.IntegerField(null=True, db_column='DrugAbuse', blank=True) # Field name made lowercase.
    medication = models.IntegerField(null=True, db_column='Medication', blank=True) # Field name made lowercase.
    visualimpairment = models.IntegerField(null=True, db_column='VisualImpairment', blank=True) # Field name made lowercase.
    heartimpairment = models.IntegerField(null=True, db_column='HeartImpairment', blank=True) # Field name made lowercase.
    class Meta:
        db_table = u'subject'
        
    def __unicode__(self):
        return self.name

class SubjectLog(models.Model):
    subject_subject = models.ForeignKey(Subject)
    number = models.IntegerField(primary_key=True, db_column='Number') # Field name made lowercase.
    time = models.DateTimeField(null=True, db_column='Time', blank=True) # Field name made lowercase.
    entry = models.TextField(db_column='Entry', blank=True) # Field name made lowercase.
    class Meta:
        db_table = u'subject_log'
        
class DetailType(models.Model):
    detail_type_id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=135, unique=True, db_column='Name') # Field name made lowercase.
    description = models.CharField(max_length=300, db_column='Description', blank=True) # Field name made lowercase.
    class Meta:
        db_table = u'detail_type'

class FeatureType(models.Model):
    feature_type_id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=135, unique=True, db_column='Name') # Field name made lowercase.
    description = models.CharField(max_length=135, db_column='Description', blank=True) # Field name made lowercase.
    class Meta:
        db_table = u'feature_type'
        
class Datum(models.Model):
    datum_id = models.IntegerField(primary_key=True)
    subject = models.ForeignKey(Subject)
    number = models.IntegerField(unique=True, db_column='Number') # Field name made lowercase.
    span_type = models.IntegerField(choices=((1,'trial'),(2,'day'),(3,'period')))
    #span_type = models.CharField(max_length=18)
    isgood = models.IntegerField(db_column='IsGood') # Field name made lowercase.
    starttime = models.DateTimeField(null=True, db_column='StartTime', blank=True) # Field name made lowercase.
    endtime = models.DateTimeField(null=True, db_column='EndTime', blank=True) # Field name made lowercase.
    _detail_types = models.ManyToManyField(DetailType, through="Datum_detail_value")
    _feature_types = models.ManyToManyField(FeatureType, through="Datum_feature_value")
    class Meta:
        db_table = u'datum'

class DatumStore(models.Model):
    datum = models.ForeignKey(Datum, primary_key=True)
    x_vec = BlobField()
    erp = BlobField()
    #x_vec = models.TextField(blank=True)
    #erp = models.TextField(blank=True)
    n_channels = models.IntegerField(null=True, blank=True)
    n_samples = models.IntegerField(null=True, blank=True)
    channel_labels = models.TextField(blank=True)
    class Meta:
        db_table = u'datum_store'
        
class DatumDetailValue(models.Model):
    datum = models.ForeignKey(Datum)
    detail_type = models.ForeignKey(DetailType)
    value = models.CharField(max_length=135, db_column='Value', blank=True) # Field name made lowercase.
    class Meta:
        db_table = u'datum_detail_value'

class DatumFeatureValue(models.Model):
    datum = models.ForeignKey(Datum)
    feature_type = models.ForeignKey(FeatureType)
    value = models.FloatField(null=True, db_column='Value', blank=True) # Field name made lowercase.
    class Meta:
        db_table = u'datum_feature_value'

class DatumHasDatum(models.Model):
    parent_datum = models.ForeignKey(Datum)
    child_datum = models.ForeignKey(Datum)
    class Meta:
        db_table = u'datum_has_datum'
