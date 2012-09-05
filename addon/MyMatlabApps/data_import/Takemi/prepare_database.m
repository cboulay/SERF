%SETUP THE DATABASE FOR TAKEMI's DATA.
%This only needs to be done once.
if ~exist('dbx','var')
    dbx=EERAT.Dbmym('eerat');
end

%Get or create subject_type
sub_type = EERAT.SubjectType(dbx,'Name','ghi_healthy','Description','Control subject using gHiSys');

%Get or create the datum_types
%Takemi's trials actually 
dat_type = EERAT.DatumType(dbx,'Name','Takemi_MI_mep');
dat_type.Description='TMS during motor imagery. No EMG saved.';
dat_type.TrialClass = 'ERDMEPTrial';

dets = {'dat_task_condition' 'Which task was used this trial (e.g. 0 or 1)' '0';
    'dat_BG_start_ms' 'Bkgnd start window in ms' '-500';
    'dat_BG_stop_ms' 'Bkgnd stop window in ms' '-1';
    'dat_prestim_start_ms' 'Prestim start window in ms' '-500';
    'dat_prestim_stop_ms' 'Prestim stop window in ms' '0';
    'dat_TMS_powerA' 'Stimulator output in percent' '0';
    'dat_TMS_powerB' 'Second intensity in Bistim' '0';
    'dat_TMS_ISI' 'TMS ISI in ms' '0';
    };

%Get or create detail_types
detail_types(size(dets,1)) = EERAT.DetailType;
for dd=1:size(dets,1)
    detail_types(dd) = EERAT.DetailType(dbx,'Name',dets{dd,1},'Description',dets{dd,2},'DefaultValue',dets{dd,3});
end
% and add to datum_type
dat_type.detail_types=detail_types;

%Get or create feature_type
feature_type = EERAT.FeatureType(dbx,'Name','MEP_p2p');
dat_type.feature_types=feature_type;

clear dat_type dets dd detail_types dets sub_type feature_type