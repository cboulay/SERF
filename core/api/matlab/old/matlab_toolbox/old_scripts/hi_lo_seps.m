paths;
load('acute_ecog_sep_rsq');
experiment=E3.Experiment('ECoG Acute SEPs');
anis=experiment.Animals;
for aa=1:length(anis)
    ani=anis(aa);
    
    t_vec=ani.T_vec;
    t_vec=t_vec(t_vec>0);
    
    ads=ani.AnimalDetails;
    ad_names={ads.Name};
    be_id=str2double(ads(strcmpi(ad_names,'best_ecog_channel_id')).Value);
    base=[str2double(ads(strcmpi(ad_names,'sep_base_start_ms')).Value)...
        str2double(ads(strcmpi(ad_names,'sep_base_stop_ms')).Value)];
    peak_window=[str2double(ads(strcmpi(ad_names,'sep_p1_start_ms')).Value)...
        str2double(ads(strcmpi(ad_names,'sep_p1_stop_ms')).Value);...
        str2double(ads(strcmpi(ad_names,'sep_n1_start_ms')).Value)...
        str2double(ads(strcmpi(ad_names,'sep_n1_stop_ms')).Value);...
        str2double(ads(strcmpi(ad_names,'sep_n2_start_ms')).Value)...
        str2double(ads(strcmpi(ad_names,'sep_n2_stop_ms')).Value)];
    
    lo=ECOG_SEP_ACUTE(aa).lohi_evoked{1,1,1}(:,be_id);
    hi=ECOG_SEP_ACUTE(aa).lohi_evoked{1,1,2}(:,be_id);
    evoked=[lo hi];
    evoked=evoked-repmat(mean(evoked(t_vec>base(1) & t_vec<base(2),:)),length(t_vec),1); %subtract the baseline
    max_peak=max(abs(evoked(t_vec>6,1)));
    
    figure;
    plot(t_vec,evoked), hold on
    plot([base(1) base(1)],[-1*max_peak max_peak],'k--')
    plot([base(2) base(2)],[-1*max_peak max_peak],'k--')
    for pp=1:size(peak_window,1)
        if pp==1
            peak_amp=max(evoked(t_vec>=peak_window(pp,1) & t_vec<peak_window(pp,2),:));
        else
            peak_amp=min(evoked(t_vec>=peak_window(pp,1) & t_vec<peak_window(pp,2),:));
        end
        output.diff_peak(aa,pp)=100*(peak_amp(2)-peak_amp(1))/max_peak;
%         output.diff_peak(aa,pp)=100*abs(peak_amp(2)./abs(peak_amp(1));
        clear peak_amp
        plot([peak_window(pp,1) peak_window(pp,1)],[-1*max_peak max_peak],'r--');
        plot([peak_window(pp,2) peak_window(pp,2)],[-1*max_peak max_peak],'r--');
    end
    hold off
    
%     diff_evoked=100*(abs(evoked(:,2))-abs(evoked(:,1)))/max_peak;
    diff_evoked=100*(evoked(:,2)-evoked(:,1))/max_peak;
%     output.diff_n1(aa)=mean(diff_evoked(t_vec>=p1_stop & t_vec<30));
%     output.diff_n2(aa)=mean(diff_evoked(t_vec>=30 & t_vec<60));
    
    %Resample evoked so that each datapoint is exactly 3ms.
    ms_edges=-9:3:100;
    for ss=1:length(ms_edges)-1
        ms_bool=t_vec>=ms_edges(ss) & t_vec<ms_edges(ss+1);
        temp_diff_evoked(ss)=mean(diff_evoked(ms_bool));
    end
    output.diff_evoked(:,aa)=temp_diff_evoked;
    clear ms_edges ss ms_bool temp_diff_evoked
end
ms_t_vec=-9+1.5:3:100-1.5;
sigmaplot.diff_plot=[ms_t_vec' output.diff_evoked];
sigmaplot.diff_peaks=output.diff_peak';
ani_ids=(1:length(anis))';
sigmaplot.anova_peaks=[repmat(ani_ids,2,1) [zeros(length(ani_ids),1);ones(length(ani_ids),1)]...
    [zeros(length(ani_ids),3);output.diff_peak]];