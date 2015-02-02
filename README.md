# Evoked Electrophysiological Response Feedback (EERF)

EERF is a [Django](https://www.djangoproject.com/) web app and some helper tools to manage and analyze evoked electrophysiological response data.
The data can be analyzed in real-time and complex features can be extracted from the data to drive feedback.

## Contents List

- [django-eerf](django-eerf/README.md) is a distribution containing my eerfapp Django web app and eerfhelper to facilitate use of this app outside of the web server context.
- eerfapp.sql Is some SQL to add some functionality when using non-Django API.
- [eerfmatlab](eerfmatlab/REAMDE.md) contains some tools for working with the data in Matlab (this is very outdated).

- setup.py is a script to install eerfhelper (TODO: Remove reliance on installing it as a package).
- standalone.py has some examples for how to interact with the data in Python without running a webserver.

## Installation and setup

1. Install Django and all its dependencies. See [INSTALL.md](./INSTALL.md) for how I setup my system.
2. Install [django-eerf](django-eerf/README.md)


## EERFAPP

### Installation
- Copy eerfapp folder, eerfapp.sql, eerfhelper folder next to your project's `manage.py`.
- Edit your Django project's settings.py file and add 'eerfapp' to the list of INSTALLED_APPS.
- Skip this step because I’ve done it for you: `python manage.py makemigrations eerfapp`
- `python manage.py migrate`
- Edit mysite/mysite/urls.py and add `url(r'^eerfapp/', include('eerfapp.urls')),` before `url(r'^admin/', include(admin.site.urls)),`

If you get an error about missing sqlparse then you can either install it (`pip install sqlparse`) or turn off debugging in settings.py.

TODO: [Make as a package](https://docs.djangoproject.com/en/dev/intro/reusable-apps/)

### eerfhelper

Change to the eerfhelper directory and run `python setup.py install`.
TODO: Instead of installing it, try to make it sufficient to leave it in place
and rely on its folder being in the path (usually true).


### Additional SQL triggers

While not strictly necessary, there are some triggers in eerfapp.sql that add some features.
- Automatically log a new entry or a change to subject_detail_value
- Automatically set the stop_time field of a datum to +1s for trials or +1 day for days/periods.*
- Automatically set the number of a new datum to be the next integer greater than the latest for that subject/span_type.*

*(Only necessary if using Matlab or other non-Django interface,
otherwise this feature is built-in to eerfapp)

These triggers can be installed by opening a shell and running
`mysql -uroot mysite < eerfapp.sql`

## Using EERFAPP...

Installing the database back-end is now done.

[BCPyElectrophys](https://github.com/cboulay/BCPyElectrophys) should now be able to use this ORM.

### ...In a web browser

In a terminal or command-prompt, change to the my site directory and execute
`python manage.py runserver`.
This will start the development server and tell you the URL the server is running on.
Open a browser and navigate to the specified URL and append `/admin/` to the end of the URL.
Enter the credentials you specified in the previous step. This will provide you with basic access to the database models.

You can also go to URL/eerfapp/ . These are pages for interacting with eerfapp.

TODO: Change the static\*.js to use relative paths.

### ...In a custom Python program

See [standalone.py](https://github.com/cboulay/EERF/tree/master/standalone.py)
for an example of how to load the data into Python without using a web server.

### ...In a custom non-Python program

Note that I cannot currently get non-Django interfaces to do CASCADE ON DELETE.
This is because Django creates foreign keys with a unique hash, and I cannot
use custom SQL (e.g., via migrations) to access the key name, drop it, then
add a new foreign key constraint with CASCADE ON DELETE set to on.

Thus, to delete using an API other than Django, you'll have to delete items
in order so as not to violate foreign key constraints.
For example, to delete a subject, you'll have to delete all of its data in this order:

DatumFeatureValue > DatumDetailValue > DatumStore > Datum > SubjectDetailValue > SubjectLog > Subject

## Additional Tips for installing MySQL

You may need to `chown -R mysql:wheel datadir` and `chmod -R 755 datadir`
Create a defaults file (usually /etc/my.cnf) with all of your settings. You can use the provided my.cnf to start.
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