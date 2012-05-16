function feature_value=get_td_feature(data,frag_ids,time_window,channel_id,aaa)
ani=E3.Subject;
ani.DB_id=data(1).subject_id;
frags=[ani.Fragments];
samps=[frags.NSamples];
chans=ani.Channels;
%Calculate the sample_bool
t_vec=ani.T_vec;
samp_bool=false(1,length(t_vec));
for fr=1:length(frag_ids)
    samp_bool(sum(samps(1:frag_ids(fr)-1))+1:sum(samps(1:frag_ids(fr))))=true;
end
t_vec=t_vec(samp_bool);
samp_bool=t_vec>=time_window(1) & t_vec<time_window(2);
global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end

n_trials=length(data);
feature_value=NaN(1,n_trials);
ntb=100;
nPulls=ceil(n_trials/ntb);
fprintf('Calculating time-domain feature from raw data\n');
var_args={'dbname',ani.E3Name,'tablename',ani.DataTableName,'samps',samps,...
    'frag_ids',frag_ids,'conv',[chans.ad2uv],'checkbg',ani.CheckBG,'freqs',[frags.Fs],'rectified',[chans.IsRectified]};
for pu=1:nPulls
    if pu<nPulls
        trial_ids=(pu-1)*ntb+1:pu*ntb;
    else
        trial_ids=(pu-1)*ntb+1:length(data);
    end
    evoked = data(trial_ids).get_evoked(var_args{:});
    evoked = squeeze(evoked(samp_bool,channel_id,:));
    if aaa %if this is absolute average amplitude
        feature_value(trial_ids)=mean(abs(evoked));
    else %else just average amplitude
        feature_value(trial_ids)=mean(evoked);
    end
    if mod(pu,1000)==0
        fprintf('\n');
    elseif mod(pu,50)==0
        fprintf('.');
    end
end
end
%mym(cid,'close');