function ecog_corr_sep_acute(experiment)
%experiment=E3.Experiment('ECoG Acute SEPs');
n_permutations=0;
timeBins=[0 4 8 12 16 20 24].*(2*pi/24);
band_pow_lims=[-2.5 -1; 1 2.5];
pt_baseline=E3.Period_type('baseline');
stored_feature_names={'mb_db';'g1_db';'g2_db';'stim';'sep_p1';'sep_n1';'sep_p2';'sep_n2'};
% stored_feature_names={'sep_p1';'sep_n1';'sep_p2';'sep_n2'};
calc_feature_names={'tod';'p1n1';'p2n2'};
% calc_feature_names={'p1n1';'p2n2'};
tested_feature_names={'p1n1';'p2n2'};
ecog_feature_names={'mb_db';'g1_db';'g2_db'};
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
    feature_vals(:,strcmpi(feature_names,'tod'))=trials.get_tod;%tod
    p1=feature_vals(:,strcmpi(feature_names,'sep_p1'));
    n1=feature_vals(:,strcmpi(feature_names,'sep_n1'));
    p2=feature_vals(:,strcmpi(feature_names,'sep_p2'));
    n2=feature_vals(:,strcmpi(feature_names,'sep_n2'));
    if mean(n2)<=mean(n1)
        min_peak=2;
    else
        min_peak=1;
    end
    neg_peaks=[n1 n2];
    feature_vals(:,strcmpi(feature_names,'p1n1'))=p1-n1;
    feature_vals(:,strcmpi(feature_names,'p2n2'))=p1-neg_peaks(:,min_peak);
    output(aa).main_seps=feature_vals(:,[find(strcmpi(feature_names,'sep_p1')) find(strcmpi(feature_names,'sep_n1')) find(strcmpi(feature_names,'sep_p2')) find(strcmpi(feature_names,'sep_n2')) find(strcmpi(feature_names,'p1n1')) find(strcmpi(feature_names,'p2n2'))]);
    
    %Prepare parameters for testing features ...
    %...For diurnal rhythm
    nBins=length(timeBins)-1;
    tod_bool=false(length(trials),nBins);
    for bb=1:nBins
        tod_bool(:,bb)=feature_vals(:,strcmpi(feature_names,'tod'))>=timeBins(bb) & feature_vals(:,strcmpi(feature_names,'tod'))<timeBins(bb+1);
    end
    
    %...For separating based on band-power
    band_bool=false(length(trials),length(ecog_feature_names),size(band_pow_lims,1));
    ecog=NaN(length(trials),length(ecog_feature_names));
    for ee=1:length(ecog_feature_names)
        ecog(:,ee)=feature_vals(:,strcmpi(feature_names,ecog_feature_names{ee}));
        zecog=zscore(ecog(:,ee));
        for bb=1:size(band_pow_lims,1)
            band_bool(:,ee,bb)=zecog>=band_pow_lims(bb,1) & zecog<=band_pow_lims(bb,2);
        end
    end
    
    %...For RSq
    testX=zscore(ecog);
    
    %effect of band-power on evoked.
    for ee=1:size(band_bool,2) %for mb,g1,g2
        for bb=1:size(band_bool,3) %for hi and lo
            output(aa).lohi_evoked{ee,bb}=trials(band_bool(:,ee,bb)).get_avg_evoked([1 2 3]);
        end
    end
    
    %Now run through the test variables.
    for ff=1:length(tested_feature_names);
        y=feature_vals(:,strcmpi(feature_names,tested_feature_names{ff}));
        
        %diurnal rhythm
        for bb=1:nBins
            output(aa).diurnal(ff,bb)=mean(y(tod_bool(:,bb)));
        end
        
        %effect of band-power on feature average and evoked.
        for ee=1:size(band_bool,2) %for mb,g1,g2
            for bb=1:size(band_bool,3) %for hi and lo
                output(aa).lohi(ff,ee,bb)=mean(y(band_bool(:,ee,bb)));
                output(aa).lohi_evoked{ff,ee,bb}=trials(band_bool(:,ee,bb)).get_avg_evoked([1 2 3]);
            end
        end
        
        %Describe the relationship between ECoG and SEP size (tod, stim
        %controlled for)
        [X_sin,coeffs]=linzer.sinusoidal(feature_vals(:,strcmpi(feature_names,'tod')),y); %#ok<*NASGU>
        [X_piece,pp]=linzer.piecewise(feature_vals(:,strcmpi(feature_names,'stim')),y);
        zy=zscore(y);
        controlX=[zscore(X_sin) zscore(X_piece)];
        [output(aa).RSq(ff,:),output(aa).simRSq(ff,:,:),output(aa).realP(ff,:),output(aa).realB(ff,:,:)]=linzer.multi_rsq_with_permutation(zy,controlX,testX,n_permutations);
    end
    
    %
    ad_names={ani.SubjectDetails.Name};
    base_start=str2double(ani.SubjectDetails(strcmpi(ad_names,'sep_base_start_ms')).Value);
    base_stop=str2double(ani.SubjectDetails(strcmpi(ad_names,'sep_base_stop_ms')).Value);
    p1_start=str2double(ani.SubjectDetails(strcmpi(ad_names,'sep_p1_start_ms')).Value);
    p1_stop=str2double(ani.SubjectDetails(strcmpi(ad_names,'sep_p1_stop_ms')).Value);
    n1_start=str2double(ani.SubjectDetails(strcmpi(ad_names,'sep_n1_start_ms')).Value);
    n1_stop=str2double(ani.SubjectDetails(strcmpi(ad_names,'sep_n1_stop_ms')).Value);
    p2_start=str2double(ani.SubjectDetails(strcmpi(ad_names,'sep_p2_start_ms')).Value);
    p2_stop=str2double(ani.SubjectDetails(strcmpi(ad_names,'sep_p2_stop_ms')).Value);
    n2_start=str2double(ani.SubjectDetails(strcmpi(ad_names,'sep_n2_start_ms')).Value);
    n2_stop=str2double(ani.SubjectDetails(strcmpi(ad_names,'sep_n2_stop_ms')).Value);
    output(aa).peak_times=[p1_start p1_stop n1_start n1_stop p2_start p2_stop n2_start n2_stop];
    
    %Calculate evoked and RSq for other electrodes if possible
