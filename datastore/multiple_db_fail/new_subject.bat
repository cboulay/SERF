mysqldump -uroot --routines --no-data --triggers eerf_subject_template > tempfile.sql
SET db_name=eerf_subject_%1
mysql -uroot -e "DROP DATABASE IF EXISTS %db_name%";
mysql -uroot -e "CREATE DATABASE %db_name%";
mysql -uroot %db_name% < tempfile.sql
mysql -uroot -e "INSERT IGNORE INTO eerf_settings.subject (Id, Name) Values ('%db_name%','%1')";