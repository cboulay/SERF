%Look at WPM CP3 and 22.5 Hz to see how signals change (relative to first
%sessions' baseline) timefreq, imagery baseline (topo) and imagery task
%(topo)
tools_paths;
import EERAT.* %Database object interfaces.
experiment = EERAT.Experiment(NaN,'Name','RT_Training');
subjects = experiment.subjects;
freqs = EERAT.TFBox.freq_edges_hz;
freqs = mean(freqs,2);
freqs = freqs(1:end-1);
get_subject_info;
sub=subjects(4);
sub_info=subjects_info(4);

fb_freqs = sub_info.fb_freq;
fb_ix = abs(bsxfun(@minus,fb_freqs,freqs));
fb_ix = find(sum(bsxfun(@eq,min(fb_ix),fb_ix),2));
fb_ix = fb_ix(1);

fb_chans = sub_info.fb_chan;
fb_chan_ix = find(strcmpi(fb_chans,channel_names));

%We have at least two periods. We are interested in the change from the
%first period to the last period.
periods = sub.periods([1 end]);

for pp=1:length(periods)
    period = periods(pp);
    trials = period.trials;
    conditions = strcmpi('IMAGERY',{trials.condition})';
    
    tf_pow = {trials.tf_pow};
    n_steps = Inf;
    for tt=1:length(tf_pow)
        n_steps = min([n_steps size(tf_pow{tt},1)]);
    end
    for tt=1:length(tf_pow)
        tf_pow{tt} = tf_pow{tt}(1:n_steps,:,:);
    end
    tf_pow = 10*log10(shiftdim(cat(4,tf_pow{:}),3));
    tf_pow = tf_pow(:,:,:,1:end-1);
    [n_trials,n_steps,n_chans,n_freqs] = size(tf_pow);
    
    base_pow = 10*log10(shiftdim(cat(3,trials.baseline_pow),2)); base_pow = base_pow(:,:,1:end-1);
    task_pow = 10*log10(shiftdim(cat(3,trials.task_pow),2)); task_pow = task_pow(:,:,1:end-1);
    
%     %Use the all trials' baseline as a reference.
%     ref_pow = base_pow(:,:,:);
%     n_ref_trials = size(ref_pow,1);
%     ref_tf = repmat(ref_pow(:,fb_chan_ix,:),[1,n_steps,1,1]);
%     ref_pow = squeeze(ref_pow(:,:,fb_ix));
%     
%     %Everything else will look at imagery trials only.
%     base_pow = squeeze(base_pow(conditions,:,fb_ix));
%     task_pow = squeeze(task_pow(conditions,:,fb_ix));
%     tf_pow = squeeze(tf_pow(conditions,:,fb_chan_ix,:));
%     n_test_trials = sum(conditions);
%         
%     y = [zeros(n_ref_trials,1);ones(n_test_trials,1)];%ref = 0 and test = 1
%     
%     %First do the timefreq.
%     x = [reshape(ref_tf,n_ref_trials,[]);reshape(tf_pow,n_test_trials,[])];
%     [r,p]=corr([y x]);
%     r = r(2:end,1); r=r.^2.*sign(r); r1{pp}=reshape(r,[n_steps,n_freqs]);
%     p=p(2:end,1); p=reshape(p,[n_steps,n_freqs]);  
% 
%     %Do the topos at 22.5Hz.
%     x = [ref_pow; base_pow];
%     [r,p]=corr([y x]);
%     r = r(2:end,1); r2{pp}=r.^2.*sign(r);
%     p=p(2:end,1);    
%     
%     x = [ref_pow; task_pow];
%     [r,p]=corr([y x]);
%     r = r(2:end,1); r3{pp}=r.^2.*sign(r);
%     p=p(2:end,1);
    
    %Normalize data by mean and standard deviation of ALL tf values.
    zmean = squeeze(mean(reshape(tf_pow,[n_trials*n_steps,n_chans,n_freqs])));
    zstd = squeeze(std(reshape(tf_pow,[n_trials*n_steps,n_chans,n_freqs])));
    
    nc = sum(conditions);
    
    temp = base_pow(conditions,:,:) - repmat(shiftdim(zmean,-1),nc,1);
    temp = temp ./ repmat(shiftdim(zstd,-1),nc,1);
    temp = squeeze(mean(temp(:,:,fb_ix)));
    r2{pp} = temp;
    
    temp = task_pow(conditions,:,:) - repmat(shiftdim(zmean,-1),nc,1);
    temp = temp ./ repmat(shiftdim(zstd,-1),nc,1);
    temp = squeeze(mean(temp(:,:,fb_ix)));
    r3{pp} = temp;
    
    temp = tf_pow(conditions,:,:,:) - repmat(shiftdim(zmean,-2),nc,n_steps);
    temp = temp ./ repmat(shiftdim(zstd,-2),nc,n_steps);
    temp = squeeze(mean(temp(:,:,fb_chan_ix,:)));
    r1{pp} = temp;
    
    clear temp
end

%Plots
%scale
rlim = max([max(max(abs(cell2mat(r1)))) max(max(abs(cell2mat([r2 r3]))))]);
figure('name',sub.Name)
for pp=1:length(periods)
    subplot(2,3,(pp-1)*3+1)
    imagesc(trials(1).tf_tvec,trials(1).tf_fvec(1:end-1),r1{pp}'), axis xy
    caxis([-1*rlim rlim])
    colorbar
    xlabel('TIME AFTER IMAGERY CUE (s)')
    ylabel('FREQUENCY (Hz)')
    
    subplot(2,3,(pp-1)*3+2)
    topoplot(r2{pp},'eloc64.txt','EEG','shading','interp','maplimits',[-1*rlim rlim])
%     title('BASELINE MU')
    
    subplot(2,3,(pp-1)*3+3)
    topoplot(r3{pp},'eloc64.txt','EEG','shading','interp','maplimits',[-1*rlim rlim])
%     topoplot(r3{pp},'eloc64.txt','EEG','shading','interp')
%     title('TASK MU')
end