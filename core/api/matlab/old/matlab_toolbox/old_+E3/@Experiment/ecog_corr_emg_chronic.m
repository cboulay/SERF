function ecog_corr_emg_chronic(experiment)
% experiment=E3.Experiment('ECoG Chronic EMG');
anis=experiment.Subjects;

stored_feature_type_names={'BGE';'MW';'HR';'mb_db';'g1_db';'g2_db';'stim'};
clear stored_feature_types
stored_feature_types(length(stored_feature_type_names))=E3.Feature_type(stored_feature_type_names{end});
for ff=1:length(stored_feature_type_names)-1
    stored_feature_types(ff)=E3.Feature_type(stored_feature_type_names{ff});
end

calculated_feature_type_names={'tod';'HRR'};

feature_type_names=[stored_feature_type_names;calculated_feature_type_names];

linzer=E3.Linearize;

for aa=1:length(anis)
    tic
    fprintf(['\n',num2str(aa),' of ',num2str(length(anis)),'\n']);
    ani=anis(aa);
%     output(aa).ani_name=ani.Name;
    
    %Get the coefficients to calculate hrr from baseline period.
    base_period=ani.Periods(strcmpi({ani.Periods.Name},'baseline'));
    base_trials=base_period.get_trials(true);
    base_bge=base_trials.get_feature_value_for_ft(stored_feature_types(strcmpi({stored_feature_types.Name},'BGE')))';
    base_mw=base_trials.get_feature_value_for_ft(stored_feature_types(strcmpi({stored_feature_types.Name},'MW')))';
    base_hr=base_trials.get_feature_value_for_ft(stored_feature_types(strcmpi({stored_feature_types.Name},'HR')))';
    %Get the parameters that transform the mw vs hr relationship to linear.
%     tmp_mw=base_mw-base_bge; %M-wave is superimposed on top of BGE
%     poly_coeffs = polyfit(tmp_mw(tmp_mw>0),base_hr(tmp_mw>0),2); %quadratic fit
%     mw_est_hr=polyval(poly_coeffs,tmp_mw);
%     b_hrr=[ones(size(base_hr)) base_bge mw_est_hr]\base_hr; %the coefficients of the hr vs bge + mw fit
    b_hrr=[ones(size(base_hr)) base_bge base_mw]\base_hr; %the coefficients of the hr vs bge + mw fit
    baseline_hr=nanmean(base_hr)-nanmean(base_bge);
    
    periods=ani.Periods;
    n_pers=length(periods);
    for pp=1:1%n_pers
        per=periods(pp);
        %since I wish to do statistical tests on whether or not each
        %feature has changed, I need to get the single-trial variables for
        %each. Only for periods.
        trials=per.get_trials(true);
        feature_values=NaN(length(trials),length(feature_type_names));
        %get BGE, MW, HR, mb, g1, g2, p1, n1, p2, n2
        for ff=1:length(stored_feature_types)
            feature_values(:,strcmpi(feature_type_names,stored_feature_type_names{ff}))=...
                trials.get_feature_value_for_ft(stored_feature_types(ff));
        end
        %calculate tod, HRR
        feature_values(:,strcmpi(feature_type_names,'tod'))=trials.get_tod;
        %Get HRR using coefficients obtained from baseline period.
        mw=feature_values(:,strcmpi(feature_type_names,'MW'));
        bge=feature_values(:,strcmpi(feature_type_names,'BGE'));
        hr=feature_values(:,strcmpi(feature_type_names,'HR'));
%         mw_est_hr=polyval(poly_coeffs,mw-bge);
%         hrr=hr-[ones(size(hr)) bge mw_est_hr]*b_hrr;
        hrr=hr-[ones(size(hr)) bge mw]*b_hrr;
        hrr=100*hrr./baseline_hr;
        feature_values(:,strcmpi(feature_type_names,'HRR'))=hrr;
        if pp==1
            baseline_feature_values=feature_values;
        end
        
%         output(aa).period_feature_values(:,pp)=nanmean(feature_values); %#ok<*AGROW>
        
%         for ff=1:size(feature_values,2)
%             [h,output(aa).feature_p_values(ff,pp)]=ttest2(feature_values(:,ff),baseline_feature_values(:,ff)); %#ok<ASGLU>
%         end
%         
%         %BGE vs HR coeffs
%         output(aa).period_bge_hr_coeffs(:,pp)=[ones(size(hr)) bge]\hr;
%         
%         %ECoG bands vs HR RSq, adjusted for lin_tod, lin_stim, and BGE
%         %Covariates
        tod=feature_values(:,strcmpi(feature_type_names,'tod'));
        [lin_tod,x_tod]=linzer.sinusoidal(tod,hr);
        stim=feature_values(:,strcmpi(feature_type_names,'stim'));
        [lin_stim,piecepol]=linzer.piecewise(stim,hr);
