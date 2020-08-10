## Installing MySQL Database and Python connector

We assume that you followed other instructions to install Python and Django. The rest of the instructions are for installing the MySQL database server and its interfaces. Though any DBMS should work, I use MySQL because some of the data I work with were originally recorded into MySQL.

### On OS X

1. Install [homebrew](http://brew.sh/) if you don't have it already.
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
1. Your Python environment will require some additional packages. e.g.: `conda install mysqlclient openssl`

### On Linux

First we'll install and configure MySQL server.
1. [Follow these instructions](https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-18-04)
1. Optional - [Change default datadir](https://www.digitalocean.com/community/tutorials/how-to-move-a-mysql-data-directory-to-a-new-location-on-ubuntu-18-04)
1. `conda install mysqlclient openssl=1.0.2r`  <-- haven't tested the openssl version requirement in a long time.

### On Windows

1. Install [MySQL Community Server](https://dev.mysql.com/downloads/mysql/)
    * Choose the Developer package (MySQL Server, Workbench, and Shell)
    * Work through pre-requisites
    * MySQL80 will be your service name unless you change this
1. `conda install mysqlclient openssl`

## Configuring the database server for use with serf

The MySQL server will need to have some minimal configuration done to it. The easiest way to do this is to open MySQL Workbench with Administrator privileges (admin needed if mysql ini file stored system directory).
You can also edit the settings file manually. Possible locations:
* /etc/my.cnf
* /etc/mysql/my.cnf
* /usr/local/etc/my.cnf
* ~/.my.cnf
* C:\ProgramData\MySQL\MySQL Server 8.0\my.ini

You'll likely want to change the data directory. In the past I've also needed to change from the default storage engine (InnoDB) to the MyISAM storage engine because I had trouble getting good performance out of InnoDB when working with some old rat data. Here are some changes I've made in the past:

```
[mysqld]
datadir = /Volumes/STORE/eerfdata
default-storage-engine = MyISAM
default_tmp_storage_engine = MyISAM
query_cache_type = 1
key_buffer_size = 2G
query_cache_limit = 400M
```

If you changed the datadir then you'll need to copy the original data structure to the new location (Windows) or use `sudo mysql_install_db --user=root --defaults-file=/etc/my.cnf`.

Then restart the server: `mysqld_safe & --defaults-file=/etc/my.cnf`

It is not necessary to specify the defaults file when using the default location (/etc/my.cnf).

1. Create the root database for the application:
    - Mac/Linux: 
        - `mysql -uroot -p`
        - `create database serf character set utf8;`
        - `exit;`
    - On Windows (Workbench GUI):
      - Open Workbench, connect to database (Database > Connect to Database)
      - Enter your username and password
      - Make a new schema called `serf`
      - [Refer to this tutorial for a visual guide](https://www.mysqltutorial.org/mysql-create-database/)
      
You are now ready to install the database for the serf app.

## Additional Tips for installing MySQL

1. Optional (mandatory for Matlab ORM): Install additional SQL triggers to
    - Automatically log a new entry or a change to subject_detail_value
    - Automatically set the stop_time field of a datum to +1s for trials or +1 day for days/periods.
    - Automatically set the number of a new datum to be the next integer greater than the latest for that subject/span_type.
    - After installing the databases for the serf app, from shell/terminal, run `mysql -uroot mysite < serf.sql`
