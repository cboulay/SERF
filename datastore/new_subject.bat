mysqldump -uroot --routines --no-data --triggers eerat_subject_template > tempfile.sql
SET db_name=eerat_subject_%1
mysql -uroot -e "DROP DATABASE %db_name%";
mysql -uroot -e "CREATE DATABASE %db_name%";
mysql -uroot %db_name% < tempfile.sql