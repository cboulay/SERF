channel_names = {'FC5','FC3','FC1','FCz','FC2','FC4','FC6','C5','C3','C1','Cz','C2','C4','C6','CP5','CP3','CP1','CPz','CP2','CP4','CP6','FP1','FPz','FP2','AF7','AF3','AFz','AF4','AF8','F7','F5','F3','F1','Fz','F2','F4','F6','F8','FT7','FT8','T7','T8','T9','T10','TP7','TP8','P7','P5','P3','P1','Pz','P2','P4','P6','P8','PO7','PO3','POz','PO4','PO8','O1','Oz','O2','Iz'};
load llpXform
spat_filt = eye(64);
for cc=1:64
    spat_filt(cc,llpXform(cc,:,1))=-0.25;
end
clear llpXform cc

%Subject specific information
clear subjects_info
ss=0;

ss=ss+1;
subjects_info(ss).name='bap';
subjects_info(ss).nScreen=4;
subjects_info(ss).nTrain=14;
subjects_info(ss).nTest=5;
subjects_info(ss).fb_freq=20;
subjects_info(ss).fb_chan={'C3.'};
subjects_info(ss).spat_filt=spat_filt;
subjects_info(ss).task_freqs=[11 21 25];
subjects_info(ss).rt_freqs=[11 23];
% subject(ss).test_channel=testch;
% subject(ss).betaFreq=20;
% subject(ss).muFreq=12;
% subject(ss).fileType=[false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true];

% ss=ss+1;
% subject(ss).name='bxb';
% subject(ss).nScreen=4;

ss=ss+1;
subjects_info(ss).name='mdp';
subjects_info(ss).nScreen=4;
subjects_info(ss).nTrain=4;
subjects_info(ss).nTest=5;
subjects_info(ss).fb_freq=[12 22];
subjects_info(ss).fb_chan={'C3.';'CP3'};
subjects_info(ss).spat_filt=spat_filt;
subjects_info(ss).task_freqs=[11 23];
subjects_info(ss).rt_freqs=[11 19 23];
% subject(ss).test_channel=testch;
% subject(ss).betaFreq=24;
% subject(ss).muFreq=12;
% subject(ss).fileType=[false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true];

% ss=ss+1;
% subject(ss).name='pct';
% subject(ss).nScreen=4;

ss=ss+1;
subjects_info(ss).name='rsm';
subjects_info(ss).nScreen=4;
subjects_info(ss).nTrain=13;
subjects_info(ss).nTest=5;
subjects_info(ss).fb_freq=22;
subjects_info(ss).fb_chan={'CP3'};
subjects_info(ss).spat_filt=spat_filt;
subjects_info(ss).task_freqs=[21 29];
subjects_info(ss).rt_freqs=[11 19];
% subject(ss).test_channel=testch;
% subject(ss).betaFreq=20;
% subject(ss).muFreq=12;
% subject(ss).fileType=[false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true];

ss=ss+1;
subjects_info(ss).name='wpm';
subjects_info(ss).nScreen=4;
subjects_info(ss).nTrain=10;
subjects_info(ss).nTest=5;
subjects_info(ss).fb_freq=[10 22];
subjects_info(ss).fb_chan={'CP3'};
subjects_info(ss).spat_filt=spat_filt;
subjects_info(ss).task_freqs=[11 21 33];
subjects_info(ss).rt_freqs=[15 27];
% subject(ss).test_channel=testch;
% subject(ss).betaFreq=28;
% subject(ss).muFreq=10;
% subject(ss).fileType=[false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true];

ss=ss+1;
subjects_info(ss).name='bxb';
subjects_info(ss).nScreen=4;
subjects_info(ss).nTrain=6;
subjects_info(ss).nTest=5;
subjects_info(ss).fb_freq=[10 23];
subjects_info(ss).fb_chan={'C3.'};
subjects_info(ss).spat_filt=spat_filt;
subjects_info(ss).task_freqs=[11 21];
subjects_info(ss).rt_freqs=[23];
% subject(ss).test_channel=testch;
% subject(ss).betaFreq=20;
% subject(ss).muFreq=10;
% subject(ss).fileType=[false(1,4*8) false(1,6*8) true(1,5*8)];

ss=ss+1;
subjects_info(ss).name='pct';
subjects_info(ss).nScreen=4;
subjects_info(ss).nTrain=9;
subjects_info(ss).nTest=5;
subjects_info(ss).fb_freq=23;
subjects_info(ss).fb_chan={'C1.'};
subjects_info(ss).spat_filt=spat_filt;
subjects_info(ss).task_freqs=25;
subjects_info(ss).rt_freqs=[11 19];
% subject(ss).test_channel=testch;
% subject(ss).betaFreq=20;
% subject(ss).muFreq=10;
% subject(ss).fileType=[false(1,4*8) false(1,9*8) true(1,5*8)];

% ss=ss+1;
% subjects_info(ss).name='sxk';
% subjects_info(ss).nScreen=0;
% subjects_info(ss).nTrain=2;
% subjects_info(ss).nTest=0;
% subjects_info(ss).fb_freq=23;
% subjects_info(ss).fb_chan={'C3.'};
% subjects_info(ss).spat_filt=spat_filt;
% subjects_info(ss).task_freqs=25;
% subjects_info(ss).rt_freqs=[11 19];