ss=3;

%How data changes over periods (days).
ft_names={'buff_amp_mean';'buff_amp_var';'baseline_amp_mean';'task_amp_mean'};
ft_freq_centers=[5 7 9 11 13 15 17 19 21 23 25 27 29];
for xx=1:length(ft_names)
    for yy=1:length(ft_freq_centers)
        comb_feat_name{(xx-1)*length(ft_freq_centers)+yy}=[ft_names{xx},'_',num2str(ft_freq_centers(yy)),'Hz']; %#ok<SAGROW>
    end
end; clear xx yy
n_features=length(comb_feat_name);

% PATHS
toolpath=pwd;
toolpath=toolpath(1:strfind(toolpath,'EERAT')+4);
toolpath=[toolpath,filesep,'core',filesep,'api',filesep,'matlab',filesep];
addpath(toolpath);
addpath([toolpath,'mym']);
clear toolpath

% DATABASE OBJECT
import EERAT.* %Object interfaces.
dbx=EERAT.Dbmym('eerat'); %Open a connection to the database.

experiment = EERAT.Experiment(dbx,'Name','Ono_FB');

sub=experiment.subjects(ss);

sub_period_ix=[];
sub_task_id=[];
sub_features=[];
for pp=1:length(sub.periods)
    per=sub.periods(pp);
    n_trials=length(per.trials);
    
    sub_period_ix=cat(1,sub_period_ix,pp*ones(n_trials,1));
    sub_task_id=cat(1,sub_task_id,per.get_trials_details('dat_task_condition'));
    
    per_features=nan(n_trials,n_features);
    for ft=1:n_features
        per_features(:,ft)=per.get_trials_features(comb_feat_name{ft});
    end
    sub_features=cat(1,sub_features,per_features);
end
sub_task_id=str2num(cell2mat(sub_task_id)); %#ok<ST2NM>

clear ft per_features pp per

%reshape features to trials x freqs x type
sub_features=reshape(sub_features,length(sub_period_ix),length(ft_freq_centers),length(ft_names));

%create POW, ERD, and AN features.
task_bool=sub_task_id==1;
pow=10*log10(sub_features(:,:,4).^2);
erd=sqrt(sub_features(:,:,4)./sub_features(:,:,3));
anp=(sub_features(:,:,4)-sub_features(:,:,1))./sub_features(:,:,2);

%Across periods, plot baseline, POW, ERD, and AN
per_ix=unique(sub_period_ix);
n_pers=length(per_ix);
n_freqs=size(pow,2);
out_baseline=nan(n_pers,n_freqs);
out_POW=out_baseline;
out_ERD=out_baseline;
out_AN=out_baseline;
for pp=1:n_pers
    p_ix=per_ix(pp);
    per_bool=sub_period_ix==p_ix;
    out_baseline(pp,:)=mean(10*log10(sub_features(per_bool & task_bool,:,1).^2));
    out_POW(pp,:)=mean(pow(per_bool & task_bool,:));%-out_baseline(pp,:);
    out_ERD(pp,:)=mean(erd(per_bool & task_bool,:));
    out_AN(pp,:)=mean(anp(per_bool & task_bool,:));
end
subplot(4,1,1)
imagesc(1:n_pers,ft_freq_centers,zscore(out_baseline)'), axis xy, title('BASELINE')
subplot(4,1,2)
imagesc(1:n_pers,ft_freq_centers,zscore(out_POW)'), axis xy, title('TASK')
subplot(4,1,3)
imagesc(1:n_pers,ft_freq_centers,out_ERD'), axis xy, title('ERD')
subplot(4,1,4)
imagesc(1:n_pers,ft_freq_centers,out_AN'), axis xy, title('AN')