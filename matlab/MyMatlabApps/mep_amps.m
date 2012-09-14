tools_paths; %Script to set the paths.
mep_win = [-0.500 0.500];

[FileName,PathName,FilterIndex] = uigetfile('*.dat','Select BCI2000 dat files','D:\data\bci2000\','MultiSelect','on');
for ff=1:length(FileName)
    full_fnames(ff).name = fullfile(PathName,FileName{ff});
end

file_amps = reshape(repmat([25*ones(1,5) 100*ones(1,5)],15,1),[],1);
file_freqs = reshape(repmat([9 11 15 19 21 21 19 15 11 9],15,1),[],1);

[signal, states, parameters] = load_bcidat(full_fnames(:).name);
trigdat = signal(:,strcmpi(parameters.ChannelNames.Value,'Trig'));
trig_starts = find(diff([0;trigdat])>0);
emgdat = signal(:,strcmpi(parameters.ChannelNames.Value,'EDC'));
%reindex emgdat into samples x trials
mep_rel_sample = mep_win.*parameters.SamplingRate.NumericValue;%convert mep_win to n_samples
reix = bsxfun(@plus,trig_starts,mep_rel_sample(1):mep_rel_sample(2));
emgdat=emgdat(reix');
mep_xvec = mep_win(1):1/parameters.SamplingRate.NumericValue:mep_win(2);
mep_xvec = mep_xvec(1:size(emgdat,1));
emgdat = bsxfun(@minus,emgdat,mean(emgdat(mep_xvec<0,:)));
plot(mep_xvec,emgdat)
xlim([0.005 0.05])
[mep_lims,~]=ginput(2);
mep_out = sum(abs(emgdat(mep_xvec>=mep_lims(1) & mep_xvec<=mep_lims(2),:)))';

trial_bool = ~any(abs(emgdat(mep_xvec<-0.005,:))>20)';

unique_amps = unique(file_amps);
for aa=1:numel(unique_amps)
    file_bool = file_amps==unique_amps(aa);
    [my_freqs,I]=sort(file_freqs(file_bool & trial_bool));
    
    temp_mep = mep_out(file_bool & trial_bool,:);
    temp_mep = temp_mep(I,:);
    
    [my_means(:,aa),my_cis(:,:,aa)] = grpstats(temp_mep,my_freqs,{'mean','meanci'});
%     [my_means(:,aa),my_sem(:,:,aa)] = grpstats(reshape(temp_mep,[],1),reshape(temp_grp,[],1),{'mean','sem'});
end

errorbar(repmat(unique(my_freqs),1,2),my_means,squeeze(my_cis(:,2,:))-my_means,'LineWidth',2)
legend(num2str(unique_amps),'Location','SouthEast')
xlabel('FREQ. (Hz)')
ylabel('MEP p2p (uV')
title('Mean MEP size (+/- 95% CI) during tACS at given current (mA)')