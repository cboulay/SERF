# Evoked Electrophysiological Response Feedback (EERF)

This repository contains some tools to manage and analyze evoked electrophysiological response data.
The data are stored in a database. The data are accessed either through an API mediated by Django (a Python package), or by Matlab.
There are also some scripts, in both Python and Matlab, to help with data management and analysis.

- [eerfapp](https://github.com/cboulay/EERF/tree/master/eerfapp) is a [Django](https://www.djangoproject.com/) (v >= 1.7) app.
- eerfapp.sql Is some SQL to add some functionality when using non-Django API.
- [eerfhelper](https://github.com/cboulay/EERF/tree/master/eerfhelper) is a simple 
Python package that contains a few helper functions and classes for working with the data.
- [eerfmatlab](https://github.com/cboulay/EERF/tree/master/eerfmatlab) contains 
some tools for working with the data in Matlab (wildly outdated).
- models.png is an image showing the relations between tables in the schema.
- setup.py is a script to install eerfhelper (TODO: Remove reliance on installing it as a package).
- standalone.py has some examples for how to interact with the data in Python without running a webserver.

## Installation

### Python and Django and Databases

The main parts of these tools are the database and its API. The database
schema is installed and configured using (Django)[https://www.djangoproject.com/download/],
a (Python)[https://www.python.org/]-based web framework.

If you do not already have them installed, go ahead and install Python then Django.
Note that I used Python 2.7.6 (via Canopy)[https://enthought.com/products/canopy/academic/]
and Django 1.7b1 when writing this guide.

As part of the Django installation, you should (setup your database)[https://docs.djangoproject.com/en/dev/topics/install/#database-installation].
I used MySQL Community Server 5.6.17 (any DBMS should work, but converting Elizan data requires MySQL).
I used the MyISAM storage engine (because InnoDB is harder to tweak for performance with Elizan data)
and I used the [MySQL-Python](https://pypi.python.org/pypi/MySQL-python) connector.
On a Mac, it may be necessary to add both the MySQL bin and lib directories to both the user path and system path.

After Python and Django are installed, proceed with the Django tutorial 
(found on the Django website; not linked because they are version-specific).
Some key steps you’ll need (please consult Django documentation if these fail):
1 - Create a database named `mysite`. e.g., `echo "create database mysite character set utf8” | mysql -uroot`
2 - Create the Django project. `django-admin.py startproject mysite`
3 - Edit mysite/mysite/settings.py to point to your database. `’ENGINE’: ‘django.db.backends.mysql’, ’NAME’: ‘mysite’, ’USER’: ‘root’, ‘HOST’: ’127.0.0.1’, ‘PORT’: ‘3306’`
4 - Install the base Django tables. `python manage.py migrate`

#### Other Python packages
Canopy should contain all the packages you need. If not using Canopy,
you need numpy, scipy, matplotlib, ... (more to come).

#### Installing eerfhelper
Change to the eerfhelper directory and run `python setup.py install`.
TODO: Instead of installing it, try to make it sufficient to leave it in place
and rely on its folder being in the path (usually true).

#### Installing eerfapp

- Copy eerfapp folder, eerfapp.sql, eerfhelper folder next to your project's `manage.py`.
- Edit your Django project's settings.py file and add 'eerfapp' to the list of INSTALLED_APPS.
- Skip this step because I’ve done it for you: `python manage.py makemigrations eerfapp`
- `python manage.py migrate`
- Edit mysite/mysite/urls.py and add `url(r'^eerfapp/', include('eerfapp.urls')),` before `url(r'^admin/', include(admin.site.urls)),`

If you get an error about missing sqlparse then you can either install it (`pip install sqlparse`) or turn off debugging in settings.py.

#### Installing SQL triggers

While not strictly necessary, there are some triggers in eerfapp.sql that add some features.
- Automatically log a new entry or a change to subject_detail_value
- Automatically set the stop_time field of a datum to +1s for trials or +1 day for days/periods.*
- Automatically set the number of a new datum to be the next integer greater than the latest for that subject/span_type.*

*(Only necessary if using Matlab or other non-Django interface,
otherwise this feature is built-in to eerfapp)

These triggers can be installed by opening a shell and running
`mysql -uroot mysite < eerfapp.sql`

### Interacting with the data...

Installing the database back-end is now done.

[BCPyElectrophys](https://github.com/cboulay/BCPyElectrophys) should now be able to use this ORM.

#### ...In a web browser

In a terminal or command-prompt, change to the my site directory and execute
`python manage.py runserver`.
This will start the development server and tell you the URL the server is running on.
Open a browser and navigate to the specified URL and append `/admin/` to the end of the URL.
Enter the credentials you specified in the previous step. This will provide you with basic access to the database models.

You can also go to URL/eerfapp/ . These are pages for interacting with eerfapp. Some of the pages that come with eerfapp require your project to have jquery and flot available.

TODO: Change the static\*.js to use relative paths.

#### ...In a custom Python program

See [standalone.py](https://github.com/cboulay/EERF/tree/master/standalone.py)
for an example of how to load the data into Python without using a web server.

#### ...In a custom non-Python program

Note that I cannot currently get non-Django interfaces to do CASCADE ON DELETE.
This is because Django creates foreign keys with a unique hash, and I cannot
use custom SQL (e.g., via migrations) to access the key name, drop it, then
add a new foreign key constraint with CASCADE ON DELETE set to on.

Thus, to delete using an API other than Django, you'll have to delete items
in order so as not to violate foreign key constraints.
For example, to delete a subject, you'll have to delete all of its data in this order:

DatumFeatureValue > DatumDetailValue > DatumStore > Datum > SubjectDetailValue > SubjectLog > Subject

### Tips for installing MySQL

Make sure your data directory is owned by mysql, group wheel, with drwxr-xr-x.
Create a defaults file (usually /etc/my.cnf) with all of your settings.
Run `sudo mysql_install_db --user=mysql --defaults-file=/etc/my.cnf`
Run `mysqld_safe & --defaults-file=/etc/my.cnf`
It is not necessary to specify the defaults file when using the default location (/etc/my.cnf).