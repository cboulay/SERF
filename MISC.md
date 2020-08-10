## Developing in Django

Django has a [good tutorial](https://docs.djangoproject.com/en/3.0/intro/tutorial01/) to familiarize you with the structure of the project you just built. To send commands to your server, run `python manage.py shell` in your expdb project. [Here are some commands you can try](https://docs.djangoproject.com/en/3.0/intro/tutorial02/#playing-with-the-api). Running commands like this in REPL may not be ideal for development. If you wish to run scripts that call and write to the database, you have to include the following in the script you wish to run:
 
```python
from django.core.management import execute_from_command_line
os.environ['DJANGO_SETTINGS_MODULE'] = 'expdb.settings'
execute_from_command_line()
```

Below is an example where I pass some multidimensional random data into the server, retrieve it, and compare the their values (sent as a blob, retrieved in bytes).

```python
import os
import pdb
import numpy as np
from django.core.management import execute_from_command_line
os.environ['DJANGO_SETTINGS_MODULE'] = 'expdb.settings'
execute_from_command_line()
from eerfapp.models import *

# Retrieve sample subject created with django admin
subj1 = Subject.objects.all()[0]
# Create if Datum doesn't exist
if len(Datum.objects.all()) == 0:
    data1 = Datum(datum_id=1, subject=subj1, number=1)
    data1.span_type = 'trial'
    data1.save()
# Retrieve sample Datum
data1 = Datum.objects.filter(subject=subj1)[0]
# Create Sample data
ch_names = ['Cz', 'FCz', 'FP1', 'FP2', 'OZ']
samples = [np.random.rand(512) for x in np.arange(0, len(ch_names))]
orig = np.swapaxes(samples, 0, 0)
# Create entry if doesn't exist
if len(DatumStore.objects.all()) == 0:
    data_pkt = DatumStore(datum=data1)
else:
    data_pkt = DatumStore.objects.all()[0]
# Modify entry and save
data_pkt.set_data(orig)
data_pkt.save()
# Retrieve sample DatumStore
data_pkt = DatumStore.objects.filter(datum=data1)[0]
# Compare orig between local and server
print("Notice that retrieved data is in bytes.", np.frombuffer(data_pkt.erp).shape)
# Reshape it to stored sample
retrieved_data = np.frombuffer(data_pkt.erp).reshape(orig.shape)
# Compare if retrieved data is the same as generated data
print("The retrieved data and sent data are equal: ", np.array_equal(retrieved_data, orig))
print("The dtypes are equal: ", retrieved_data.dtype == orig.dtype)
print("The nbytes are equal: ", retrieved_data.nbytes == orig.nbytes)
```


## Troubleshooting

  * `FileNotFoundError: [WinError 3] The system cannot find the path specified...` or `URL pattern for eerfapp.views is invalid`
    * For both these types of errors, ensure you have eerfapp and eerfhelper folders in your site-packages.
      * You can get these folders by running `python setup.py install` in `eerf/django-eerf` and navigating to `.../build/lib`
  * `caching_sha2_password cannot be loaded`
    * You may need to manually modify your password using this command:
      * ALTER USER 'youruser'@'localhost' IDENTIFIED WITH mysql_native_password BY 'yourpassword';
  * Ensure MySQL is setup properly (ie: `pip install mysqlclient`)
    * Linux and Mac requires MySQL development headers and libraries.
      * Ubuntu: `sudo apt-get install python-dev default-libmysqlclient-dev`
      * Arch: via [AUR](https://aur.archlinux.org/packages/libmysqlclient/), makepkg
    * On Windows, there are binary wheels you can install without MySQLConnector/C or MSVC

If you get an error about missing sqlparse then you can either install it (`pip install sqlparse`) or turn off debugging in settings.py.


FOR CHAD
-------

Development cycle, in django-eerfapp directory.

1. `pip uninstall django-eerfapp` uninstalls what might already be there.
3. `pip install -e .` installs new dist.

If models.py changed then you should recreate the migrations.

1. `python ~/Documents/Django\ Projects/expdb/manage.py makemigrations eerfapp`

TODO
----

Change the static\*.js to use relative paths.