%         %Tested predictors. I'm not saving the coefficients, so there is no
%         %need to standardize the predictors.
%         testX=[feature_values(:,strcmpi(feature_type_names,'mb_db')) feature_values(:,strcmpi(feature_type_names,'g1_db')) feature_values(:,strcmpi(feature_type_names,'g2_db'))];
%         
%         [output(aa).HRRSq(:,pp),~,~,~]=linzer.multi_rsq_with_permutation(hr,[lin_tod lin_stim],testX,0);
%         [output(aa).HRRRSq(:,pp),~,~,~]=linzer.multi_rsq_with_permutation(hr,[lin_tod lin_stim bge],testX,0);
%         
%         %ECoG bands vs BGE RSq. Adjust for tod.
        [lin_tod_bge,x_tod_bge]=linzer.sinusoidal(tod,bge); %#ok<*NASGU>
%         [output(aa).BGERSq(:,pp),~,~,~]=linzer.multi_rsq_with_permutation(bge,lin_tod_bge,testX,0);
    end
    
    %Now do days.
    days=ani.Days;
    day_dates=datenum({days.Date});
    cond_onset=datenum(ani.SubjectDetails(strcmpi({ani.SubjectDetails.Name},'cond_onset_date')).Value);
    day_vec=day_dates-cond_onset+1;
    day_bool=day_vec<=60;
%     output(aa).day_vec=day_vec(day_bool); %Day number relative to conditioning onset (=+1)
    days=days(day_bool);
    %Get variable for each day.
    for dd=1:length(days)
        fprintf('.');
%         for ff=1:length(stored_feature_types)
%             output(aa).day_feature_values(ff,dd)=days(dd).get_feature_value_for_ft(stored_feature_types(ff));
%         end
%         output(aa).day_feature_values(strcmpi(feature_type_names,'tod'),dd)=NaN;
%         %calculate HRR
%         day_bge=output(aa).day_feature_values(strcmpi(feature_type_names,'BGE'),dd);
%         day_mw=output(aa).day_feature_values(strcmpi(feature_type_names,'MW'),dd);
%         day_hr=output(aa).day_feature_values(strcmpi(feature_type_names,'HR'),dd);
%         day_mw_est_hr=polyval(poly_coeffs,day_mw-day_bge);
%         hrr=day_hr-[ones(size(day_hr)) day_bge day_mw_est_hr]*b_hrr;
%         hrr=day_hr-[ones(size(day_hr)) day_bge day_mw]*b_hrr;
%         hrr=100*hrr./baseline_hr;
%         output(aa).day_feature_values(strcmpi(feature_type_names,'HRR'),dd)=hrr;
        
%         %BGE vs HR coeffs
%         day_trials=days(dd).get_trials(true);
%         day_trials_bge=day_trials.get_feature_value_for_ft(stored_feature_types(strcmpi({stored_feature_types.Name},'BGE')))';
%         day_trials_hr=day_trials.get_feature_value_for_ft(stored_feature_types(strcmpi({stored_feature_types.Name},'HR')))';
%         output(aa).day_bge_hr_coeffs(:,dd)=[ones(size(day_trials_hr)) day_trials_bge]\day_trials_hr;

        %HRR RSq
        %ECoG bands vs HR RSq, adjusted for lin_tod, lin_stim, and BGE
        day=days(dd);
        trials=day.get_trials(true);
        tod=trials.get_tod;
        bge=trials.get_feature_value_for_ft(stored_feature_types(1));
        mw=trials.get_feature_value_for_ft(stored_feature_types(2));
        hr=trials.get_feature_value_for_ft(stored_feature_types(3));
        mb_db=trials.get_feature_value_for_ft(stored_feature_types(4));
        g1_db=trials.get_feature_value_for_ft(stored_feature_types(5));
        g2_db=trials.get_feature_value_for_ft(stored_feature_types(6));
        stim=trials.get_feature_value_for_ft(stored_feature_types(7));
        lin_tod=x_tod(1).*cos(tod-x_tod(2))+x_tod(3);
        lin_stim=ppval(piecepol,stim);
        testX=[mb_db' g1_db' g2_db'];
        [output(aa).day_HRRSq(:,dd),~,~,~]=linzer.multi_rsq_with_permutation(hr',[lin_tod lin_stim'],testX,0);
        [output(aa).day_HRRRSq(:,dd),~,~,~]=linzer.multi_rsq_with_permutation(hr',[lin_tod lin_stim' bge'],testX,0);
        lin_tod_bge=x_tod_bge(1).*cos(tod-x_tod_bge(2))+x_tod_bge(3);
        [output(aa).day_BGERSq(:,dd),~,~,~]=linzer.multi_rsq_with_permutation(bge',lin_tod_bge,testX,0);
    end
    toc
end

global ECOG_EMG_CHRONIC
ECOG_EMG_CHRONIC=output;
fprintf('See ECOG_EMG_CHRONIC\n');
save('chronic_ecog_emg_rsq.mat','ECOG_EMG_CHRONIC');