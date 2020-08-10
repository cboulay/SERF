# boot_django.py
#
# This file sets up and configures Django. It's used by scripts that need to
# execute as if running in a Django server.
import os
import django
from django.conf import settings


BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__)))
USER_DIR = os.path.expanduser("~")
db_default_kwargs = {}
if os.path.isfile(os.path.join(USER_DIR, 'my_serf.cnf')):
    db_default_kwargs = {"OPTIONS": {"read_default_file": os.path.join(USER_DIR, "my_serf.cnf")}}


def boot_django():
    settings.configure(
        BASE_DIR=BASE_DIR,
        DEBUG=True,
        DATABASES={
            "default": {
                "ENGINE": "django.db.backends.mysql",
                "NAME": "serf",
                "USER": "root",
                **db_default_kwargs  # read_default_file, if found. Specified values can overwrite above values.
            }
        },
        INSTALLED_APPS=(
            "serf",
        ),
    )
    django.setup()
