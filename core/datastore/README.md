# Evoked Electrophysiological Response Analysis Toolbox (EERAT)

## SQL Database

### Installing your SQL server

I hope that the database structure will work in several SQL servers but I have only tested it in MySQL (version > 5.5). I use MySQL because one of my uses for these tools is to analyze legacy data from ELIZANIII [TODO: link?] and the ELIZANIII data structure requires MySQL.

TODO: Download MySQL [TODO: link?], install MySQL, configure MySQL, test MySQL

### Creating the EERAT relational model for the first time

Run the following at a command prompt.
>mysql -uroot < eerat_v1.sql
>mysql -uroot eerat < eerat_data.sql
>mysql -uroot eerat < test_data.sql
The first line inserts the schema and triggers. The second inserts some default data and stored procedures. The third inserts some test data.

### Explanation of schema

### Modifying the EERAT relation model (includes updating to newer versions)

Everytime the API is instantiated it checks the version of the database against the API's expected version number. If the version numbers do not match, the API attempts to upgrade the database (without destroying any data) using the upgrade path defined by the .sql files.

The relational model was designed using MySQL Workbench. The model diagram is available in /SQL_database/EERAT_model.mwb . This file provides a representation of the data structure. You may modify the data structure to your liking but this will probably break the API and any future upgrades.

TODO: Changing datum_type should reset the datum's Number.