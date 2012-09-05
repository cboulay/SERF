import RT.* %Some classes to help load the data.
import EERAT.* %Database object interfaces.
if ~exist('dbx','var')
    dbx=EERAT.Dbmym('eerat'); %Open a connection to the database.
end

experiment = EERAT.Experiment(dbx,'Name','RT_Training','Description','BCI training reaction time features');%Get or create an experiment to group the subjects.
sub_type = EERAT.SubjectType(dbx,'Name','BCPy_healthy');
dat_type = EERAT.DatumType(dbx,'Name','multiclass_imagery');

get_subject_info;%subject_info stored in a separate file.
% subjects_info = subjects_info(4);%Temp - Start with WPMS005-S014 %and SXKS004-S013
for ss=1:length(subjects_info)%For each subject
    si=subjects_info(ss);
    
    %Get or create the subject. Subjects and data are special in that they
    %require their type to be passed in as an argument at creation time.
    sub=EERAT.Subject(dbx,'Name',['RT_',si.name],'subject_type_id',sub_type.subject_type_id);
    sub.experiments=experiment;%Add this subject to our experiment.
    
    rtsub = RT.Subject(si);%Create a RT.Subject out of this si.
    rtsub.load_data;%Load the data into tksub.trials
    
    %Save only the first and last session.
    sessions = [rtsub.trials.sess_n]';
    session_bool = sessions == min(sessions) | sessions == max(sessions);
    rtsub.trials = rtsub.trials(session_bool);
    sessions = unique(sessions(session_bool));
    
    fb_freqs = subjects_info(ss).fb_freq;
    fb_freqs = cell2mat(reshape([cellstr(num2str(fb_freqs')) repmat({','},length(fb_freqs),1)]',1,[]));
    fb_freqs = fb_freqs(1:end-1);
        
    %Create a period for each
    for pp=1:2
        this_period = EERAT.Period(dbx, 'new', true, 'subject_id', sub.subject_id, ...
            'datum_type_id', dat_type.datum_type_id, 'span_type', 'period');
        trial_bool = [rtsub.trials.sess_n] == sessions(pp);
        sess_trials = rtsub.trials(trial_bool);
        this_period.StartTime = datestr(sess_trials(1).trial_datenum);
        this_period.EndTime = datestr(sess_trials(end).trial_datenum + (1/60*24));
        this_period.details(strcmpi('dat_conditioned_feature_name',{this_period.details.Name}')).Value=fb_freqs;
        
        n_trials = length(sess_trials);
        task_start_stop = NaN(n_trials,2);
        for tt=1:n_trials
            this_trial = sess_trials(tt);
            new_trial=EERAT.Trial(dbx, 'new', true, 'subject_id', sub.subject_id,...
                'datum_type_id', dat_type.datum_type_id,...
                'span_type', 'trial', 'IsGood', true);
            new_trial.periods=this_period;
            x_vec = this_trial.t_vec';
            new_trial.StartTime = datestr(this_trial.trial_datenum);
            new_trial.EndTime = datestr(this_trial.trial_datenum + (x_vec(end) - x_vec(1))/(60*60*24));
            new_trial.erp = this_trial.raw_data;
            new_trial.channel_labels = channel_names;
            new_trial.xvec = x_vec;
            %Save window for task eval (use last second of trial)
            task_start_stop(tt,:) = [x_vec(end)-1+1/rtsub.eeg_fs x_vec(end)];
        end
        bg_start_stop = 1000*repmat(rtsub.baseline_win,n_trials,1);
        task_start_stop = 1000*task_start_stop;
        this_period.set_trials_details({'dat_BG_start_ms' 'dat_BG_stop_ms' 'dat_task_start_ms' 'dat_task_stop_ms'},...
            [bg_start_stop task_start_stop]);
        this_period.set_trials_details({'dat_task_condition'},{sess_trials.task_level}');
    end
end