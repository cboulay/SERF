function ecog_corr_emg_acute(experiment)
n_permutations=1000;
timeBins=[0 4 8 12 16 20 24].*(2*pi/24);
band_pow_lims=[-2.5 -1; 1 2.5];
bgRegBinEdges=-2:0.4:2;
% pt_baseline=E3.Period_type('baseline');
stored_feature_names={'mb_db';'g1_db';'g2_db';'stim';'BGE';'MW';'HR'};
calc_feature_names={'tod';'HRR'};%HRR is only used for diurnal.
ecog_feature_names={'mb_db';'g1_db';'g2_db'};
% tested_feature_names={'BGE';'HR'};
fts(length(stored_feature_names))=E3.Feature_type(stored_feature_names{end});
for ff=1:length(stored_feature_names)-1
    fts(ff)=E3.Feature_type(stored_feature_names{ff});
end
feature_names=[stored_feature_names;calc_feature_names];
n_features=length(feature_names);
linzer=E3.Linearize;
anis=experiment.Subjects;
clear output
for aa=1:length(anis)
    tic
    ani=anis(aa);
    be_id=str2double(ani.SubjectDetails(strcmpi({ani.SubjectDetails.Name},'best_ecog_channel_id')).Value);
    %Restore this line if we need the total number, including ~IsGood
    %     trials=ani.get_trials_for_pt(pt_baseline,false);
    %     output(aa).n_total_trials=length(trials); %#ok<*AGROW>
    %Get baseline trials, only is good
    baseline=ani.Periods(strcmpi({ani.Periods.Name},'baseline'));
    trials=baseline.get_trials(true);
    output(aa).n_good_trials=length(trials);
    
    %Get stored features
    feature_vals=NaN(output(aa).n_good_trials,n_features);
    for ff=1:length(stored_feature_names)
        feature_vals(:,strcmpi(feature_names,fts(ff).Name))=trials.get_feature_value_for_ft(fts(ff));
    end
    %Calculated features
    feature_vals(:,strcmpi(feature_names,'tod'))=trials.get_tod;%tod.
    %1pm - 12:59pm = 0 - 2pi. i.e. 8am=2*pi*19/24; 2pm=2*pi*1/24
    y=feature_vals(:,strcmpi(feature_names,'HR'));
    [X_sin,coeffs]=linzer.sinusoidal(feature_vals(:,strcmpi(feature_names,'tod')),y); %#ok<*NASGU>
    [X_piece,pp]=linzer.piecewise(feature_vals(:,strcmpi(feature_names,'stim')),y);
    controlX=[ones(size(y)) zscore(X_sin) zscore(X_piece)];
    [~,~,HRR,~]=regress(y,controlX);
    feature_vals(:,strcmpi(feature_names,'HRR'))=HRR;
    [~,~,zHRR,~]=regress(zscore(y),controlX);
    
    
    output(aa).descriptives=[mean(feature_vals);std(feature_vals)];
    
    feature_zs=zscore(feature_vals);
    
    %Principal components analysis
%     spectra=trials.get_spectrum(be_id);
%     spectra=spectra';
%     zspectra=zscore(spectra);
%     [temp,~,~,~]=princomp(zspectra);
%     output(aa).prinCompCoeff=temp(:,1:5);
    
%     %Diurnal rhythm
%     nBins=length(timeBins)-1;
%     for bb=1:nBins
%         %First bin is 1300:1700. Last bin is 900:1300
%         tod_bool=feature_vals(:,strcmpi(feature_names,'tod'))>=timeBins(bb) & feature_vals(:,strcmpi(feature_names,'tod'))<timeBins(bb+1);
%         if any(tod_bool)
%             for ff=1:length(feature_names)
%                 output(aa).diurnal(ff,bb)=mean(feature_vals(tod_bool,strcmpi(feature_names,feature_names{ff})));
%                 output(aa).diurnalz(ff,bb)=mean(feature_zs(tod_bool,strcmpi(feature_names,feature_names{ff})));
%             end
%         end
%     end
    
    %Effect of band-power on evoked, feature-average and BGE vs HR
    %regressions.
    %Calculate some variables for the regression
    
