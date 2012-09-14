from django.db import models
#https://docs.djangoproject.com/en/dev/topics/db/models/
#https://docs.djangoproject.com/en/dev/ref/models/fields/#ref-foreignkey

from django.conf import settings


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
        if settings.DATABASE_ENGINE == 'mysql':
            return 'LONGBLOB'
        elif settings.DATABASE_ENGINE == 'postgresql_psycopg2':
            return 'bytea'
        else:
            raise NotImplementedError

    def to_python(self, value):
        if settings.DATABASE_ENGINE == 'postgresql_psycopg2':
            if value is None:
                return value
            return str(value)
        else:
            return value

    def get_db_prep_save(self, value):
        if value is None:
            return None
        if settings.DATABASE_ENGINE =='postgresql_psycopg2':
            return psycopg2.Binary(value)
        else:
            return BlobValueWrapper(value)
        

class System(models.Model):
    name = models.CharField(max_length=45)
    value = models.CharField(max_length=45)

class Subject(models.Model):
    name = models.CharField(max_length=45)
    local_id = models.CharField(max_length=45, null=True)
    weight = models.IntegerField(null=True, blank=True)
    height = models.IntegerField(null=True, blank=True)
    birthday = models.DateField('Subject DOB', null=True)
    head_size = models.CharField(max_length=45, null=True, blank=True)
    sex = models.PositiveSmallIntegerField(default=0)
    handedness = models.PositiveSmallIntegerField(default=0)
    smoking = models.PositiveSmallIntegerField(default=0)
    alcohol_abuse = models.PositiveSmallIntegerField(default=0)
    drug_abuse = models.PositiveSmallIntegerField(default=0)
    medication = models.PositiveSmallIntegerField(default=0)
    visual_impairment = models.PositiveSmallIntegerField(default=0)
    heart_impairment = models.PositiveSmallIntegerField(default=0)
    
    def __unicode__(self):
        return self.name   
    
class Feature_type(models.Model):
    name = models.CharField(max_length=45)
    description = models.CharField(max_length=45)
    
class Detail_type(models.Model):
    name = models.CharField(max_length=45)
    description = models.CharField(max_length=45)
    
class Subject_log(models.Model):
    subject = models.ForeignKey(Subject)
    number = models.IntegerField()
    time = models.DateTimeField('date entry')
    entry = models.CharField(max_length=200)
    
class Datum(models.Model):
    subject = models.ForeignKey(Subject, related_name='data')
    number = models.IntegerField()
    span_type = models.IntegerField(choices=((1,'trial'),(2,'day'),(3,'period')))
    is_good = models.BooleanField(default=True)
    start_time = models.DateTimeField('data start', auto_now_add=True)
    stop_time = models.DateTimeField('data stop', auto_now_add=True)
    #trials
    #periods
    _detail_types = models.ManyToManyField(Detail_type, through="Datum_detail_value")
    _feature_types = models.ManyToManyField(Feature_type, through="Datum_feature_value")
    
    def __unicode__(self):
        return self.subject.name + ' ' + self.span_type + ' ' + self.number
    
class Datum_store(models.Model):
    datum = models.OneToOneField(Datum)
    x_vec = BlobField()
    erp = BlobField()
    n_channels = models.IntegerField()
    n_samples = models.IntegerField()
    channel_labels = models.TextField()
    
class Datum_detail_value(models.Model):
    datum = models.ForeignKey(Datum)
    detail_type = models.ForeignKey(Detail_type)
    value = models.CharField(max_length=45)
    
    def __unicode__(self):
        return self.detail_type.name + ' ' + self.value
    
class Datum_feature_value(models.Model):
    datum = models.ForeignKey(Datum)
    feature_type = models.ForeignKey(Feature_type)
    value = models.FloatField()
    
    def __unicode__(self):
        return self.feature_type.name + ' ' + self.value