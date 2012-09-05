import Takemi.*
%Each subject underwent 4 conditions: disc, RC, ERD5, and ERD15
%disc was used simply to identify features to use for feedback.
%Within each condition there were 3 ISI's: 0, 3 (SICI) and 10 (ICF)
%Each RC session had ISIs 0 (test), 2, 3, 5, 10, 15. The best SICI (2,3,5)
%and ICF(10,15) were chosen for subsequent ERD5 and ERD15 runs.

% Subject metadata
ss = 0;

ss = ss+1;
subjects_info(ss).name = 'aoki';
subjects_info(ss).date = '110406';
subjects_info(ss).muscle = 'FCR';
subjects_info(ss).sici_isi = 3;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'CP3';
subjects_info(ss).fb_freq = 21;
subjects_info(ss).chad_task_freq = 31.5;
subjects_info(ss).chad_mep_freq = 19.5;

ss = ss+1;
subjects_info(ss).name = 'habagishi';
subjects_info(ss).date = '110330-2';
subjects_info(ss).muscle = 'FCR';
subjects_info(ss).sici_isi = 2;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'FC3';
subjects_info(ss).fb_freq = 11;
subjects_info(ss).chad_task_freq = 10.5;
subjects_info(ss).chad_mep_freq = 25.5;%+ve

ss = ss+1;
subjects_info(ss).name = 'ishikawa';
subjects_info(ss).date = '110307-1';
subjects_info(ss).muscle = 'ECR';
subjects_info(ss).sici_isi = 3;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'CP3';
subjects_info(ss).fb_freq = 8;
subjects_info(ss).chad_task_freq = 7.5;
subjects_info(ss).chad_mep_freq = 28.5;

ss = ss+1;
subjects_info(ss).name = 'k.nakamura';
subjects_info(ss).date = '110303-2';
subjects_info(ss).muscle = 'ECR';
subjects_info(ss).sici_isi = 3;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'FC3';
subjects_info(ss).fb_freq = 17;
subjects_info(ss).chad_task_freq = 7.5;%
subjects_info(ss).chad_mep_freq = 16.5;%+ve

ss = ss+1;
subjects_info(ss).name = 'kumakura';
subjects_info(ss).date = '110315';
subjects_info(ss).muscle = 'ECR';
subjects_info(ss).sici_isi = 3;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'FC3';
subjects_info(ss).fb_freq = 9;
subjects_info(ss).chad_task_freq = 16.5;
subjects_info(ss).chad_mep_freq = 7.5;%+ve

ss = ss+1;
subjects_info(ss).name = 'miyamoto';
subjects_info(ss).date = '110325-1';
subjects_info(ss).muscle = 'FCR';
subjects_info(ss).sici_isi = 3;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'CP3';
subjects_info(ss).fb_freq = 11;
subjects_info(ss).chad_task_freq = 10.5;%
subjects_info(ss).chad_mep_freq = 25.5;%

ss = ss+1;
subjects_info(ss).name = 'nagao';
subjects_info(ss).date = '110328-1';
subjects_info(ss).muscle = 'ECR';
subjects_info(ss).sici_isi = 3;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'C1';
subjects_info(ss).fb_freq = 13;
subjects_info(ss).chad_task_freq = 11.5;
subjects_info(ss).chad_mep_freq = 13.5;

ss = ss+1;
subjects_info(ss).name = 'nakayama';
subjects_info(ss).date = '110408-3';
subjects_info(ss).muscle = 'ECR';
subjects_info(ss).sici_isi = 3;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'CP3';
subjects_info(ss).fb_freq = 13;
subjects_info(ss).chad_task_freq = 13.5;
subjects_info(ss).chad_mep_freq = 16.5;

ss = ss+1;
subjects_info(ss).name = 'nobori';
subjects_info(ss).date = '110402';
subjects_info(ss).muscle = 'FCR';
subjects_info(ss).sici_isi = 3;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'C5';
subjects_info(ss).fb_freq = 8;
subjects_info(ss).chad_task_freq = 7.5;
subjects_info(ss).chad_mep_freq = 19.5;

ss = ss+1;
subjects_info(ss).name = 'ogasawara';
subjects_info(ss).date = '110307-2';
subjects_info(ss).muscle = 'ECR';
subjects_info(ss).sici_isi = 3;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'C5';
subjects_info(ss).fb_freq = 11;
subjects_info(ss).chad_task_freq = 10.5;
subjects_info(ss).chad_mep_freq = 31.5;

ss = ss+1;
subjects_info(ss).name = 'onose';
subjects_info(ss).date = '110330-1';
subjects_info(ss).muscle = 'FCR';
subjects_info(ss).sici_isi = 3;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'CP3';
subjects_info(ss).fb_freq = 18;
subjects_info(ss).chad_task_freq = 19.5;
subjects_info(ss).chad_mep_freq = 28.5;

