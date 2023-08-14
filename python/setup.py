import os
from setuptools import setup, find_packages

with open(os.path.join(os.path.dirname(__file__), '..', 'README.md')) as readme:
    README = readme.read()


setup(
    name='serf',
    version='1.2',
    packages=find_packages() + ['serf/tools/resources'],
    package_data={"serf/tools/resources": ["*.mat"]},
    include_package_data=True,
    license='BSD License',  # example license
    description='A simple Django app to...',
    long_description=README,
    url='https://github.com/cboulay/SERF',
    author='Chadwick Boulay',
    author_email='chadwick.boulay@gmail.com',
    classifiers=[
        'Framework :: Django',
        'Intended Audience :: Developers',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
    ],

    entry_points={
        'console_scripts': ['serf-shell=serf.scripts.djangoshell:main',
                            'serf-makemigrations=serf.scripts.makemigrations:main',
                            'serf-migrate=serf.scripts.migrate:main',
                            ],
    }
)
