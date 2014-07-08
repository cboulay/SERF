# Introduction

This is an API for accessing the EERF database from within the Matlab
programming environment.

# Setup

1. Download this repository to $repopath.
2. Start your database server.
    `sudo mysqd_safe &` or use your GUI.
3. Open Matlab and change to $repopath.
4. Add the database interface to the path: `addpath(fullfile(pwd, 'mym'));`
5. Import the object interfaces: `import EERF.*;`
6. Create a connection to the MySQL server: `dbx = EERF.Dbmym('mysite');`

# Using

See test.m for an example of how to use this. Sorry, more detail to come later.