# encoding: utf8
from django.db import models, migrations
import datetime
import eerfapp.models


class Migration(migrations.Migration):

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='DetailType',
            fields=[
                ('detail_type_id', models.AutoField(serialize=False, primary_key=True)),
                ('name', models.CharField(unique=True, max_length=135)),
                ('description', models.CharField(max_length=300, blank=True)),
            ],
            options={
                u'db_table': u'detail_type',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='System',
            fields=[
                ('name', models.CharField(max_length=135, serialize=False, primary_key=True)),
                ('value', models.CharField(max_length=135, blank=True)),
            ],
            options={
                u'db_table': u'system',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='FeatureType',
            fields=[
                ('feature_type_id', models.AutoField(serialize=False, primary_key=True)),
                ('name', models.CharField(unique=True, max_length=135)),
                ('description', models.CharField(max_length=135, blank=True)),
            ],
            options={
                u'db_table': u'feature_type',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='Subject',
            fields=[
                ('subject_id', models.AutoField(serialize=False, primary_key=True)),
                ('name', models.CharField(unique=True, max_length=135)),
                ('id', models.CharField(max_length=135, null=True, blank=True)),
                ('weight', models.PositiveIntegerField(null=True, blank=True)),
                ('height', models.PositiveIntegerField(null=True, blank=True)),
                ('birthday', models.DateField(null=True, blank=True)),
                ('headsize', models.CharField(max_length=135, null=True, blank=True)),
                ('sex', eerfapp.models.EnumField(max_length=104, choices=[('unknown', 'unknown'), ('male', 'male'), ('female', 'female'), ('unspecified', 'unspecified')])),
                ('handedness', eerfapp.models.EnumField(max_length=104, choices=[('unknown', 'unknown'), ('right', 'right'), ('left', 'left'), ('equal', 'equal')])),
                ('smoking', eerfapp.models.EnumField(max_length=104, choices=[('unknown', 'unknown'), ('no', 'no'), ('yes', 'yes')])),
                ('alcohol_abuse', eerfapp.models.EnumField(max_length=104, choices=[('unknown', 'unknown'), ('no', 'no'), ('yes', 'yes')])),
                ('drug_abuse', eerfapp.models.EnumField(max_length=104, choices=[('unknown', 'unknown'), ('no', 'no'), ('yes', 'yes')])),
                ('medication', eerfapp.models.EnumField(max_length=104, choices=[('unknown', 'unknown'), ('no', 'no'), ('yes', 'yes')])),
                ('visual_impairment', eerfapp.models.EnumField(max_length=104, choices=[('unknown', 'unknown'), ('no', 'no'), ('yes', 'yes'), ('corrected', 'corrected')])),
                ('heart_impairment', eerfapp.models.EnumField(max_length=104, choices=[('unknown', 'unknown'), ('no', 'no'), ('yes', 'yes'), ('pacemaker', 'pacemaker')])),
            ],
            options={
                u'db_table': u'subject',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='SubjectDetailValue',
            fields=[
                (u'id', models.AutoField(verbose_name=u'ID', serialize=False, auto_created=True, primary_key=True)),
                ('subject', models.ForeignKey(to='eerfapp.Subject', to_field='subject_id')),
                ('detail_type', models.ForeignKey(to='eerfapp.DetailType', to_field='detail_type_id')),
                ('value', models.CharField(max_length=135, null=True, blank=True)),
            ],
            options={
                u'unique_together': set([('subject', 'detail_type')]),
                u'db_table': u'subject_detail_value',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='SubjectLog',
            fields=[
                (u'id', models.AutoField(verbose_name=u'ID', serialize=False, auto_created=True, primary_key=True)),
                ('subject', models.ForeignKey(to='eerfapp.Subject', to_field='subject_id')),
                ('time', models.DateTimeField(default=datetime.datetime.now, null=True, blank=True)),
                ('entry', models.TextField(blank=True)),
            ],
            options={
                u'db_table': u'subject_log',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='Datum',
            fields=[
                ('datum_id', models.AutoField(serialize=False, primary_key=True)),
                ('subject', models.ForeignKey(to='eerfapp.Subject', to_field='subject_id')),
                ('number', models.PositiveIntegerField(default=0)),
                ('span_type', eerfapp.models.EnumField(max_length=104, choices=[('trial', 'trial'), ('day', 'day'), ('period', 'period')])),
                ('is_good', models.BooleanField(default=True)),
                ('start_time', models.DateTimeField(default=datetime.datetime.now, null=True, blank=True)),
                ('stop_time', models.DateTimeField(default=None, null=True, blank=True)),
            ],
            options={
                u'db_table': u'datum',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='DatumDetailValue',
            fields=[
                (u'id', models.AutoField(verbose_name=u'ID', serialize=False, auto_created=True, primary_key=True)),
                ('datum', models.ForeignKey(to='eerfapp.Datum', to_field='datum_id')),
                ('detail_type', models.ForeignKey(to='eerfapp.DetailType', to_field='detail_type_id')),
                ('value', models.CharField(max_length=135, null=True, blank=True)),
            ],
            options={
                u'unique_together': set([('datum', 'detail_type')]),
                u'db_table': u'datum_detail_value',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='DatumFeatureValue',
            fields=[
                (u'id', models.AutoField(verbose_name=u'ID', serialize=False, auto_created=True, primary_key=True)),
                ('datum', models.ForeignKey(to='eerfapp.Datum', to_field='datum_id')),
                ('feature_type', models.ForeignKey(to='eerfapp.FeatureType', to_field='feature_type_id')),
                ('value', models.FloatField(null=True, blank=True)),
            ],
            options={
                u'unique_together': set([('datum', 'feature_type')]),
                u'db_table': u'datum_feature_value',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='DatumStore',
            fields=[
                ('datum', models.OneToOneField(primary_key=True, to_field='datum_id', serialize=False, to='eerfapp.Datum')),
                ('x_vec', eerfapp.models.NPArrayBlobField(null=True, blank=True)),
                ('erp', eerfapp.models.NPArrayBlobField(null=True, blank=True)),
                ('n_channels', models.PositiveSmallIntegerField(null=True, blank=True)),
                ('n_samples', models.PositiveIntegerField(null=True, blank=True)),
                ('channel_labels', eerfapp.models.CSVStringField(null=True, blank=True)),
            ],
            options={
                u'db_table': u'datum_store',
            },
            bases=(models.Model,),
        ),
    ]
