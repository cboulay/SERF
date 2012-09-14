tools_paths; %Script to set the paths.
baseline_win = [-3 0];%time, in s, relative to go cue
prestim_win = [-1 0]; %time, in s, relative to stimulus.
mep_win = [-0.050 0.100];

[FileName,PathName,FilterIndex] = uigetfile('*.dat','Select BCI2000 dat files','D:\data\bci2000\','MultiSelect','on');
for ff=1:length(FileName)
    full_fnames(ff).name = fullfile(PathName,FileName{ff});
end

filter_parms = {
    'SpatialFilter','D:\BCI2000\parms\fragments\spatial_filters\lbpassive_llp.prm';
    'ARFilter','D:\BCI2000\parms\fragments\spectral\AR_1hz_pow.prm';
    %'LinearClassifier','LC.prm';
    %'LPFilter','LP_1sec.prm';
    %'ExpressionFilter','Exp_pow_to_db.prm';
    %'Normalizer','Norm.prm'
};
ix = 0;
for ff=1:length(FileName)
    
    %Start with the spectral analysis
    % s = bci2000chain(filenames{ff},'ARSignalProcessing','full_llp_ar_parameters.prm');
    % s = bci2000chain(filenames{ff},'ARSignalProcessing','-v','full_car_ar_parameters.prm');
    %FP1 FP2 F7 F3 Fz F4 F8 T7 C3 Cz C4 T8 P7 P3 Pz P4 Trig P8 O1 O2 EDC Trig2
    s = bci2000chain(full_fnames(ff).name,filter_parms(:,1),filter_parms{:,2});
    [n_samps,n_chans,n_freqs] = size(s.Signal);
    f_vec = s.ElementValues;
    trial_starts = find(diff([0;s.States.CurrentTrial])>0);
    go_cue_starts = 1+find(s.States.PresentationPhase(2:end)==3 & s.States.PresentationPhase(1:end-1)<3);
    
    for tt=1:length(trial_starts)
        ix = ix+1;
        if tt==length(trial_starts)
            trial_stop = n_samps;
        else
            trial_stop = trial_starts(tt+1);
        end
        trial_bool = (1:n_samps)>=trial_starts(tt) & (1:n_samps)<=trial_stop;
        trig_start = find(diff([0;s.Signal(:,17,end).*trial_bool'])>0,1,'first');
        
        baseline_end_time = s.Time(go_cue_starts(tt));
        baseline_bool = s.Time>=baseline_end_time+baseline_win(1) & s.Time<baseline_end_time+baseline_win(2);
        baseline_out(ix,:,:) = squeeze(mean(s.Signal(baseline_bool,:,:)));
        
        prestim_end_time = s.Time(trig_start);
        prestim_bool = s.Time>=prestim_end_time + prestim_win(1) & s.Time<prestim_end_time + prestim_win(2);
%         prestim_out(ff,tt,:,:) = squeeze(mean(s.Signal(prestim_bool,:,:)));
        prestim_out(ix,:,:) = squeeze(s.Signal(find(prestim_bool,1,'last'),:,:));
        
        %Convert to ERD
        prestim_out(ix,:,:) = 100 * (prestim_out(ix,:,:)./baseline_out(ix,:,:));
        
        target_code(ix) = s.States.TargetCode(go_cue_starts(tt));
    end    
end
prestim_out = reshape(prestim_out,[],n_chans*n_freqs);
% prestim_out = 10*log10(prestim_out);
prestim_out = log(prestim_out);
target_code = reshape(target_code,[],1);
target_code = 3-target_code;

%Nowextract the mep_p2p values.
[signal, states, parameters, total_samples, file_samples] = load_bcidat(full_fnames(:).name);
trigdat = signal(:,strcmpi(parameters.ChannelNames.Value,'Trig'));
trig_starts = find(diff([0;trigdat])>0);
emgdat = signal(:,strcmpi(parameters.ChannelNames.Value,'EDC'));
%reindex emgdat into samples x trials
mep_rel_sample = mep_win.*parameters.SamplingRate.NumericValue;%convert mep_win to n_samples
reix = bsxfun(@plus,trig_starts,mep_rel_sample(1):mep_rel_sample(2));
emgdat=emgdat(reix');
%Remove the offset from each trial.
mep_xvec = mep_win(1):1/parameters.SamplingRate.NumericValue:mep_win(2);
mep_xvec = mep_xvec(1:size(emgdat,1));
emgdat = bsxfun(@minus,emgdat,mean(emgdat(mep_xvec<0,:)));
plot(mep_xvec,emgdat)
xlim([0.005 0.05])
[mep_lims,~]=ginput(2);
mep_p2p = emgdat(mep_xvec>=mep_lims(1) & mep_xvec<=mep_lims(2),:);
% mep_p2p = max(mep_p2p)-min(mep_p2p);
mep_p2p = sum(abs(mep_p2p));
mep_p2p = mep_p2p';
mep_p2p = sqrt(mep_p2p);

ch_bool = logical([1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 1 1 0]);

trial_bool = ~any(abs(emgdat(mep_xvec<-0.005,:))>15);
trial_bool = trial_bool';

[r,p] = corrcoef([target_code prestim_out]);
r = r(2:end,1); r=sign(r).*(r.^2); p = p(2:end,1);
r = reshape(r,n_chans,n_freqs);
task_rsq = r;
task_rsq=task_rsq(ch_bool,:);

for tt=1:2
    [r,p] = corrcoef([mep_p2p(trial_bool & target_code==tt) prestim_out(trial_bool & target_code==tt,:)]);
    r = r(2:end,1); r=sign(r).*(r.^2); p = p(2:end,1);
    r = reshape(r,n_chans,n_freqs);
    mep_rsq(:,:,tt) = r;
end
mep_rsq=mep_rsq(ch_bool,:,:);

t_clim = max(max(abs(task_rsq)));
mep_clim = max(max(max(abs(mep_rsq))));

figure;
subplot(3,1,1)
imagesc(f_vec,1:sum(ch_bool),task_rsq)
xlabel('FREQ (hz)'), ylabel('CH #')
title('TASK R^2')
caxis([-1*t_clim t_clim])
colorbar

subplot(3,1,2)
imagesc(f_vec,1:sum(ch_bool),mep_rsq(:,:,2))
xlabel('FREQ (hz)'), ylabel('CH #')
title('MEP Imagery R^2')
caxis([-1*mep_clim mep_clim])
colorbar

subplot(3,1,3)
imagesc(f_vec,1:sum(ch_bool),mep_rsq(:,:,1))
xlabel('FREQ (hz)'), ylabel('CH #')
title('MEP Rest R^2')
caxis([-1*mep_clim mep_clim])
colorbar

parameters.ChannelNames.Value(ch_bool)'

topoFreqs = [10 23 28];
nf = numel(topoFreqs);
figure;
for tf = 1:nf
    f_ix = find(abs(f_vec-topoFreqs(tf))==min(abs(f_vec - topoFreqs(tf))),1,'first');
    subplot(3,nf,tf)
    topoplot(double(task_rsq(:,f_ix)),'eloc_gpassive.txt','EEG','maplimits',[-1*t_clim t_clim],'shading','interp')
    title(['Task ',num2str(topoFreqs(tf)),' Hz'])
    
    subplot(3,nf,nf+tf)
    topoplot(double(mep_rsq(:,f_ix,2)),'eloc_gpassive.txt','EEG','maplimits',[-1*mep_clim mep_clim],'shading','interp')
    title(['MEP Imagery - ',num2str(topoFreqs(tf)),' Hz'])
    
    subplot(3,nf,2*nf+tf)
    topoplot(double(mep_rsq(:,f_ix,1)),'eloc_gpassive.txt','EEG','maplimits',[-1*mep_clim mep_clim],'shading','interp')
    title(['MEP Rest - ',num2str(topoFreqs(tf)),' Hz'])
end