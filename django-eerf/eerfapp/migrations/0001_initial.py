# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models, migrations
import datetime
import eerfapp.models


class Migration(migrations.Migration):

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Datum',
            fields=[
                ('datum_id', models.AutoField(serialize=False, primary_key=True)),
                ('number', models.PositiveIntegerField(default=0)),
                ('span_type', eerfapp.models.EnumField(max_length=104, choices=[(b'trial', b'trial'), (b'day', b'day'), (b'period', b'period')])),
                ('is_good', models.BooleanField(default=True)),
                ('start_time', models.DateTimeField(default=datetime.datetime.now, null=True, blank=True)),
                ('stop_time', models.DateTimeField(default=None, null=True, blank=True)),
            ],
            options={
                'db_table': 'datum',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='DatumDetailValue',
            fields=[
                ('id', models.AutoField(verbose_name='ID', serialize=False, auto_created=True, primary_key=True)),
                ('value', models.CharField(max_length=135, null=True, blank=True)),
            ],
            options={
                'db_table': 'datum_detail_value',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='DatumFeatureValue',
            fields=[
                ('id', models.AutoField(verbose_name='ID', serialize=False, auto_created=True, primary_key=True)),
                ('value', models.FloatField(null=True, blank=True)),
            ],
            options={
                'db_table': 'datum_feature_value',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='DatumFeatureStore',
            fields=[
                ('dfv', models.OneToOneField(related_name='store', primary_key=True, serialize=False, to='eerfapp.DatumFeatureValue')),
                ('x_vec', eerfapp.models.NPArrayBlobField(null=True, blank=True)),
                ('dat_array', eerfapp.models.NPArrayBlobField(null=True, blank=True)),
                ('n_channels', models.PositiveSmallIntegerField(null=True, blank=True)),
                ('n_features', models.PositiveIntegerField(null=True, blank=True)),
                ('channel_labels', eerfapp.models.CSVStringField(null=True, blank=True)),
            ],
            options={
                'db_table': 'datum_feature_value_store',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='DatumStore',
            fields=[
                ('datum', models.OneToOneField(related_name='store', primary_key=True, serialize=False, to='eerfapp.Datum')),
                ('x_vec', eerfapp.models.NPArrayBlobField(null=True, blank=True)),
                ('erp', eerfapp.models.NPArrayBlobField(null=True, blank=True)),
                ('n_channels', models.PositiveSmallIntegerField(null=True, blank=True)),
                ('n_samples', models.PositiveIntegerField(null=True, blank=True)),
                ('channel_labels', eerfapp.models.CSVStringField(null=True, blank=True)),
            ],
            options={
                'db_table': 'datum_store',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='DetailType',
            fields=[
                ('detail_type_id', models.AutoField(serialize=False, primary_key=True)),
                ('name', models.CharField(unique=True, max_length=135)),
                ('description', models.CharField(max_length=300, blank=True)),
            ],
            options={
                'db_table': 'detail_type',
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
                'db_table': 'feature_type',
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
                ('sex', eerfapp.models.EnumField(max_length=104, choices=[(b'unknown', b'unknown'), (b'male', b'male'), (b'female', b'female'), (b'unspecified', b'unspecified')])),
                ('handedness', eerfapp.models.EnumField(max_length=104, choices=[(b'unknown', b'unknown'), (b'right', b'right'), (b'left', b'left'), (b'equal', b'equal')])),
                ('smoking', eerfapp.models.EnumField(max_length=104, choices=[(b'unknown', b'unknown'), (b'no', b'no'), (b'yes', b'yes')])),
                ('alcohol_abuse', eerfapp.models.EnumField(max_length=104, choices=[(b'unknown', b'unknown'), (b'no', b'no'), (b'yes', b'yes')])),
                ('drug_abuse', eerfapp.models.EnumField(max_length=104, choices=[(b'unknown', b'unknown'), (b'no', b'no'), (b'yes', b'yes')])),
                ('medication', eerfapp.models.EnumField(max_length=104, choices=[(b'unknown', b'unknown'), (b'no', b'no'), (b'yes', b'yes')])),
                ('visual_impairment', eerfapp.models.EnumField(max_length=104, choices=[(b'unknown', b'unknown'), (b'no', b'no'), (b'yes', b'yes'), (b'corrected', b'corrected')])),
                ('heart_impairment', eerfapp.models.EnumField(max_length=104, choices=[(b'unknown', b'unknown'), (b'no', b'no'), (b'yes', b'yes'), (b'pacemaker', b'pacemaker')])),
            ],
            options={
                'db_table': 'subject',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='SubjectDetailValue',
            fields=[
                ('id', models.AutoField(verbose_name='ID', serialize=False, auto_created=True, primary_key=True)),
                ('value', models.CharField(max_length=135, null=True, blank=True)),
                ('detail_type', models.ForeignKey(to='eerfapp.DetailType')),
                ('subject', models.ForeignKey(related_name='_detail_values', to='eerfapp.Subject')),
            ],
            options={
                'db_table': 'subject_detail_value',
            },
            bases=(models.Model,),
        ),
        migrations.CreateModel(
            name='SubjectLog',
            fields=[
                ('id', models.AutoField(verbose_name='ID', serialize=False, auto_created=True, primary_key=True)),
                ('time', models.DateTimeField(default=datetime.datetime.now, null=True, blank=True)),
                ('entry', models.TextField(blank=True)),
                ('subject', models.ForeignKey(to='eerfapp.Subject')),
            ],
            options={
                'db_table': 'subject_log',
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
                'db_table': 'system',
            },
            bases=(models.Model,),
        ),
        migrations.AlterUniqueTogether(
            name='subjectdetailvalue',
            unique_together=set([('subject', 'detail_type')]),
        ),
        migrations.AddField(
            model_name='datumfeaturevalue',
            name='datum',
            field=models.ForeignKey(related_name='_feature_values', to='eerfapp.Datum'),
            preserve_default=True,
        ),
        migrations.AddField(
            model_name='datumfeaturevalue',
            name='feature_type',
            field=models.ForeignKey(to='eerfapp.FeatureType'),
            preserve_default=True,
        ),
        migrations.AlterUniqueTogether(
            name='datumfeaturevalue',
            unique_together=set([('datum', 'feature_type')]),
        ),
        migrations.AddField(
            model_name='datumdetailvalue',
            name='datum',
            field=models.ForeignKey(related_name='_detail_values', to='eerfapp.Datum'),
            preserve_default=True,
        ),
        migrations.AddField(
            model_name='datumdetailvalue',
            name='detail_type',
            field=models.ForeignKey(to='eerfapp.DetailType'),
            preserve_default=True,
        ),
        migrations.AlterUniqueTogether(
            name='datumdetailvalue',
            unique_together=set([('datum', 'detail_type')]),
        ),
        migrations.AddField(
            model_name='datum',
            name='subject',
            field=models.ForeignKey(related_name='data', to='eerfapp.Subject'),
            preserve_default=True,
        ),
        migrations.AddField(
            model_name='datum',
            name='trials',
            field=models.ManyToManyField(related_name='periods', db_table='datum_has_datum', to='eerfapp.Datum'),
            preserve_default=True,
        ),
        migrations.AlterUniqueTogether(
            name='datum',
            unique_together=set([('subject', 'number', 'span_type')]),
        ),
    ]
