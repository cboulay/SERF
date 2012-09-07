%Modify parameters here.
clear all
sub_name = 'SUZUKI';
session_run = [ 
                1 5;
                1 6;
                2 5;
                2 6;
                3 4;
                3 5;
            ];
basedir = 'D:\data\bci2000\';
ctrl_freq = 9;
%/Modify


this_dir = pwd;
cd('D:\BCI2000\tools\matlab\');
bci2000path -AddToMatlabPath tools/mex     % binary mex-files (load_bcidat and friends)
bci2000path -AddToMatlabPath tools/matlab  % matlab m-files
bci2000path -AddToMatlabPath tools/OfflineAnalysis  % matlab m-files
bci2000path -AddToSystemPath tools/cmdline % binary executables (command-line utilities)
cd(this_dir);
chan_labels={'F3';'Fz';'F4';'T7';'C3';'Cz';'C4';'T8';'P7';'P3';'Pz';'P4';'P8';'O1';'Oz';'O2'};

file_base = [basedir,sub_name,filesep,sub_name];
filenames=cell(1,size(session_run,1));
for rr=1:length(session_run)
    sess=num2str(session_run(rr,1));
    while length(sess)<3
        sess = ['0',sess];
    end
    run=num2str(session_run(rr,2));
    if length(run)<2
        run=['0',run];
    end
    filenames{rr}=[file_base,sess,filesep,sub_name,'S',sess,'R',run,'.dat'];
end; clear rr filedir file_base sess run

ctrl_for_feedback = [];
for ff=1:length(filenames)
    s = bci2000chain(filenames{ff},...
        'TransmissionFilter|ARFilter|LPFilter|ExpressionFilter|Normalizer','-v',...
        'temp.prm','FirstBinCenter', ctrl_freq, 'LastBinCenter', ctrl_freq);
%     temp_sig = (-1/3)*s.Signal;
%     temp_sig = min([temp_sig,3.2768*ones(size(temp_sig))],[],2);
%     temp_sig = max([temp_sig,-3.2768*ones(size(temp_sig))],[],2);
%     temp_sig(temp_sig<0) = 6.5535 + temp_sig(temp_sig<0);
%     temp_sig = temp_sig*10000;
%     temp_sig = uint16(temp_sig);
%     scatter(s.States.Value,temp_sig);

    %Slice s.Signal to get feedback periods only.
    fb_on = find([0;diff(s.States.Feedback)>0]);
    fb_off = find([0;diff(s.States.Feedback)<0]);
    n_trials = length(fb_on);
    fb_sig = cell(n_trials,1);
    %If I could guarantee that n_samps_per_trial were always the same then
    %I could vectorize this to make it faster.
    for tt=1:n_trials
        fb_sig{tt} = s.Signal(fb_on(tt):fb_off(tt)-1)';
    end; clear tt
    ctrl_for_feedback = cat(1,ctrl_for_feedback,fb_sig);
    
    clear fb_on fb_off n_trials fb_sig
end; clear ff

%Extend each entry in ctrl_for_feedback so it has the max n_samples
n_samps = 0;
for tt=1:length(ctrl_for_feedback)
    n_samps = max(n_samps, length(ctrl_for_feedback{tt}));
end
for tt=1:length(ctrl_for_feedback)
    ctrl_for_feedback{tt} = [ctrl_for_feedback{tt} zeros(1,n_samps-length(ctrl_for_feedback{tt}))];
end

csvpath = [basedir,sub_name,filesep,'fake_control.csv'];
csvwrite(csvpath,cell2mat(ctrl_for_feedback));

% Filter( SpatialFilter, 2.B );
% Filter( ARFilter, 2.C );
% Filter( LinearClassifier, 2.D );
% Filter( LPFilter, 2.D1 );
% Filter( ExpressionFilter, 2.D2 );
% Filter( Normalizer, 2.E );
% Filtering  matrix  LinearClassifier= 1 4 1 6 1 1 % % %//Linear classification matrix in sparse representation