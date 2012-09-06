%SETUP THE DATABASE. ONLY NECESSARY ONCE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Get or create the subject_type
sub_type = EERAT.SubjectType(dbx,'Name','ghi_stroke');
sub_type.Description='Data collected using g.tec Matlab Simulink';

%Get or create detail_type and add to subject_type
det_names={'subj_stroke';'subj_injury_date'};
sub_dets(length(det_names))=EERAT.DetailType;
for dd=1:length(det_names)
    sub_dets(dd)=EERAT.DetailType(dbx,'Name',det_names{dd}); %get_or_create
end
sub_type.detail_types=sub_dets;%add to subject_type
clear dd sub_dets

%Get or create datum_type (i.e. period and trial type)
dat_lr_imagery = EERAT.DatumType(dbx,'Name','lr_imagery');
dat_lr_imagery.Description='Left or Right Hand Imagery';

%Get or create feature_types and add them to the datum_type
fts(length(ft_names)*length(ft_freq_centers))=EERAT.FeatureType;
for ft=1:length(ft_names)
    for ff=1:length(ft_freq_centers)
        %get or create
        fts((ft-1)*length(ft_freq_centers)+ff)=EERAT.FeatureType(dbx,'Name',[ft_names{ft},'_',num2str(ft_freq_centers(ff)),'Hz']);
    end
end
dat_lr_imagery.feature_types=fts;
clear ff ft fts

%Get or create detail_type and add to datum_type
det_task_condition = EERAT.DetailType(dbx,'Name','dat_task_condition');
det_task_condition.Description='Which task was used this trial (e.g. 0 or 1)';
det_task_condition.DefaultValue='0';
dat_lr_imagery.detail_types=det_task_condition;
clear det_task_condition;