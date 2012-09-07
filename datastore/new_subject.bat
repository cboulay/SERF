mysqldump -uroot --routines --no-data --triggers eerf_subject_template > tempfile.sql
SET db_name=eerf_subject_%1
mysql -uroot -e "DROP DATABASE %db_name%";
mysql -uroot -e "CREATE DATABASE %db_name%";
mysql -uroot %db_name% < tempfile.sql