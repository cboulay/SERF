import os
from setuptools import setup

with open(os.path.join(os.path.dirname(__file__), 'README.md')) as readme:
    README = readme.read()

# allow setup.py to be run from any path
os.chdir(os.path.normpath(os.path.join(os.path.abspath(__file__), os.pardir)))

setup(
    name='django-eerfapp',
    version='0.8',
    packages=['eerfapp', 'eerfhelper'],
    include_package_data=True,
    license='BSD License',  # example license
    description='A simple Django app to...',
    long_description=README,
    url='https://github.com/cboulay/EERF',
    author='Chadwick Boulay',
    author_email='chadwick.boulay@gmail.com',
    classifiers=[
        'Environment :: Web Environment',
        'Framework :: Django',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: BSD License',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        'Topic :: Internet :: WWW/HTTP',
        'Topic :: Internet :: WWW/HTTP :: Dynamic Content',
    ],
)
