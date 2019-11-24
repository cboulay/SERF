## Installing Python and Django and Databases

The most important parts of these tools are the database and its interfaces.
The database schema is installed and configured using [Django](https://www.djangoproject.com/download/),
 a [Python](https://www.python.org/)-based web framework.

To get up and running, we need a database server, Python, Django, the python-database connector,
 Python's scientific packages, and some other Python packages. Platform-specific instructions are below.

### On OS X

1. Install [homebrew](http://brew.sh/).
1. `brew install mysql`
1. Optional - Change default data dir
    * `mkdir /path/to/datadir`
    * `sudo mysqld --initialize-insecure --user=`whoami` --basedir="$(brew --prefix mysql)" --datadir=/path/to/datadir`
    * You may need to `chown -R mysql:wheel /path/to/datadir` and `chmod -R 755 /path/to/datadir`
    * Add a `datadir` line to my.cnf (see below))
1. Edit ~/.profile and add the following lines.
    `export PATH=/usr/local/mysql/bin:$PATH`
    `export PATH=/usr/local/mysql/lib:$PATH`
1. `source ~/.profile` or you may have to close and reopen terminal.
1. Run the server `mysql.server start` or `mysqld_safe &`
1. [Install conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/macos.html#installing-on-macos)
1. Create or activate your conda environment. e.g. to create: `conda create -n sql python=3.6`
    * `source activate sql`
1. `conda install django numpy scipy pyqt qtpy pyqtgraph mysqlclient openssl`

### On Linux

First we'll install and configure MySQL server.
1. [Follow these instructions](https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-18-04)
1. Optional - [Change default datadir](https://www.digitalocean.com/community/tutorials/how-to-move-a-mysql-data-directory-to-a-new-location-on-ubuntu-18-04)
1. Create or activate your conda environment. e.g. to create: `conda create -n sql python=3.6`
    * `source activate sql`
1. `conda install django numpy scipy pyqt qtpy pyqtgraph mysqlclient openssl=1.0.2r`

### On Windows

TODO

## Configuring the database server and Django

Though any DBMS should work, I use MySQL because some of the data I work with were originally recorded into MySQL.
I use the MyISAM storage engine because I had trouble getting good performance out of InnoDB when working with these old data.
If you followed the instructions above then mysql and its python connector should already be installed.

* You need a settings file to specify the MyISAM storage engine and some other options.
    (Use any of the following locations for your settings file: /etc/my.cnf /etc/mysql/my.cnf /usr/local/etc/my.cnf ~/.my.cnf)
    ```
    [mysqld]
    default-storage-engine = MyISAM
    query_cache_type = 1
    key_buffer_size = 2G
    query_cache_limit = 400M
    ```

Many of the instructions are from the [Django tutorial](https://docs.djangoproject.com/en/2.2/intro/tutorial02/):

1. Create a Django project
	1. `cd ~`
	1. `mkdir django_eerf`
	1. `cd django_eerf`
	1. `django-admin startproject expdb`
	1. `cd expdb`
1. Configure the Django project.
    1. Edit expdb/settings.py . In the Database section, under 'default', change the ENGINE and NAME, and add OPTIONS:
    ```
    ’ENGINE’: ‘django.db.backends.mysql’,
    ’NAME’: ‘expdb’,
    'HOST': '127.0.0.1',
    'USER': 'username',
    'PASSWORD': 'password',
    'OPTIONS': {'read_default_file': '/path/to/my.cnf'}
    ```
1. Create the Django project database.
    - `mysql -uroot -p`
    - `create database expdb character set utf8;`
    - `exit;`
1. Install the base Django tables. From ~/Documents/django_eerf/expdb/ `python manage.py migrate`
1. Test Django
    - `python manage.py runserver`
    - Navigate to `http://127.0.0.1:8000/`

You are now ready to install the Django [eerf web application](django-eerf/README.md).

## Additional Tips for installing MySQL
Create a defaults file (usually /etc/my.cnf) with all of your settings. You can use the provided my.cnf to start.
Run `sudo mysql_install_db --user=mysql --defaults-file=/etc/my.cnf`
Run `mysqld_safe & --defaults-file=/etc/my.cnf`
It is not necessary to specify the defaults file when using the default location (/etc/my.cnf).
