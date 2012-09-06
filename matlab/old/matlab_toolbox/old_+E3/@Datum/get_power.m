function [power,freqs]=get_power(obj,params,chan_ids)
%This is a helper function for the class-level functions. This function
%does most of the work in calculating the power in data for given set of
%mem params.
class_name=class(obj(1));
global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
% switch class_name
%     case 'E3.Trial'
        trials=obj;
%     case {'E3.Day','E3.Period'}
%         trials=obj.get_trials(true);
% end

%Variables needed to get evoked. It is important to set these variables in
%advance and provide them to get_evoked because get_evoked will be called
%many times in a row and this should save time.
frag_ids=1;
ani=E3.Subject;
ani.DB_id=obj(1).subject_id;
dbname=ani.E3Name;
tablename=ani.DataTableName;
frags=[ani.Fragments];
samps=[frags.NSamples];
fs=[frags.Fs];
chans=ani.Channels;
if isempty(chan_ids)
    chan_ids=1:length(chans);
end
n_channels=length(chan_ids);
conv=[chans.ad2uv];
rectified=[chans.IsRectified];
checkbg=ani.CheckBG; %in ms

params(end)=fs(1);
%Set the model order to encompass at least 1 cycle of the slowest
%frequency:params(2)
lowest_f=max(params(2)-params(4),1);
order=ceil(fs(1)/lowest_f);
order=max(ceil(fs(1)/10),order);
order=min(floor(samps(1))/2,order);
params(1)=order;

ntb=20;
n_trials=length(trials);
nPulls=ceil(n_trials/ntb);

if n_trials==0
    [temp_pow,freqs]=mem(rand(sum(samps),1),params);
    power=NaN(size(temp_pow,1),n_channels);
else
    %Do one trial to get power size for pre-allocation.
    temp_evoked=trials(1).Evoked;
    temp_evoked=temp_evoked(:,chan_ids);
    [temp_pow,freqs]=mem(temp_evoked,params);
    n_freqs=size(temp_pow,1);
    if strcmpi(class_name,'E3.Trial')
        power=zeros(n_freqs,n_channels,n_trials);
    else
        power=zeros(n_freqs,n_channels);
    end
%     n_so_far=0;
    fprintf('Calculating spectral power\n');
    var_args={'dbname',dbname,'tablename',tablename,'samps',samps,...
        'frag_ids',frag_ids,'conv',conv,'checkbg',checkbg,'freqs',fs,'rectified',rectified};
    for pu=1:nPulls
        if pu<nPulls
            trial_id=(pu-1)*ntb+1:pu*ntb;
        else
            trial_id=(pu-1)*ntb+1:n_trials;
        end
        npt=length(trial_id);
        this_evoked = trials(trial_id).get_evoked(var_args{:});
        this_evoked=this_evoked(:,chan_ids,:);
        this_evoked=reshape(this_evoked,[],n_channels*npt);
        temp_pow=mem(this_evoked,params);
        temp_pow=reshape(temp_pow,n_freqs,n_channels,npt);
        temp_pow(temp_pow<=0)=eps;
        temp_pow=10*log10(temp_pow.^2);
%         switch class_name
%             case {'E3.Period','E3.Day'}
%                 power=power+nansum(temp_pow,3);
%                 n_so_far=n_so_far+sum(squeeze(any((~any(isnan(temp_pow))),2)));
%             case 'E3.Trial'
                power(:,:,trial_id)=temp_pow;
%         end
        if mod(pu,1000)==0
            fprintf('\n');
        elseif mod(pu,20)==0
            fprintf('.');
        end
    end
%     if ~strcmpi(class_name,'E3.Trial')
%         power=power./n_so_far;
%     end
end
power=squeeze(power);
%mym(cid,'close');