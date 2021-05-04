from django.db import models
# import django.utils.timezone
import datetime
import numpy as np


# =========================
# Define custom fields here
# =========================


class EnumField(models.Field):
    """
    A field class that maps to MySQL's ENUM type.

    Usage:

    Class Card(models.Model):
        suit = EnumField(choices=(('Clubs', 'Clubs'),
                                  ('Diamonds', 'Diamonds'),
                                  ('Spades', 'Spades'),
                                  ('Hearts', 'Hearts')))

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
        return "enum(%s)" % ', '.join("'%s'" % k for (k, _) in self.choices)


class NPArrayBlobField(models.BinaryField):
    """
    http://stackoverflow.com/questions/759288/how-do-you-put-a-file-in-a-fixture-in-django
    """
    description = "Store/retrieve numpy arrays as LONGBLOB"

    # ===========================================================================
    def __init__(self, np_dtype=np.float, *args, **kwargs):
        self.np_dtype = np_dtype
        super().__init__(*args, **kwargs)
        # super(NPArrayBlobField, self).__init__(*args, **kwargs)

    def db_type(self, connection):
        return 'LONGBLOB'

    def from_db_value(self, value, expression, connection):
        if value is None:
            return value
        return np.frombuffer(value, dtype=self.np_dtype)

    def to_python(self, value):  # From database to python
        if value is not None and len(value) > 0:
            if not hasattr(value, '__add__'):  # or isinstance(value, basestring):
                value = np.frombuffer(value, dtype=self.np_dtype)
                value.flags.writeable = True
            if isinstance(value, basestring) and value not in ['EMPTY']:
                value = np.frombuffer(value, dtype=self.np_dtype)
                value.flags.writeable = True
        else:
            value = np.array([], dtype=self.np_dtype)
        return value

    def get_db_prep_save(self, value, connection):  # from python to database
        if value is not None:
            value = value.tostring()
        return value

    def deconstruct(self):
        name, path, args, kwargs = super().deconstruct()
        if self.np_dtype != np.float:
            kwargs['np_dtype'] = self.np_dtype
        return name, path, args, kwargs
        

class CSVStringField(models.TextField):
    """
    http://justcramer.com/2008/08/08/custom-fields-in-django/
    """
    description = "Stores a list as a comma-separated string into a Text column"

    def to_python(self, value):
        if not value:
            value = []
        elif isinstance(value, list):
            return value
        else:
            value = value.split(', ')
        return value

    def from_db_value(self, value, expression, connection):
        if not value:
            value = []
        elif isinstance(value, list):
            return value
        else:
            value = value.split(', ')
        return value

    def get_db_prep_value(self, value, connection, prepared=False):
        if not value:
            return
        # Removed "unicode" because was giving off error as undefined
        # return ', '.join(unicode(s) for s in value)
        return ', '.join(s for s in value)

    def value_to_string(self, obj):
        value = self._get_val_from_obj(obj)
        return self.get_db_prep_value(value)


# ==========================
# Define custom models here.
# ==========================


class System(models.Model):
    """
    A quick identifier of the system. I cannot remember what this is useful for. Upgrading?
    """
    name = models.CharField(max_length=135, primary_key=True)
    value = models.CharField(max_length=135, blank=True)

    class Meta:
        db_table = u'system'


class Subject(models.Model):
    """
    A participant/animal/patient. Has detail_values_dict, a dict of its :model:`eerfd.SubjectDetailValue`.
    """
    # mandatory
    subject_id = models.AutoField(primary_key=True)
    id = models.CharField(max_length=135, unique=True)
    birthday = models.DateField(null=True, blank=True)
    sex = EnumField(choices=(('unknown', 'unknown'),
                             ('male', 'male'),
                             ('female', 'female'),
                             ('unspecified', 'unspecified')),
                    default='unknown')
    # optional
    name = models.CharField(max_length=135, blank=True)

    class Meta:
        db_table = u'subject'
        
    def __unicode__(self):
        return self.name
    
    # ===========================================================================
    # def get_periods(self):
    #    return self.data.filter(span_type=3)
    # def set_periods(self, periods):
    #    self.data.add(periods)
    # periods = property(get_periods, set_periods)
    # 
    # def get_or_create_recent_period(self,delay=9999):
    #    td = datetime.timedelta(hours=delay)
    #    periods = self.data.filter(span_type=3).filter(
    #    stop_time__gte=django.utils.timezone.now()-td).order_by('-stop_time')
    #    if periods.count() > 0:
    #        return periods[0]
    #    else:
    #        new_period = Datum.objects.create(subject=self, span_type='period')
    #        return new_period
    # ===========================================================================
    def detail_values_dict(self):  # return a dict of detail values.
        return dict([(item.detail_type.name, item.value) for item in self._detail_values.all()])

    def update_ddv(self, key, value):
        new_sdv = SubjectDetailValue.objects.get_or_create(subject=self,
                                                           detail_type=DetailType.objects.get_or_create(name=key)[0])[0]
        new_sdv.value = value
        new_sdv.save()


class SubjectLog(models.Model):
    """
    One-to-many child of :model:`eerfd.Subject`.
    Contains an entry for significant changes to the subject.
    Some changes, e.g. to subject_detail_values, are auto-generated.
    """
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    # on_delete=models.CASCADE is the default. Note that this does not use the DBMS property but
    # instead uses internal code.
    time = models.DateTimeField(null=True, blank=True, default=datetime.datetime.now)
    entry = models.TextField(blank=True)

    class Meta:
        db_table = u'subject_log'
        # unique_together = ("subject","time")

    def __unicode__(self):
        return u"%s - %s: %s..." % (self.subject.name, self.time, self.entry[0:min(40, len(self.entry))])


class Procedure(models.Model):
    """
        Anything undertaken on the subject: experiment, surgical, monitoring,...
    """
    # mandatory
    procedure_id = models.AutoField(primary_key=True)
    date = models.DateField(blank=True, null=True, default=datetime.date.today)
    subject = models.ForeignKey(Subject, related_name="_procedures", on_delete=models.CASCADE)
    type = EnumField(choices=(('none', 'none'),
                              ('surgical', 'surgical'),
                              ('experiment', 'experiment'),
                              ('monitoring', 'monitoring'),
                              ('other', 'other')), default='none')
    # optional
    a = NPArrayBlobField(np.float, null=True, blank=True, editable=True)  # A-E Coordinates
    distance_to_target = models.FloatField(null=True, blank=True)
    e = NPArrayBlobField(np.float, null=True, blank=True, editable=True)  # A-E Coordinates
    electrode_config = EnumField(choices=(('none', 'none'), ('+', '+'), ('x', 'x'), ('l', 'l')),
                                 default='none')
    entry = NPArrayBlobField(np.float, null=True, blank=True, editable=True)  # entry point coordinates
    medication_status = EnumField(choices=(('none', 'none'), ('on', 'on'), ('off', 'off'), ('half', 'half')),
                                  default='none')
    offset_direction = EnumField(choices=(('none', 'none'), ('A', 'A'), ('B', 'B'), ('C', 'C'), ('D', 'D'),
                                          ('E', 'E'), ('F', 'F'), ('G', 'G'), ('H', 'H')), default='none')
    offset_size = models.FloatField(default=0.0)
    target_name = models.CharField(max_length=135, blank=True)

    cfg_roots = ['left', 'right', 'bilateral', 'full', 'array']
    suffixes = [('_' + str(_)) if _ > 1 else '' for _ in range(1, 5)]
    import itertools
    choices = ['none'] + [_[0] + _[1] for _ in itertools.product(cfg_roots, suffixes)]
    recording_config = EnumField(choices=tuple([(_, _) for _ in choices]), default='none')
    target = NPArrayBlobField(np.float, null=True, blank=True, editable=True)  # entry point coordinates

    class Meta:
        db_table = u'procedure'

    def __unicode__(self):
        return self.name


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
    subject = models.ForeignKey(Subject, related_name="_detail_values", on_delete=models.CASCADE)
    detail_type = models.ForeignKey(DetailType, on_delete=models.CASCADE)
    value = models.CharField(max_length=135, null=True, blank=True)

    class Meta:
        db_table = u'subject_detail_value'
        unique_together = ("subject", "detail_type")

    def __unicode__(self):
        return u"%s=%s" % (self.detail_type.name, self.value)


class Datum(models.Model):
    # mandatory
    datum_id = models.AutoField(primary_key=True)
    procedure = models.ForeignKey(Procedure, on_delete=models.CASCADE, related_name="procedure")
    number = models.PositiveIntegerField(null=False, default=0)
    span_type = EnumField(choices=(('trial', 'trial'), ('day', 'day'), ('period', 'period')))
    # optional
    # is_good = models.BooleanField(null=False, default=True)
    is_good = NPArrayBlobField(np.bool, null=True, blank=True, editable=True)
    start_time = models.DateTimeField(blank=True, null=True, default=datetime.datetime.now)
    stop_time = models.DateTimeField(blank=True, null=True, default=None)
    # ===========================================================================
    # _detail_types = models.ManyToManyField(DetailType, through="DatumDetailValue",
    #                    related_name="+")  # no need for a detail_type to know ALL its values.
    # _feature_types = models.ManyToManyField(FeatureType, through="DatumFeatureValue", related_name="+")
    # ===========================================================================
    trials = models.ManyToManyField("self",
                                    db_table=u'datum_has_datum',
                                    symmetrical=False,
                                    limit_choices_to={'span_type': 'trial'},
                                    related_name="periods",
                                    )

    class Meta:
        db_table = u'datum'
        # unique_together = ("subject", "number", "span_type")
        unique_together = ("procedure", "number", "span_type")

    def save(self):
        if self.number == 0:
            # sub_dat =
            # Datum.objects.filter(subject=self.subject).filter(span_type=self.span_type).order_by('-number')[0]
            # self.number = sub_dat[0].number + 1 if sub_dat else 1

            # Fixed error when no data are present
            sub_dat = Datum.objects.filter(procedure=self.procedure).filter(span_type=self.span_type). \
                order_by('-number')
            self.number = sub_dat[0].number + 1 if sub_dat else 1
        if not self.stop_time:
            self.stop_time = (self.start_time + datetime.timedelta(seconds=1)) \
                if self.span_type == 'trial' else (self.start_time + datetime.timedelta(days=1))
        super(Datum, self).save()
        
    def __unicode__(self):
        return u"%s - %i" % (self.span_type, self.number)
    
    def feature_values_dict(self):  # return a dict of detail values.
        return dict([(item.feature_type.name, item.value) for item in self._feature_values.all()])

    def update_dfv(self, key, value):
        new_dfv = DatumFeatureValue.objects.get_or_create(
            datum=self, feature_type=FeatureType.objects.get_or_create(name=key)[0])[0]
        new_dfv.value = value
        new_dfv.save()
        return value

    def detail_values_dict(self):  # return a dict of detail values.
        return dict([(item.detail_type.name, item.value) for item in self._detail_values.all()])

    def update_ddv(self, key, value):
        new_ddv = DatumDetailValue.objects.get_or_create(
            datum=self, detail_type=DetailType.objects.get_or_create(name=key)[0])[0]
        new_ddv.value = value
        new_ddv.save()

    # ===========================================================================
    # def copy_details_from(self,ref_datum):
    #    ref_details = ref_datum.detail_values_dict()
    #    for kk in ref_details:
    #        if kk in ['BG_start_ms', 'BG_stop_ms'] or\
    #            (kk in ['MEP_start_ms', 'MEP_stop_ms', 'MEP_chan_label']) or\
    #            (kk in ['MR_start_ms', 'MR_stop_ms', 'HR_start_ms', 'HR_stop_ms', 'HR_chan_label']):
    #            self.update_ddv(kk,ref_details[kk])
    #    
    # ===========================================================================

    def extend_stop_time(self):
        td = datetime.timedelta(minutes=5) if self.span_type == 'period' else datetime.timedelta(seconds=1)
        new_time = datetime.datetime.now() + td
        if new_time > self.stop_time:
            self.stop_time = new_time

    if False:  # Remove code to calculate features.
        from serf.tools.features import hreflex_features as feature_functions
        def recalculate_child_feature_values(self):
            # REcalculate implies we want to calculate using period's details.
            if self.span_type == 'period':
                my_trials = self.trials.all()
                return [tr.calculate_all_features(refdatum=self) for tr in my_trials]

        def calculate_all_features(self, refdatum=None):
            return [self.calculate_value_for_feature_name(dfv.feature_type.name, refdatum=refdatum) for dfv in self._feature_values]

        def calculate_value_for_feature_name(self, fname, refdatum=None):
            # import SERF.APIextension.feature_functions
            fxn = getattr(feature_functions, fname)  # pulls the name of the function from the feature_functions module.
            return self.update_dfv(fname, fxn(self, refdatum=refdatum))


class DatumStore(models.Model):
    datum = models.OneToOneField(Datum, primary_key=True, related_name="store", on_delete=models.CASCADE)
    x_vec = NPArrayBlobField(np.float, null=True, blank=True, editable=True)  # Exclusively t_vec because erp
    dat_array = NPArrayBlobField(np.int16, null=True, blank=True, editable=True)  # is a recorded time series segment
    n_channels = models.PositiveSmallIntegerField(null=True, blank=True)
    n_samples = models.PositiveIntegerField(null=True, blank=True)
    channel_labels = CSVStringField(null=True, blank=True)

    class Meta:
        db_table = u'datum_store'

    def __unicode__(self):
        return u"%i samples x %i channels" % (self.n_samples, self.n_channels) if self.n_samples else "EMPTY"

    def get_data(self):
        return self.dat_array.reshape((self.n_channels, self.n_samples))

    def set_data(self, values):
        self.dat_array = values
        self.n_channels, self.n_samples = values.shape
        self.save()
    data = property(get_data, set_data)


class DatumFeatureValue(models.Model):
    datum_feature_id = models.AutoField(primary_key=True)
    datum = models.ForeignKey(Datum, related_name="_feature_values", on_delete=models.CASCADE)
    feature_type = models.ForeignKey(FeatureType, on_delete=models.CASCADE)
    value = models.FloatField(null=True, blank=True)
    
    class Meta:
        db_table = u'datum_feature_value'
        unique_together = ("datum", "feature_type")

    def __unicode__(self):
        return u"%s=%f" % (self.feature_type.name, self.value)


class DatumFeatureStore(models.Model):
    dfv = models.OneToOneField(DatumFeatureValue, primary_key=True, related_name="store", on_delete=models.CASCADE)
    x_vec = NPArrayBlobField(np.float, null=True, blank=True, editable=True)  # e.g., Hz
    dat_array = NPArrayBlobField(np.float, null=True, blank=True, editable=True)  # e.g., psd values at each Hz
    n_channels = models.PositiveSmallIntegerField(null=True, blank=True)
    n_features = models.PositiveIntegerField(null=True, blank=True)
    channel_labels = CSVStringField(null=True, blank=True)

    class Meta:
        db_table = u'datum_feature_value_store'

    def __unicode__(self):
        return u"%i features x %i channels" % (self.n_features, self.n_channels) if self.n_channels else "EMPTY"

    def get_data(self):
        return self.dat_array.reshape((self.n_channels, self.n_features))

    def set_data(self, values):
        self.dat_array = values
        self.n_channels, self.n_features = values.shape
        self.save()
    data = property(get_data, set_data)


class DatumDetailValue(models.Model):
    datum = models.ForeignKey(Datum, related_name="_detail_values", on_delete=models.CASCADE)
    detail_type = models.ForeignKey(DetailType, on_delete=models.CASCADE)
    value = models.CharField(max_length=135, null=True, blank=True)

    class Meta:
        db_table = u'datum_detail_value'
        unique_together = ("datum", "detail_type")

    def __unicode__(self):
        return u"%s=%s" % (self.detail_type.name, self.value)
