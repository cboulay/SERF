# Evoked Electrophysiological Response Feedback (EERF)

EERF is a [Django](https://www.djangoproject.com/) web app and some helper tools to manage and analyze evoked electrophysiological response data.
The data can be analyzed in real-time and complex features can be extracted from the data to drive feedback.

## Contents List

- [django-eerf](django-eerf/README.md) is a python package containing my eerfapp Django web app and eerfhelper to facilitate use of this app outside of the web server context.
- eerfapp.sql Is some SQL to add some functionality when using non-Django API.
- [eerfmatlab](eerfmatlab/REAMDE.md) contains some tools for working with the data in Matlab (this is very outdated).
- standalone.py has some examples for how to interact with the data in Python without running a webserver.

## Installation and setup

1. Install Django and all its dependencies. See [INSTALL.md](./INSTALL.md) for how I setup my system.
2. Install [django-eerf](django-eerf/README.md)
3. Optional (mandatory if you will use the database backend outside the Django/Python context (e.g., Matlab ORM)): Additional SQL triggers to
    - Automatically log a new entry or a change to subject_detail_value
    - Automatically set the stop_time field of a datum to +1s for trials or +1 day for days/periods.
    - Automatically set the number of a new datum to be the next integer greater than the latest for that subject/span_type.
    - From shell/terminal, run `mysql -uroot expdb < eerfapp.sql`

The web app, and especially its database backend, should now be installed.

## Using EERFAPP...

### ...In a web browser (i.e., in Django)

See [django-eerf](django-eerf/REAMDE.md).

### ...In a custom Python program

See [standalone.py](./standalone.py) for an example of how to load the data into Python without using a web server.

[BCPyElectrophys](https://github.com/cboulay/BCPyElectrophys) should now be able to use this ORM.

### ...In a custom non-Python program

e.g. [Matlab](eerfmatlab/README.md)

Note that I cannot currently get non-Django interfaces to do CASCADE ON DELETE.
This is because Django creates foreign keys with a unique hash, and I cannot
use custom SQL (e.g., via migrations) to access the key name, drop it, then
add a new foreign key constraint with CASCADE ON DELETE set to on.

Thus, to delete using an API other than Django, you'll have to delete items
in order so as not to violate foreign key constraints.
For example, to delete a subject, you'll have to delete all of its data in this order:

DatumFeatureValue > DatumDetailValue > DatumStore > Datum > SubjectDetailValue > SubjectLog > Subject