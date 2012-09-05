%Analyze some data from Takemi's experiment.
tools_paths;
import EERAT.* %Database object interfaces.
experiment = EERAT.Experiment(NaN,'Name','Takemi_MI_TMS');
subjects = experiment.subjects;

output.ntrials = [];
output.mep = [];
output.pow = [];
output.erd = [];

n_subs = length(subjects);
for ss=1:n_subs
    sub = subjects(ss);
    period = sub.periods;%I know there is only one period for this dataset.
    trials = period.trials;
    
    %Look at erd differences between RC trials and MI trials.
    conditions = strcmpi('1',{trials.condition})';
    erd = shiftdim(cat(3,trials.erd),2);
    [n_trials, n_channels, n_freqs] = size(erd);
    [r1,p1]=corr([conditions reshape(erd,[n_trials n_channels*n_freqs])]);
    r1 = r1(2:end,1); r1=r1.^2.*sign(r1); p1=p1(2:end,1);
    freqs = trials(1).tf_fvec;
    
    %Look at power change form baseline to task for MI trials only.
    sometrials = trials(conditions);%Only use trials with motor imagery.
    baseline_pow = 10*log10(shiftdim(cat(3,sometrials.baseline_pow),2));
    prestim_pow = 10*log10(shiftdim(cat(3,sometrials.prestim_pow),2));
    someerd = shiftdim(cat(3,sometrials.erd),2);
    [n_trials, n_channels, n_freqs] = size(baseline_pow);
    y = [zeros(n_trials,1);ones(n_trials,1)];
    x = [reshape(baseline_pow,[n_trials n_channels*n_freqs]);reshape(prestim_pow,[n_trials n_channels*n_freqs])];
    [r2,p2] = corr([y x]);
    r2 = r2(2:end,1); r2=r2.^2.*sign(r2); p2=p2(2:end,1);
    subplot(4,4,ss)
    %Plot ERD correlations with task and power correlations with task
    %period (task vs baseline)
    %Also plot average ERD during MI trials only.
    plotyy(freqs(1:end-1),[r1(1:end-1) r2(1:end-1)],freqs(1:end-1),squeeze(mean(someerd(:,:,1:end-1))))
    title(sub.Name)
    rsq_out(ss,:) = r2(1:end-1);
    
    %Look at how mep correlates with EEG features.
    meps = sqrt([trials.mep]');
    isis = [trials.isi]';
    
    %isolate trials with single-pulse TMS
    mep_bool = ~isnan(meps);
    isi_bool = isis==0;
    some_bool = mep_bool & isi_bool & conditions;
    somepow = 10*log10(squeeze(shiftdim(cat(3,trials(some_bool).prestim_pow),2)));
    someerd = squeeze(shiftdim(cat(3,trials(some_bool).erd),2));
    somemep = meps(some_bool);
    
    %standardize for collating across subjects
    somemep = zscore(somemep);
    somepow = zscore(somepow);
    someerd = zscore(someerd);
    
    output.ntrials = [output.ntrials;length(somemep)];
    output.mep = [output.mep; somemep];
    output.pow = [output.pow; somepow];
    output.erd = [output.erd; someerd];
    
    
    [r3,p3] = corr([somemep somepow someerd]);
    r3 = r3(2:end,1); r3=r3.^2.*sign(r3); p3=p3(2:end,1);
    r3 = reshape(r3,[],2);
    rsq_out2(ss,:,:) = r3;
end
legend('TaskCondERD','MIPowDiff','MIERDDiff')

%Reorder subjects by their feedback frequency
get_subject_info;
fb_freqs = [subjects_info.fb_freq];
[fb_freqs,I] = sort(fb_freqs);

figure;

subplot(2,1,1)
imagesc(1:n_subs,freqs(1:end-1),rsq_out(I,:)'), axis xy
caxis([-1*max(max(abs(rsq_out))) max(max(abs(rsq_out)))])
colorbar
% xlabel('SUBJECT')
ylabel('FREQ. (Hz)')
title('Rest vs. Imagery')
%TODO: order by peak freq.

subplot(2,1,2)
% [r,p] = corr([output.mep output.pow output.erd]);
% r = r(2:end,1); r=r.^2.*sign(r); p=p(2:end,1);
% r = reshape(r,length(freqs),[]); p=reshape(p,length(freqs),[]);
% subplot(2,1,2)
% plot(freqs(1:end-1),r(1:end-1,:))
% axis tight
% xlabel('FREQ (Hz)')
% ylabel('+/- R^2')
% legend('POW','ERD')

powerd = 1;
imagesc(1:n_subs,freqs(1:end-1),rsq_out2(I,:,powerd)'), axis xy
caxis([-1*max(max(abs(rsq_out2(:,:,powerd)))) max(max(abs(rsq_out2(:,:,powerd))))])
colorbar
xlabel('SUBJECT')
ylabel('FREQ. (Hz)')
title('MEP')