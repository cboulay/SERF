## Installing Python and Django and Databases

The most important parts of these tools are the database and its interfaces. The database schema is installed and configured using [Django](https://www.djangoproject.com/download/), a [Python](https://www.python.org/)-based web framework.

To get up and running, we need a database server, Python, Django, the python-database connector, Python's scientific packages, and some other Python packages. Platform-specific instructions are below.

### On OS X

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
11. `brew install mysql`  (Using 5.7.12 at latest writing)
12. Edit ~/.profile and add the following lines.
    `export PATH=/usr/local/mysql/bin:$PATH`
    `export PATH=/usr/local/mysql/lib:$PATH`
13. `source ~/.profile` or you may have to close and reopen terminal.
14. `pip install mysqlclient`

### On Windows

TODO

## Configuring the database server and Django

Though any DBMS should work, I use MySQL because some of the data I work with were originally recorded into MySQL.
I use the MyISAM storage engine because I had trouble getting good performance out of InnoDB when working with these old data.
If you followed the instructions above then mysql and its python connector should already be installed.
Many of the instructions are from the [Django tutorial](https://docs.djangoproject.com/en/dev/intro/tutorial01/):

1. Configure the database server.
    1. Create the directory where your mysql data will reside. I used `mkdir /Volumes/STORE/eerfdata`
    1. You need a settings file to specify the MyISAM storage engine and some other options.
    You can use the my.cnf supplied in this repo as a starting point.
    `cp my.cnf /usr/local/etc/my.cnf`
    (Use any of the following locations for your settings file: /etc/my.cnf /etc/mysql/my.cnf /usr/local/etc/my.cnf ~/.my.cnf)    
    Be sure to edit its datadir.
    1. Initialize the datadir: `sudo mysqld --initialize-insecure --user=`whoami` --basedir="$(brew --prefix mysql)" --datadir=/Volumes/STORE/eerfdata`
    1. Run the server `mysql.server start` or `mysqld_safe &`
1. Create a Django project
	1. `cd ~`
	1. `mkdir django_eerf`
	1. `cd django_eerf`
	1. `django-admin startproject mysite`
1. Configure the Django project.
    1. Edit mysite/settings.py to point to the database. `’ENGINE’: ‘django.db.backends.mysql’, ’NAME’: ‘mysite’, ’USER’: ‘root’, ‘HOST’: ’127.0.0.1’, ‘PORT’: ‘3306’`
    1. Create the Django project database.
        - `mysql -uroot`
        - `create database mysite character set utf8;`
        - `exit;`
4. Install the base Django tables. From ~/Documents/django_eerf/mysite/ `python manage.py migrate`
5. Test Django
    - `python manage.py runserver`
    - Navigate to `http://127.0.0.1:8000/`

You are now ready to install the Django [eerf web application](django-eerf/README.md).

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