%     zBGE=feature_zs(:,strcmpi(feature_names,'BGE'));
%     nBgBins=length(bgRegBinEdges)-1;
%     
    ecog=NaN(length(trials),length(ecog_feature_names));
    for ee=1:length(ecog_feature_names) %For each ecog feature
        ecog(:,ee)=feature_vals(:,strcmpi(feature_names,ecog_feature_names{ee}));
%         zecog=zscore(ecog(:,ee));
%         for bb=1:size(band_pow_lims,1) %For lo and hi
%             band_bool=zecog>=band_pow_lims(bb,1) & zecog<=band_pow_lims(bb,2);
%             %evoked
%             output(aa).lohi_evoked{ee,bb}=trials(band_bool).get_avg_evoked([1 2 3]);
%             
%             %feature-average
%             output(aa).lohi(1,ee,bb)=mean(feature_vals(band_bool,strcmpi(feature_names,'BGE')));
%             output(aa).lohi(2,ee,bb)=mean(feature_vals(band_bool,strcmpi(feature_names,'MW')));
%             output(aa).lohi(3,ee,bb)=mean(feature_vals(band_bool,strcmpi(feature_names,'HR')));
%             
%             %BGE vs HR regressions. I'm not sure why I don't get the
%             %coefficients from the single trials, then get the example
%             %plots from the binned.
%             tempBGHR=NaN(nBgBins,2);
%             tempNTrials=NaN(nBgBins,1);
%             for bg=1:nBgBins
%                 thisSubBool=band_bool & (zBGE>=bgRegBinEdges(bg) & zBGE<bgRegBinEdges(bg+1));
%                 tempBGHR(bg,:)=[mean(zBGE(thisSubBool)) mean(zHRR(thisSubBool))];
%                 tempNTrials(bg)=sum(thisSubBool);
%             end
%             tempBGHR=tempBGHR(tempNTrials>50,:);
%             output(aa).bg_hr_lohi_b(ee,bb,:)=regress(tempBGHR(:,2),[ones(size(tempBGHR(:,2))) tempBGHR(:,1)]);
%             tempR=corrcoef(tempBGHR(:,1),tempBGHR(:,2));
%             output(aa).bg_hr_lohi_r(ee,bb)=tempR(2,1);
%         end
    end
    
    %Describe the relationship between ECoG and EMG
%     testX=[zspectra zscore(ecog)];
    testX=zscore(ecog);
    
    %BGE; tod controlled for
    y=feature_vals(:,strcmpi(feature_names,'BGE'));
    [X_sin,coeffs]=linzer.sinusoidal(feature_vals(:,strcmpi(feature_names,'tod')),y); %#ok<*NASGU>
    controlX=zscore(X_sin);
    zy=zscore(y);
    [output(aa).BGERSq,output(aa).BGEsimRSq,output(aa).BGErealP,output(aa).BGErealB]=linzer.multi_rsq_with_permutation(zy,controlX,testX,n_permutations);
    
    %HR; tod and stim controlled for
    y=feature_vals(:,strcmpi(feature_names,'HR'));
    [X_sin,coeffs]=linzer.sinusoidal(feature_vals(:,strcmpi(feature_names,'tod')),y); %#ok<*NASGU>
    [X_piece,pp]=linzer.piecewise(feature_vals(:,strcmpi(feature_names,'stim')),y);
    controlX=[zscore(X_sin) zscore(X_piece)];
    zy=zscore(y);
    [output(aa).HRRSq,output(aa).HRsimRSq,output(aa).HRrealP,output(aa).HRrealB]=linzer.multi_rsq_with_permutation(zy,controlX,testX,n_permutations);
    
    %HRR;  tod, stim and BGE controlled for
    controlX=[zscore(X_sin) zscore(X_piece) feature_zs(:,strcmpi(feature_names,'BGE'))];
    [output(aa).HRRRSq,output(aa).HRRsimRSq,output(aa).HRRrealP(3,:),output(aa).HRRrealB]=linzer.multi_rsq_with_permutation(zy,controlX,testX,n_permutations);
        