% ss = ss+1;
% %RC excel file suggest 66 trials but dat files only have 37 trials.
% %Probably first 37
% subjects_info(ss).name = 's.kondo';
% subjects_info(ss).date = '110303-1';
% subjects_info(ss).muscle = 'FCR';
% subjects_info(ss).sici_isi = 3;
% subjects_info(ss).icf_isi = 10;
% subjects_info(ss).fb_ch_ref = 'FC3';
% subjects_info(ss).center_freq = 11;

% ss = ss+1;
% %RC dat files only have 66 of 81 trials. There seems to be a missing
% file.
% subjects_info(ss).name = 'shimizu';
% subjects_info(ss).date = '110325-2';
% subjects_info(ss).muscle = 'FCR';
% subjects_info(ss).sici_isi = 3;
% subjects_info(ss).icf_isi = 10;
% subjects_info(ss).fb_ch_ref = 'CP3';
% subjects_info(ss).center_freq = 9;

ss = ss+1;
subjects_info(ss).name = 'shiozaki';
subjects_info(ss).date = '110328-2';
subjects_info(ss).muscle = 'ECR';
subjects_info(ss).sici_isi = 3;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'CP3';
subjects_info(ss).fb_freq = 11;
subjects_info(ss).chad_task_freq = 7.5;
subjects_info(ss).chad_mep_freq = 19.5;%+ve
%Power changes and correlations with MEP size look great but reversed at
%freq=19

% ss = ss+1;
% %Is missing 5-1 file.
% subjects_info(ss).name = 'terasaki';
% subjects_info(ss).date = '110411-1';
% subjects_info(ss).muscle = 'FCR';
% subjects_info(ss).sici_isi = 2;
% subjects_info(ss).icf_isi = 15;
% subjects_info(ss).fb_ch_ref = 'CP3';
% subjects_info(ss).center_freq = 9;

ss = ss+1;
subjects_info(ss).name = 'tomiyama';
subjects_info(ss).date = '110401';
subjects_info(ss).muscle = 'FCR';
subjects_info(ss).sici_isi = 3;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'CP3';
subjects_info(ss).fb_freq = 9;
subjects_info(ss).chad_task_freq = 7.5;
subjects_info(ss).chad_mep_freq = 10.5;

ss = ss+1;
subjects_info(ss).name = 'umemoto';
subjects_info(ss).date = '110404-1';
subjects_info(ss).muscle = 'FCR';
subjects_info(ss).sici_isi = 3;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'CP3';
subjects_info(ss).fb_freq = 10;
subjects_info(ss).chad_task_freq = 10.5;
subjects_info(ss).chad_mep_freq = 7.5;

ss = ss+1;
subjects_info(ss).name = 'y.watanabe';
subjects_info(ss).date = '110411-2';
subjects_info(ss).muscle = 'FCR';
subjects_info(ss).sici_isi = 2;
subjects_info(ss).icf_isi = 15;
subjects_info(ss).fb_ch_ref = 'CP3';
subjects_info(ss).fb_freq = 11;
subjects_info(ss).chad_task_freq = 10.5;
subjects_info(ss).chad_mep_freq = 25.5;%+ve

% ss = ss+1;
% subjects_info(ss).name = 'yazaki';
% subjects_info(ss).date = '110218-2';
% subjects_info(ss).muscle = 'FCR';
% subjects_info(ss).sici_isi = 3;
% subjects_info(ss).icf_isi = 10;
% subjects_info(ss).fb_ch_ref = 'C5';
% subjects_info(ss).center_freq = 14;

ss = ss+1;
subjects_info(ss).name = 'yoshimizu';
subjects_info(ss).date = '110408-1';
subjects_info(ss).muscle = 'ECR';
subjects_info(ss).sici_isi = 3;
subjects_info(ss).icf_isi = 10;
subjects_info(ss).fb_ch_ref = 'CP3';
subjects_info(ss).fb_freq = 17;
subjects_info(ss).chad_task_freq = 34.5;
subjects_info(ss).chad_mep_freq = 13.5;

% Ignored because this subject has more channels and I don't know map.
% ss = ss+1;
% subjects_info(ss).name = 'zoushima';
% subjects_info(ss).date = '110426';
% subjects_info(ss).muscle = 'ECR';
% subjects_info(ss).sici_isi = 3;
% subjects_info(ss).icf_isi = 10;
% subjects_info(ss).fb_ch_ref = 'C1';
% subjects_info(ss).center_freq = 10;

clear ss