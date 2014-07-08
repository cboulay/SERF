addpath(genpath(fullfile(pwd, 'mym')));

import EERF.*  % Object interfaces.
dbx = EERF.Dbmym('mysite');  % Open a connection to the database.

subjects=EERF.Db_obj.get_obj_array(dbx, 'Subject'); %Get all subjects;
my_sub = subjects(1);

%Alternatively, if you know the name, you could try
%my_sub = EERF.Subject(dbx, 'name', 'ap4'); %This will search for the
%subject matching this name.

my_period = my_sub.periods(33);
my_trial = my_period.trials(1);

%Plot the trial
plot(my_trial);

%The rest are not working right now.
meps=pp.get_trials_features('MEP_p2p'); %Get all meps from the period.
powerA=pp.get_trials_details('dat_TMS_powerA'); %Get TMS intensity for the period.
powerA=str2double(powerA);