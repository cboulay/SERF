=====
EERFAPP
=====

EERFAPP is a simple Django app to...

Detailed documentation is in the "docs" directory.

Quick start
-----------

1. Add "eerfapp" to your INSTALLED_APPS setting like this::

    INSTALLED_APPS = (
        ...
        'eerfapp',
    )

2. Include the eerfapp URLconf in your project urls.py like this::

    url(r'^eerfapp/', include('eerfapp.urls')),

3. Run `python manage.py migrate` to create the eerfapp models.

4. Start the development server and visit http://127.0.0.1:8000/admin/
   to ...(you'll need the Admin app enabled).

5. Visit http://127.0.0.1:8000/eerfapp/ to...
