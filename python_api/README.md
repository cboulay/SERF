# Evoked Electrophysiological Response Analysis Toolbox (EERAT)

## Python data API

### Installing Python and the API's dependencies

### Interacting with the data

```python

cd D:\Tools/EERAT/ #Useful for my testing with IPython
from python_api.Eerat_sqlalchemy import *
my_subj_type=get_or_create(Subject_type, Name='BCPy healthy')
my_subject=get_or_create(Subject, Name='CHAD_TEST', subject_type=my_subj_type, species_type='human')
my_dat_type=get_or_create(Datum_type, Name='hr_baseline')
now_per=my_subject.get_now_period_of_type(my_dat_type)

```

now_per is a Datum (period) instance for the provided Datum_type (my_dat_type).
If we set any of its details then new trials created under this period will inherit those details by default. (e.g. dat_ERP_channel_label, dat_ERP_channel_id)

Now we can make a new trial. The SQL database has triggers to create the trial's default details (from the period) and feature values (usually NULL by default), but these triggers only fire when the trial is persisted. Thus we use the API's >get_or_create method. To be sure the >get_or_create method does not match any existing trials, we have to provide it with a unique key that definitely does not exist, i.e. with Number=0.

```python
#This does not persist the trial immediately, and therefore does not create detail and feature entries until after a flush.
new_trial = Datum(subject=my_subject, datum_type=my_dat_type, span_type='trial', IsGood=1)

#This creates a new trial and persists immediately, generating its default details and features.
my_trial = get_or_create(Datum\
	, subject=my_subject\
	, datum_type=my_dat_type\
	, span_type='trial'\
	, IsGood=1\
	, Number=0)

#Or we can load an old trial with the following
my_trial = my_subject.data[-1]
```

We can then store some data in the trial. Storing data will typically kick off feature calculation for the datum. Further online analysis apps are needed for more complicated features and for getting features specific to our period object.

```python
my_trial.store={\
	'x_vec':numpy.arange(-500,500, dtype=float)\
	, 'data':numpy.array(100*numpy.random.ranf((2,1000)), dtype=float)\
	, 'channel_labels':'Trig, EDC'}
print(my_trial.feature_values)
```