function ecog_intermittent_chronic(experiment)
% experiment=E3.Experiment('ECoG Chronic Intermittent');
anis=experiment.Animals;

stored_feature_type_names={'mb_db';'g1_db';'g2_db'};
clear stored_feature_types
stored_feature_types(length(stored_feature_type_names))=E3.Feature_type(stored_feature_type_names{end});
for ff=1:length(stored_feature_type_names)-1
    stored_feature_types(ff)=E3.Feature_type(stored_feature_type_names{ff});
end
feature_type_names=stored_feature_type_names;

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
        %each. Only for periods.
        trials=per.get_trials(true);
        feature_values=NaN(length(trials),length(feature_type_names));
        for ff=1:length(stored_feature_types)
            feature_values(:,strcmpi(feature_type_names,stored_feature_type_names{ff}))=...
                trials.get_feature_value_for_ft(stored_feature_types(ff));
        end
        if pp==1
            baseline_feature_values=feature_values;
        end
        output(aa).period_feature_values(:,pp)=nanmean(feature_values); %#ok<*AGROW>
        
        for ff=1:size(feature_values,2)
            [h,output(aa).feature_p_values(ff,pp)]=ttest2(feature_values(:,ff),baseline_feature_values(:,ff)); %#ok<ASGLU>
        end
        
    end
    
    %Now do days.
    days=ani.Days;
    day_dates=datenum({days.Date});
    cond_onset=datenum(ani.AnimalDetails(strcmpi({ani.AnimalDetails.Name},'cond_onset_date')).Value);
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
    end
    toc
end

global ECOG_INTERMITTENT_CHRONIC
ECOG_INTERMITTENT_CHRONIC=output;
fprintf('See ECOG_INTERMITTENT_CHRONIC\n');
save('chronic_ecog_intermittent.mat','ECOG_INTERMITTENT_CHRONIC');