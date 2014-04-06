# Evoked Electrophysiological Response Feedback (EERF)

- [eerf](https://github.com/cboulay/EERF/tree/master/python/eerf) is a Django project and app.
- [eerfx](https://github.com/cboulay/EERF/tree/master/python/eerfx) is a simple Python package
that contains a few helpers for EERF. It can be installed as a Python package using setup.py
found in this directory. eerfx also contains feature_functions.py which is a list of functions for calculating features from raw ERP waveforms.
- scratch.py is a file I use for quick debugging of test code. You can ignore it.
- standalone.py has some examples for using the Django ORM outside of a Django web server environment.

### Installing Python and some dependencies

#### Before you start
If you intend on using this repo with [BCPy2000](http://bci2000.org/downloads/BCPy2000/BCPy2000.html)
and [BCPyElectrophys](https://github.com/cboulay/BCPyElectrophys) then please follow the instructions
at BCPyElectrophys first. Then return here and skip the next step on Installing Python.

### Installing Python
I used [Canopy](https://enthought.com/products/canopy/academic/), which came with Python 2.76 at the time.

### Installing a database server.
Since we will be using the database primarily with Django, it makes sense to use
Django's [database installation instructions](https://docs.djangoproject.com/en/dev/topics/install/#database-installation).
I'd like to use postgres eventually, but I am in a hurry and more familiar with MySQL, so I used that (MySQL Community Server 5.6.17).

Test that your database server is running.

#### Create a database called eerf
E.g., in MySQL, this can be done either with the Workbench (a database is also called a schema) or the command line interface.
The SQL command is `CREATE DATABASE eerf;`

#### Advanced MySQL
MySQL has many security features and optimization features. For example, it is probably not a good idea to use
the root mysql user for Django. Instead, you should create a separate mysql user that has limited read and write
access. MySQL documentation is abundant on the web.

### Installing Python packages/libraries
Python packages can be installed by [binary installers on Windows](http://www.lfd.uci.edu/~gohlke/pythonlibs/).
On any platform, Python packages can be installed using pip. pip may already be installed if you used a distribution (e.g., Canopy),
otherwise you can install it with [setup_tools](http://pypi.python.org/pypi/setuptools) using the command 'easy_install pip'.

### Installing Django
[Django](https://www.djangoproject.com/download/). I used v 1.6.2.

#### Database-Python Connector
This should already be in the Django database-installation instructions.

Note, getting [MySQL-Python](https://pypi.python.org/pypi/MySQL-python) to work
on a Mac can be rather tricky. You should add both the MySQL bin and lib directories to the path.
(Not just the user environment path, but the system path that will Python will run in.)

### Other packages
Canopy should contain all the packages you need. If not using Canopy,
you need numpy, ... (more to come).

### Installing this project/app

Install eerfx first: Change to the EERF/python directory and execute `python setup.py install`.

Configure the Django app next.
Edit python\eerf\eerf\settings.py and set the MySQL username and password, and further down set
the [TIME_ZONE](http://www.postgresql.org/docs/8.1/static/datetime-keywords.html#DATETIME-TIMEZONE-SET-TABLE). 

Tell Django to setup the database: From a console, switch to the EERF/python/eerf and execute
`python manage.py syncdb`.
During this process, you should configure your project admin username and password.
This should setup the database for use with Django.

TODO: Fix these errors

```
Failed to install custom SQL for eerfd.SubjectDetailValue model: (1064, "You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near '' at line 1")
Failed to install custom SQL for eerfd.Datum model: (1064, "You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near '' at line 1")
```

There's a bug where multi-line statements cannot be added automatically by Django. There was a workaround, but that no longer seems to work.
So, for each of the following files, copy-paste the code into your SQL editor (e.g., MySQL Workbench) and run it.
EERF/python/eerf/eerfd/sql/subjectdetailvalue.sql
EERF/python/eerf/eerfd/sql/datum.sql

Installing the database back-end is now done.

[BCPyElectrophys](https://github.com/cboulay/BCPyElectrophys) should now be able to use this ORM.

### Interacting with the data...

#### ...In a web browser

In a terminal or command-prompt, change to the EERF/python/eerf directory and execute
`python manage.py runserver`.
This will start the development server and tell you the URL the server is running on.
Open a browser and navigate to the specified URL and append `/admin/` to the end of the URL.
Enter the credentials you specified in the previous step. This will provide you with basic access to the database models.
Furthermore, you can access the /eerfd/ URL to get an interactive GUI. There isn't much data to look at just yet.

#### ...In a custom Python program

To access the ORM from within a separate Python program, we have to set the proper environment variable so the program knows where to find the ORM.
Your script should start with the following commands (change the directory as needed).

```python
import os
sys.path.append(os.path.abspath('d:/tools/eerf/python/eerf'))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "eerf.settings")
```

Now you can import the models and test it out.

```python
from eerfd.models import Subject
my_subject = Subject.objects.get_or_create(name='Test')[0]
```

See the Django documentation on how to work with these models or see [MyBCPyModules/ERPExtension](https://github.com/cboulay/MyBCPyModules/blob/master/ERPExtension.py)
for an example of how to work with the models.