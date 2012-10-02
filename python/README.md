# Evoked Electrophysiological Response Feedback (EERF)

## Python data API

This project createts a database and API for evoked electrophysiological response data.
This database may be accessed through a simple web interface or directly from within Python.

### Installing Python and the API's dependencies

Dependencies include Numpy, ?Scipy, Django, and MySQL-python.
Numpy, Scipy, and Django all have extensive documentation on how to install those packages. Please consult their respective pages.
MySQL-python is a little tricky to install on OSX and the information is difficult to find.
Try the code below after changing the mysql directory to match your installed version.

```

>sudo -i
#export PATH=$PATH:/usr/local/mysql-5.5.17-osx10.6-x86_64/bin
#export DYLD_LIBRARY_PATH=/usr/local/mysql/lib/
#export ARCHFLAGS='-arch i386 -arch x86_64'
#export CC=gcc-4.2
#export PATH="/Library/Frameworks/Python.framework/Versions/2.7/bin:${PATH}"
#easy_install mysql-python
#sudo pip install MySQL-python==1.2.3c1

```

### Installing the database

The process is essentially the same as setting up a Django app for the first time but most of the heavy lifting is already done for you.

In a terminal or command-prompt, change to the EERF/python/eerf directory and execute
`python manage.py syncdb`
Go through the steps to create your admin account.

We need to further add some useful tools for dealing with the eerf data. Change to the EERF/python directory and execute
`python setup.py install`

### Interacting with the data

#### In a web browser

In a terminal or command-prompt, change to the EERF/python/eerf directory and execute
`python manage.py runserver`
This will tell you the URL the server is running on.
Open a browser and navigate to the specified URL and append `/admin/` to the end of the URL.
This will provide you with basic access to the database models.

#### In a custom Python program

To access the ORM from within a separate Python program, we have to set the proper environment variable so the module knows where to find the ORM. 

```python
import os
sys.path.append(os.path.abspath('d:/tools/eerf/python/eerf'))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "eerf.settings")
```

Now you can import the models and test it out.

```python
from api.models import Subject
my_subject = Subject.objects.get_or_create(name='Test')[0]
```

See the Django documentation on how to work with these models or see (MyBCPyModules/ERPExtension)[https://github.com/cboulay/MyBCPyModules/blob/master/ERPExtension.py] 
for an example of how to work with the models.

(The following is in progress)
By `import eerfx.online` into our program, we get access to a few extra functions: