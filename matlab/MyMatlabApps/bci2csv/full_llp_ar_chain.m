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
end; clear rr filedir file_base basedir sess run

SIG = [];
TARG = [];
for ff=1:length(filenames)
% #include "SpatialFilter.h"
% #include "ARFilter.h"
% #include "LinearClassifier.h"
% #include "LPFilter.h"
% #include "ExpressionFilter.h"
% #include "Normalizer.h"

    if 1==1
%         s = bci2000chain(filenames{ff},...
%             'TransmissionFilter|ARFilter|LinearClassifier|LPFilter|ExpressionFilter','-v',...
%             'full_llp_ar_parameters.prm');
        s = bci2000chain(filenames{ff},'ARSignalProcessing','full_llp_ar_parameters.prm');
%         s = bci2000chain(filenames{ff},'ARSignalProcessing','-v','full_car_ar_parameters.prm');
        n_samps = length(s.Time);
        n_chans = length(s.Parms.SpatialFilter.RowLabels);
        s.Signal = reshape(s.Signal,n_samps,[],n_chans);
        s.Signal = permute(s.Signal,[1 3 2]);
        f_vec = 0:2:40;
    else %Use this if we don't want adaptive normalization.
        s = bci2000chain(filenames{ff},...
            'TransmissionFilter|ARFilter','-v',...
            'full_llp_ar_parameters.prm');
        f_vec = s.ElementValues;
    end
    fb_bool = s.States.Feedback>0;
    sig = s.Signal(fb_bool,:,:);
    targ_codes = s.States.TargetCode(fb_bool);
    trial_codes = s.States.CurrentTrial(fb_bool);
    
    [~,n_chans,n_freqs]=size(sig);
    t_ix = unique(trial_codes);
    sig_out = NaN(n_chans,n_freqs,length(t_ix)); clear n_chans n_freqs
    targ_out = NaN(1,length(t_ix));
    for tt=1:length(t_ix)
        sig_out(:,:,tt)=squeeze(mean(sig(trial_codes==tt,:,:)));
        targ_out(tt)=mean(targ_codes(trial_codes==tt));
    end
    SIG = cat(3,SIG,sig_out);
    TARG = cat(2,TARG,targ_out);
    clear sig_out targ_out t_ix tt sig trial_codes fb_bool
end; clear ff s

[n_chans,n_freqs,n_trials]=size(SIG);
relax_bool = TARG == 1;

figure;
[ressq, amp1, amp2] = calc_rsqu(SIG(:,:,relax_bool), SIG(:,:,~relax_bool), 1);
%pow_db = 10*log10(SIG.^2);
avg_pow = cat(3,amp1,amp2);

for cc=1:n_chans
    subplot(4,4,cc)
    ha = plotyy(f_vec,squeeze(avg_pow(cc,:,:)),f_vec,ressq(cc,:));
    set(ha(2),'ylim',[0 max(max(ressq))])
    title(chan_labels(cc));
end
% temp = squeeze(SIG(5,6,:));
% figure;hist(temp)
% test_chans = [5 6 10 11];
% for cc=1:length(test_chans)
%     subplot(2,2,cc)
%     ha = plotyy(f_vec,squeeze(avg_pow(test_chans(cc),:,:)),f_vec,ressq(test_chans(cc),:));
%     set(ha(2),'ylim',[0 max(max(ressq(test_chans,:)))])
%     title(chan_labels(test_chans(cc)));
% end
% 
% for ff=[10 12 14 20 22 24]
%     figure;
%     for cc=1:length(test_chans)
%         [n1,x1]=hist(squeeze(SIG(test_chans(cc),f_vec==ff,relax_bool)));
%         [n2,x2]=hist(squeeze(SIG(test_chans(cc),f_vec==ff,~relax_bool)));
%         subplot(2,2,cc)
%         plot(x1,n1./sum(relax_bool),x2,n2./sum(~relax_bool))
%         title([num2str(ff),' ',chan_labels(test_chans(cc))])
%     end
% end