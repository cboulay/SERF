# Evoked Electrophysiological Response Feedback (EERF)

EERF is a set of tools to manage and analyze evoked electrophysiological response data.
The data can be analyzed in real-time and complex features can be extracted from the data to drive feedback.

The core of EERF is the database backend.
The database schema is designed to provide a complete and flexible representation of epoched neurophysiological data.

EERF also contains several interfaces for interacting with the database.
There is the Django Python ORM, the Django webserver, and a basic Matlab ORM.

There are also some scripts, in both Python and Matlab, to help with data management and analysis.

## Contents List

- [eerfapp](https://github.com/cboulay/EERF/tree/master/eerfapp) is a [Django](https://www.djangoproject.com/) (v >= 1.7) app.
- eerfapp.sql Is some SQL to add some functionality when using non-Django API.
- [eerfhelper](https://github.com/cboulay/EERF/tree/master/eerfhelper) is a simple 
Python package that contains a few helper functions and classes for working with the data.
- [eerfmatlab](https://github.com/cboulay/EERF/tree/master/eerfmatlab) contains 
some tools for working with the data in Matlab (this is very outdated).
- models.png is an image showing the relations between tables in the schema.
- setup.py is a script to install eerfhelper (TODO: Remove reliance on installing it as a package).
- standalone.py has some examples for how to interact with the data in Python without running a webserver.

## Installation

Note: If you already have a working Django installation, you can skip ahead to "Installing EERF app".

### Python and Django and Databases

The most important parts of these tools are the database and its interfaces. The database schema is installed and configured using [Django](https://www.djangoproject.com/download/), a [Python](https://www.python.org/)-based web framework.

To get up and running, we need a database server, Python, Django, the python-database connector, Python's scientific packages, and some other Python packages. Platform-specific instructions are below.

#### Installing on OS X.

1. Install [homebrew](http://brew.sh/).
2. `brew install python`
3. `pip install numpy`
4. `brew install gcc`
5. `pip install scipy`
6. `brew install freetype`
7. `pip install matplotlib`
8. `pip install ipython[all]`
9. `brew install pyqt`
10. `pip install django`
11. `brew install mysql`
12. Edit ~/.profile and add the following lines.
    export PATH=/usr/local/mysql/bin:$PATH
    export PATH=/usr/local/mysql/lib:$PATH
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
13. `source ~/.profile` or you may have to close and reopen terminal.
14. `pip install mysql-python`
15. `pip install spyder`

#### Installing on Windows

TODO

#### Setting up the database server and Django

Though any DBMS should work, I use MySQL because some of the data I work with were originally recorded in MySQL. I use the MyISAM storage engine because I had trouble getting good performance out of InnoDB when working with these old data. If you followed the instructions above then mysql and its python connector should already be installed.
Many of the instructions are from the [Django tutorial](https://docs.djangoproject.com/en/dev/intro/tutorial01/):

1. Configure the database server.
    1. Create the directory where your mysql data will reside. I used `mkdir /Volumes/STORE/eerfdata`
    2. `mysql_install_db --verbose --user=root --basedir="$(brew --prefix mysql)" --datadir=/Volumes/STORE/eerfdata --tmpdir=/tmp`
    3. Specify the data directory in my.cnf . You may choose to edit and use the one from this repo then place it in your /etc/my.cnf
    4. Run the server `mysqld_safe &`
2. Create a Django project. From ~/Documents/Django\ Projects/ `django-admin startproject mysite`
3. Configure the Django project.
    1. Edit mysite/settings.py to point to the database. `’ENGINE’: ‘django.db.backends.mysql’, ’NAME’: ‘mysite’, ’USER’: ‘root’, ‘HOST’: ’127.0.0.1’, ‘PORT’: ‘3306’`
    2. Create the Django project database.
        `mysql -uroot`
        `create database mysite character set utf8;`
        `exit;`
4. Install the base Django tables. From ~/Documents/Django\ Projects/mysite/ `python manage.py migrate`
5. Test Django
    `python manage.py runserver`
    Navigate to `http://127.0.0.1:8000/`

#### Installing eerfhelper

Change to the eerfhelper directory and run `python setup.py install`.
TODO: Instead of installing it, try to make it sufficient to leave it in place
and rely on its folder being in the path (usually true).

### Installing eerfapp

- Copy eerfapp folder, eerfapp.sql, eerfhelper folder next to your project's `manage.py`.
- Edit your Django project's settings.py file and add 'eerfapp' to the list of INSTALLED_APPS.
- Skip this step because I’ve done it for you: `python manage.py makemigrations eerfapp`
- `python manage.py migrate`
- Edit mysite/mysite/urls.py and add `url(r'^eerfapp/', include('eerfapp.urls')),` before `url(r'^admin/', include(admin.site.urls)),`

If you get an error about missing sqlparse then you can either install it (`pip install sqlparse`) or turn off debugging in settings.py.

TODO: [Make as a package](https://docs.djangoproject.com/en/dev/intro/reusable-apps/)

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

You can also go to URL/eerfapp/ . These are pages for interacting with eerfapp.

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

Consider adding the following to my.cnf
```
default-storage-engine = MyISAM
query_cache_type = 1
key_buffer_size = 2G
query_cache_limit = 400M
```