%     %Calculate RSq for other electrodes if possible
%     chan_is_ecog=[ani.Channels.TotalAmplification]==10000;
%     chan_is_good=[ani.Channels.IsGood];
%     if sum(chan_is_ecog & chan_is_good)>1
%         ad_names={ani.SubjectDetails.Name};
%         be_id=str2double(ani.SubjectDetails(strcmpi(ad_names,'best_ecog_channel_id')).Value);
%         cx=0;
%         for cc=1:length([ani.Channels])
%             if cc~=be_id && chan_is_ecog(cc) && chan_is_good(cc)
%                 cx=cx+1;
%                 %Get band power values for each trial in this channel
%                 [temp_mb,freqs]=get_power(trials,[25, 17.5, 17.5, 25, 10, 0, NaN],cc);
%                 [temp_g1,freqs]=get_power(trials,[25, 62.5, 62.5, 45, 10, 0, NaN],cc);
%                 [temp_g2,freqs]=get_power(trials,[25, 150, 150, 100, 10, 0, NaN],cc);
%                 %Correlate (zscore) band-power with BGE, HR, HRR
%                 testX=zscore([temp_mb temp_g1 temp_g2]);
%                 %BGE
%                 y=feature_vals(:,strcmpi(feature_names,'BGE'));
%                 [X_sin,coeffs]=linzer.sinusoidal(feature_vals(:,strcmpi(feature_names,'tod')),y); %#ok<*NASGU>
%                 controlX=zscore(X_sin);
%                 zy=zscore(y);
%                 [output(aa).other_BGERSq(:,cx),output(aa).other_BGEsimRSq(:,:,cx),output(aa).other_BGErealP(:,cx),output(aa).other_BGErealB(:,:,cx)]=...
%                     linzer.multi_rsq_with_permutation(zy,controlX,testX,0);
%                 
%                 %HR
%                 y=feature_vals(:,strcmpi(feature_names,'HR'));
%                 [X_sin,coeffs]=linzer.sinusoidal(feature_vals(:,strcmpi(feature_names,'tod')),y); %#ok<*NASGU>
%                 [X_piece,pp]=linzer.piecewise(feature_vals(:,strcmpi(feature_names,'stim')),y);
%                 controlX=[zscore(X_sin) zscore(X_piece)];
%                 zy=zscore(y);
%                 [output(aa).other_HRRSq(:,cx),output(aa).other_HRsimRSq(:,:,cx),output(aa).other_HRrealP(:,cx),output(aa).other_HRrealB(:,:,cx)]=...
%                     linzer.multi_rsq_with_permutation(zy,controlX,testX,0);
%                 
%                 %HR controlling for tod, stim and BGE
%                 controlX=[zscore(X_sin) zscore(X_piece) zscore(feature_vals(:,strcmpi(feature_names,'BGE')))];
%                 [output(aa).other_HRRRSq(:,cx),output(aa).other_HRRsimRSq(:,:,cx),output(aa).other_HRRrealP(:,cx),output(aa).other_HRRrealB(:,:,cx)]=...
%                     linzer.multi_rsq_with_permutation(zy,controlX,testX,0);
%             end
%         end
%     end
    
    output(aa).freqs=ani.Freqs;
    output(aa).t_vec=ani.T_vec;
    toc
end

%diurnal is sep features x time window
%lohi is sep features x ecog features x lo/hi
%lohi_evoked is {sep features x ecog features x lo/hi}
%RSq is sep features x ecog features
%simRSq is features x n_permutations x ecog_features
%realP is features x ecog features
%realB is features x ecog features x predictors ([ones controlX])
global ECOG_EMG
ECOG_EMG=output;
fprintf('See ECOG_EMG\n');
save('C:\Users\cboulayadmin\Desktop\Dropbox\My Dropbox\Thesis\Resources\AcutePaper\emg.mat','ECOG_EMG');