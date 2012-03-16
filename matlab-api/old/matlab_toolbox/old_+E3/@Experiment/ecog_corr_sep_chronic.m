function ecog_corr_sep_chronic(experiment)
% experiment=E3.Experiment('ECoG Chronic SEPs');
anis=experiment.Subjects;

stored_feature_type_names={'mb_db';'g1_db';'g2_db';'sep_p1';'sep_n1';'sep_p2';'sep_n2';'stim'};
clear stored_feature_types
stored_feature_types(length(stored_feature_type_names))=E3.Feature_type(stored_feature_type_names{end});
for ff=1:length(stored_feature_type_names)-1
    stored_feature_types(ff)=E3.Feature_type(stored_feature_type_names{ff});
end
calculated_feature_type_names={'P1-N1';'P1-N2';'tod'};
feature_type_names=[stored_feature_type_names;calculated_feature_type_names];

linzer=E3.Linearize;

for aa=1:length(anis)
    tic
    fprintf(['\n',num2str(aa),' of ',num2str(length(anis)),'\n']);
    ani=anis(aa);
    output(aa).ani_name=ani.Name;
    
    periods=ani.Periods;
    n_pers=length(periods);
    for pp=1:n_pers
        per=periods(pp);
        %since I wish to do statistical tests on whether or not each
        %feature has changed, I need to get the single-trial variables for
        %each.
        trials=per.get_trials(true);
        feature_values=NaN(length(trials),length(feature_type_names));
        %get mb, g1, g2, p1, n1, p2, n2
        for ff=1:length(stored_feature_types)
            feature_values(:,strcmpi(feature_type_names,stored_feature_type_names{ff}))=...
                trials.get_feature_value_for_ft(stored_feature_types(ff));
        end
        %calculate P1-N1, P2-N2, tod
        p1=feature_values(:,strcmpi(feature_type_names,'sep_p1'));
        n1=feature_values(:,strcmpi(feature_type_names,'sep_n1'));
        p2=feature_values(:,strcmpi(feature_type_names,'sep_p2'));
        n2=feature_values(:,strcmpi(feature_type_names,'sep_n2'));
        %find the peak that's most negative.
        if pp==1
            if mean(n2)<=mean(n1)
                min_peak=2;
            else
                min_peak=1;
            end
        end
        neg_peaks=[n1 n2];
        feature_values(:,strcmpi(feature_type_names,'P1-N1'))=p1-n1;
        feature_values(:,strcmpi(feature_type_names,'P1-N2'))=p1-neg_peaks(:,min_peak);
        feature_values(:,strcmpi(feature_type_names,'tod'))=trials.get_tod;
        %Store baseline features for future t-tests
        if pp==1
            baseline_feature_values=feature_values;
        end
        %Save feature average values
        output(aa).period_feature_values(:,pp)=nanmean(feature_values); %#ok<*AGROW>
        %t-test feature vs baseline
        for ff=1:size(feature_values,2)
            [h,output(aa).feature_p_values(ff,pp)]=ttest2(feature_values(:,ff),baseline_feature_values(:,ff)); %#ok<ASGLU>
        end
        
        %ECoG bands vs P1-N1, P2-N2
        %Covariates tod and stim
        tod=feature_values(:,strcmpi(feature_type_names,'tod'));
        stim=feature_values(:,strcmpi(feature_type_names,'stim'));
        peaks=NaN(length(trials),2);
        peaks(:,1)=feature_values(:,strcmpi(feature_type_names,'P1-N1'));
        peaks(:,2)=feature_values(:,strcmpi(feature_type_names,'P1-N2'));
        testX=[feature_values(:,strcmpi(feature_type_names,'mb_db')) feature_values(:,strcmpi(feature_type_names,'g1_db')) feature_values(:,strcmpi(feature_type_names,'g2_db'))];
        for pe=1:2
            [lin_tod,x]=linzer.sinusoidal(tod,peaks(:,pe)); %#ok<*NASGU>
            [lin_stim,piecepol]=linzer.piecewise(stim,peaks(:,pe));
            [output(aa).SEPSq(:,pe,pp),~,~,~]=linzer.multi_rsq_with_permutation(peaks(:,pe),[lin_tod lin_stim],testX,0);
        end
    end
    
    %Now do days.
    days=ani.Days;
    day_dates=datenum({days.Date});
    cond_onset=datenum(ani.SubjectDetails(strcmpi({ani.SubjectDetails.Name},'cond_onset_date')).Value);
    day_vec=day_dates-cond_onset+1;
    day_bool=day_vec<=60;
    output(aa).day_vec=day_vec(day_bool); %Day number relative to conditioning onset (=+1)
    days=days(day_bool);
    %Get variable for each day.
    for dd=1:length(days)
        fprintf('.');
        for ff=1:length(stored_feature_types)
            output(aa).day_feature_values(ff,dd)=days(dd).get_feature_value_for_ft(stored_feature_types(ff));
        end
        p1=output(aa).day_feature_values(strcmpi(feature_type_names,'sep_p1'),dd);
        n1=output(aa).day_feature_values(strcmpi(feature_type_names,'sep_n1'),dd);
        p2=output(aa).day_feature_values(strcmpi(feature_type_names,'sep_p2'),dd);
        n2=output(aa).day_feature_values(strcmpi(feature_type_names,'sep_n2'),dd);
        neg_peaks=[n1 n2];
        output(aa).day_feature_values(strcmpi(feature_type_names,'P1-N1'),dd)=p1-n1;
        output(aa).day_feature_values(strcmpi(feature_type_names,'P1-N2'),dd)=p1-neg_peaks(:,min_peak);
        output(aa).day_feature_values(strcmpi(feature_type_names,'tod'),dd)=NaN;
    end
    toc
end

global ECOG_SEP_CHRONIC
ECOG_SEP_CHRONIC=output;
fprintf('See ECOG_SEP_CHRONIC\n');
save('chronic_ecog_sep_rsq.mat','ECOG_SEP_CHRONIC');