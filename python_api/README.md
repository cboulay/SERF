# Evoked Electrophysiological Response Analysis Toolbox (EERAT)

## Python data API

This module provides access to the EERAT datastore from Python.
In addition to simple reading and writing data, there are some functions for performing more complex analyses 
that can either be triggered automatically or that can be called manually.

### Installing Python and the API's dependencies

Dependencies include SQLAlchemy, Numpy, and Scipy.
Installing Numpy and Scipy can be tricky so please refer to their respective sites for instructions.

### Interacting with the data

There are some GUIs available to interact with the data for either monitoring and adjusting online analysis
or offline analysis. (TODO: Links to the GUIs).

Or you can access the data and the add-on API functions directly from a Python console:

```python

from EeratAPI.API import *
my_subj_type=get_or_create(Subject_type, Name='BCPy_healthy')
my_subject=get_or_create(Subject, Name='CHAD_TEST', subject_type=my_subj_type, species_type='human')
#Assumes data, and that last is a trial. See how to create trials further below.
temp_store = my_subject.data[-1].store
x=temp_store['x_vec']
y=temp_store['data']
chan_labels=temp_store['channel_labels']
#Note that the following assumes you are using IPython with the -pylab switch, or equivalent
plots=plot(x,y.T,label=chan_labels)
legend(plots,chan_labels)

```

#### Extended online analysis

Beyond plotting single trials there are futher analyses built-in to the OnlineAPIExtension.
Many of these are for analyzing periods and the trials within them.

```python

from EeratAPI.OnlineAPIExtension import *
my_dat_type=get_or_create(Datum_type, Name='hr_baseline')
now_per=my_subject.get_now_period_of_type(my_dat_type)

```

now_per is a Datum (period) instance for the provided Datum_type (my_dat_type).

We can update the period store as the average of its (good) trials:

```python
now_per.update_store()
temp_store = now_per.store
x=temp_store['x_vec']
y=temp_store['data']
chan_labels=temp_store['channel_labels']
plots=plot(x,y.T,label=chan_labels)
legend(plots,chan_labels)
```

Or we can model the ERP's input-output curve for this period and get estimates of its parameters.

```python
#Possible values of model_type are 'halfmax' (default) and 'threshold' 
parms,parms_err = now_per.model_erp(model_type='threshold')

x = now_per._get_child_details('dat_Nerve_stim_output')
x = x.astype(np.float)
y = now_per._get_child_features('HR_aaa')
y_est = my_sigmoid(x,*list(parms))
pylab.plot(x, y, 'o', label='data')
pylab.plot(x,y_est, label='fit')
legend(loc='upper left')
```

### Creating data

Creating a trial requires the presence of its parent period (above). Any new trials created during the
time defined by this period will inherit the period's details by default.
When creating a new trial, the SQL database has triggers to create the trial's
default details (from the period) and feature values (usually NULL by default), 
but these triggers only fire when the trial is persisted. Thus we use the API's >get_or_create method. 
To be sure the >get_or_create method does not match any existing trials, 
we have to provide it with a unique key that definitely does not exist, i.e. with Number=0.

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

We can then store some data in the trial. Storing data will typically kick off feature calculation for the datum.

```python
my_trial.store={\
	'x_vec':numpy.arange(-500,500, dtype=float)\
	, 'data':numpy.array(100*numpy.random.ranf((2,1000)), dtype=float)\
	, 'channel_labels':'Trig, EDC'}
print(my_trial.feature_values)
```

Further [online analysis apps](https://github.com/cboulay/EERAT/tree/master/python_apps/online_analysis) 
are needed for more complicated features and for getting features specific to our period object.