%     output(aa).evoked=trials.get_avg_evoked;
    chan_is_ecog=[ani.Channels.TotalAmplification]==10000;
    chan_is_good=[ani.Channels.IsGood];
    if sum(chan_is_ecog & chan_is_good)>1
        be_id=str2double(ani.SubjectDetails(strcmpi(ad_names,'best_ecog_channel_id')).Value);        
        cx=0;
        for cc=1:length([ani.Channels])
            if cc~=be_id && chan_is_ecog(cc) && chan_is_good(cc)
                cx=cx+1;
                base_values=get_td_feature(trials,[2 3],[base_start base_stop],cc,false);
                p1_values=get_td_feature(trials,[2 3],[p1_start p1_stop],cc,false)-base_values;
                n1_values=get_td_feature(trials,[2 3],[n1_start n1_stop],cc,false)-base_values;
%                 p2_values=get_td_feature(trials,[2 3],[p2_start p2_stop],cc,false)-base_values;
                n2_values=get_td_feature(trials,[2 3],[n2_start n2_stop],cc,false)-base_values;
                p1n1=p1_values-n1_values;
                if min_peak==1
                    p2n2=p1_values-n1_values;
                else
                    p2n2=p1_values-n2_values;
                end
                %temp_vars=[p1_values' n1_values' p2_values' n2_values' p1n1' p2n2'];
                output(aa).other_seps(:,:,cx)=p2n2';%temp_vars;
%                 for ff=1:length(tested_feature_names);
%                     y=temp_vars(:,ff);
%                     [X_sin,coeffs]=linzer.sinusoidal(feature_vals(:,strcmpi(feature_names,'tod')),y);
%                     [X_piece,pp]=linzer.piecewise(feature_vals(:,strcmpi(feature_names,'stim')),y);
%                     zy=zscore(y);
%                     controlX=[zscore(X_sin) zscore(X_piece)];
%                     [output(aa).other_RSq(ff,:,cx),output(aa).other_simRSq(ff,:,:,cx),output(aa).other_realP(ff,:,cx),output(aa).other_realB(ff,:,:,cx)]=...
%                         linzer.multi_rsq_with_permutation(zy,controlX,testX,n_permutations);
%                 end
            end
        end
    end
    toc
end

%diurnal is sep features x time window
%lohi is sep features x ecog features x lo/hi
%lohi_evoked is {sep features x ecog features x lo/hi}
%RSq is sep features x ecog features
%simRSq is features x n_permutations x ecog_features
%realP is features x ecog features
%realB is features x ecog features x predictors ([ones controlX])
global ECOG_SEP_ACUTE
ECOG_SEP_ACUTE=output;
fprintf('See ECOG_SEP_ACUTE\n');
save('acute_ecog_sep_rsq.mat','ECOG_SEP_ACUTE');