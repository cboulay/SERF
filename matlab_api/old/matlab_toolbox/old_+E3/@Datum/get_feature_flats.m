function feature_value=get_feature_flats(data)
%function feature_value=get_feature_flats(data)
%argument data is an array or instance of Trial, Day, or Period object(s).
%This function calculates the number of times the signal goes flat (across
%two samples) for best_ecog_channel. It uses all 3 fragments.
%I had this set to also use conditioned channel but then it didn't work for
%all intermittent data.
%For trial data, the lack of a requirement on conditioned_channel might
%result in trials with bad EMG being included. For pre-stimulus, this
%should be taken care of with filters for BG. For post-stimulus, this
%should be taken care of with fitlers for M-wave.

%Determine the class of data. This feature is only defined for Trials
class_name=class(data(1));
switch class_name
    case 'E3.Trial'
        n_trials=length(data);
        feature_value=NaN(1,n_trials);
        frag_ids=[1 2 3]; %Get all frags from the db.
        
        %Get the subject object these data belong to.
        ani=E3.Subject;
        ani.DB_id=data(1).subject_id;
        
        %Determine if we have 'conditioned_channel_id' or 'best_ecog_channel_id' or both.
        ad_names={ani.SubjectDetails.Name};
        be_id=[];
        ad_id=find(strcmp(ad_names,'best_ecog_channel_id'));
        if any(ad_id)
            be_id=str2double(ani.SubjectDetails(ad_id).Value);
        end
        
        if any(be_id)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end %#ok<*TLEV>
            ntb=100;
            ani=E3.Subject;
            ani.DB_id=data(1).subject_id;
            frags=[ani.Fragments];
            samps=[frags.NSamples];
            chans=ani.Channels;
            nPulls=ceil(n_trials/ntb);
            fprintf('Calculating flats from raw data');
            var_args={'dbname',ani.E3Name,'tablename',ani.DataTableName,'samps',samps,...
                'frag_ids',frag_ids,'conv',[chans.ad2uv],'checkbg',ani.CheckBG,'freqs',[frags.Fs],'rectified',[chans.IsRectified]};
            for pu=1:nPulls
                if pu<nPulls
                    trial_ids=(pu-1)*ntb+1:pu*ntb;
                else
                    trial_ids=(pu-1)*ntb+1:length(data);
                end
                evoked = data(trial_ids).get_evoked(var_args{:});
                evoked = evoked(:,be_id,:);
                feature_value(trial_ids)=squeeze(max(sum(diff(evoked)==0),[],2));
                if mod(pu,1000)==0
                    fprintf('\n');
                elseif mod(pu,50)==0
                    fprintf('.');
                end
            end
            %mym(cid,'close');
        end
    case {'E3.Period','E3.Day'}
        warning('Flats not defined for days or periods') %#ok<*WNTAG>
end