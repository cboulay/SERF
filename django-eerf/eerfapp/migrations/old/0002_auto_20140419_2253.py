# encoding: utf8
from django.db import models, migrations


class Migration(migrations.Migration):

    dependencies = [
        ('eerfapp', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='datum',
            name='trials',
            field=models.ManyToManyField(to='eerfapp.Datum'),
            preserve_default=True,
        ),
        migrations.AlterUniqueTogether(
            name='datum',
            unique_together=set([('subject', 'number', 'span_type')]),
        ),
    ]
