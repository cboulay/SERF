%Analyze some data from Takemi's experiment.
tools_paths;
import EERAT.* %Database object interfaces.
experiment = EERAT.Experiment(NaN,'Name','RT_Training');
subjects = experiment.subjects;
freqs = EERAT.TFBox.freq_edges_hz;
freqs = mean(freqs,2);
freqs = freqs(1:end-1);
n_subs = length(subjects);

get_subject_info;


for ss=1:n_subs
    sub = subjects(ss);
    
    fb_freqs = subjects_info(ss).fb_freq;
    fb_ix = abs(bsxfun(@minus,fb_freqs,freqs));
    fb_ix = find(sum(bsxfun(@eq,min(fb_ix),fb_ix),2));
    n_fb = length(fb_ix);
    
    %We have at least two periods. We are interested in the change from the
    %first period to the last period.
    periods = sub.periods([1 end]);
    figure('name',sub.Name)
    for pp=1:length(periods)
        period = periods(pp);
        trials = period.trials;
        conditions = strcmpi('IMAGERY',{trials.condition})';
        task_pow = 10*log10(shiftdim(cat(3,trials.task_pow),2));
        task_pow = task_pow(:,:,1:end-1); %last freq is used for reference.
        [n_trials,n_chans,n_freqs]=size(task_pow);
        [r,p]=corr([conditions reshape(task_pow,[n_trials n_chans*n_freqs])]);
        r = r(2:end,1); r=r.^2.*sign(r); r=reshape(r,[n_chans,n_freqs]);
        p=p(2:end,1); p=reshape(p,[n_chans,n_freqs]);
        
        subplot(2,n_fb+1,(n_fb+1)*(pp-1)+1)
        imagesc(freqs,1:64,r')
        caxis([-1*max(max(abs(r))) max(max(abs(r)))])
        colorbar
        
        clims = [-1*max(max(abs(r(:,fb_ix)))) max(max(abs(r(:,fb_ix))))];
        for bb=1:n_fb
            subplot(2,n_fb+1,(n_fb+1)*(pp-1)+1+bb)
            topoplot(r(:,fb_ix(bb)),'eloc64.txt','EEG','shading','interp','maplimits',clims)
            title([num2str(freqs(fb_ix(bb))),' Hz'])
        end
    end
end