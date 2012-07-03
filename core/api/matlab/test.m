%Testing script to help development of EERAT MATLAB API.

addpath('mym'); %Path for MySQL wrapper.

% addpath('+EERAT');
import EERAT.* %Object interfaces.
dbx=EERAT.Dbmym('eerat'); %Open a connection to the database.
subjects=EERAT.Db_obj.get_obj_array(dbx,'Subject'); %Get all subjects;
ss=subjects(3);
pp=ss.periods(end);
tt=pp.trials(1);
plot(tt.xvec,tt.erp),legend(tt.channel_labels)
meps=pp.get_trials_features('MEP_p2p');
powerA=pp.get_trials_details('dat_TMS_powerA');
powerA=str2double(powerA);