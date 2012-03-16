load('emg.mat');
createPrinCompFigure(ECOG_EMG(1).freqs,cat(3,ECOG_EMG.prinCompCoeff))

%Descriptive statistics.
temp=cat(3,ECOG_EMG.descriptives);%mean,std x features x anis
%features are 'mb_db';'g1_db';'g2_db';'stim';'BGE';'MW';'HR';'tod';'HRR'

%Diurnal from ECOG_EMG to sigmaplot
temp=cat(3,ECOG_EMG.diurnalz); %features x time_windows x animals
temp=permute(temp,[2 3 1]);
temp=reshape(temp,size(temp,1),[]);
sigmaplot.diurnal=temp; %BGE, MW, HR, mb_db, g1_db, g2_db
clear temp*

%RSq with BGE
temp=cat(1,ECOG_EMG.BGERSq); %n_anis x features (39 freqs,mb,g1,g2)
sigmaplot.rsq_spec_bge=[freqs temp(:,1:length(freqs))'];
sigmaplot.rsq_band_bge{1}=reshape(repmat({'mb','g1','g2'},size(temp,1),1),[],1);
sigmaplot.rsq_band_bge{2}=reshape(temp(:,length(freqs)+1:end),[],1);
clear temp*
%ECoG vs BGE Slope
temp=cat(3,ECOG_EMG.BGErealB); %features (39 freqs,mb,g1,g2) x coeffs x n_anis
temp=squeeze(temp(40:end,end,:)); %mb,g1,g2 x n_anis
sigmaplot.slope_band_bge=temp';

%RSq with HR and HRR
temp1=cat(1,ECOG_EMG.HRRSq);
temp2=cat(1,ECOG_EMG.HRRRSq);
sigmaplot.rsq_spec_hr_hrr=[freqs temp1(:,1:length(freqs))' temp2(:,1:length(freqs))'];
sigmaplot.rsq_band_hr_hrr{1}=reshape(repmat({'mb','g1','g2'},size(temp,1),1),[],1);
sigmaplot.rsq_band_hr_hrr{2}=[reshape(temp1(:,length(freqs)+1:end),[],1) reshape(temp2(:,length(freqs)+1:end),[],1)];
clear temp*
%ECoG vs HR and HRR Slope
temp1=cat(3,ECOG_EMG.HRrealB); %features (39 freqs,mb,g1,g2) x coeffs x n_anis
temp1=squeeze(temp1(40:end,end,:)); %mb,g1,g2 x n_anis
temp2=cat(3,ECOG_EMG.HRRrealB); %features (39 freqs,mb,g1,g2) x coeffs x n_anis
temp2=squeeze(temp2(40:end,end,:));
sigmaplot.slope_band_hr_hrr=[temp1' temp2'];

%Sample evoked EMG
temp_list=[11 22 30 34 38 41];
for aa=1:length(temp_list)
    figure;
    x=ECOG_EMG(temp_list(aa)).t_vec';
    for bb=1:3
        y=[ECOG_EMG(temp_list(aa)).lohi_evoked{bb,1}(:,1),ECOG_EMG(temp_list(aa)).lohi_evoked{bb,2}(:,1)];
        subplot(3,1,bb)
        plot(x,y)
        xlim([-5 15])
        ylim([min(min(y(x>3,:))) max(max(y(x>3,:)))])
        title(num2str(temp_list(aa)))
    end
%     w=waitforbuttonpress;
end
%? pick an animal.
clear x y

%Ecog on BGE vs HR
temp=cat(4,ECOG_EMG.bg_hr_lohi_b); %ecog_bands x lo_hi x int_slope x anis
temp=temp(:,2,:,:)-temp(:,1,:,:);
temp=squeeze(temp);
temp=permute(temp,[3,1,2]);
temp=reshape(temp,[],size(temp,3));
sigmaplot.delta_int_slope=temp;
temp=cat(3,ECOG_EMG.bg_hr_lohi_r); %ecog_bands, l0_hi, pearson's r
temp=permute(temp,[3 1 2]);
temp=reshape(temp,[],2);
sigmaplot.bg_hr_regress_lo_hi=temp; %This isn't graphed or reported. It's only meant to help identify an example animal.
clear temp*

%RSq across electrodes
multi_elec_bool=false(length(ECOG_EMG),1);
for aa=1:length(ECOG_EMG)
    multi_elec_bool(aa)=~isempty(ECOG_EMG(aa).other_HRRRSq);
end
% n_multi_elec=sum(multi_elec_bool);

temp1=cat(1,ECOG_EMG(multi_elec_bool).BGERSq); %n_anis x 39 freqs,mb,g1,g2
temp1=temp1(:,40:end);
temp2=NaN(size(temp1,1),size(temp1,2),2);
multi_ind=find(multi_elec_bool);
for aa=1:length(multi_ind)
    temp2(aa,:,:)=[ECOG_EMG(multi_ind(aa)).other_BGERSq(:,1) ECOG_EMG(multi_ind(aa)).other_BGERSq(:,end)];
end
temp=cat(3,temp1,temp2);
sigmaplot.multi_elec_bge_rsq=reshape(temp,[],size(temp,3));

temp1=cat(1,ECOG_EMG(multi_elec_bool).HRRRSq); %n_anis x 39 freqs,mb,g1,g2
temp1=temp1(:,40:end);
temp2=NaN(size(temp1,1),size(temp1,2),2);
multi_ind=find(multi_elec_bool);
for aa=1:length(multi_ind)
    temp2(aa,:,:)=[ECOG_EMG(multi_ind(aa)).other_HRRRSq(:,1) ECOG_EMG(multi_ind(aa)).other_HRRRSq(:,end)];
end
temp=cat(3,temp1,temp2);
sigmaplot.multi_elec_hrr_rsq=reshape(temp,[],size(temp,3));

sigmaplot.multi_elec_bge_hrr_stats=[reshape(sigmaplot.multi_elec_bge_rsq,[],1) reshape(sigmaplot.multi_elec_hrr_rsq,[],1)];

temp_anis=repmat((1:size(temp,1))',[1,size(temp,2),size(temp,3)]);
temp_elec_names={'C.SMC','C.Pst','I.SMC'};
temp_elec_names=repmat(shiftdim((temp_elec_names),-1),[size(temp,1),size(temp,2)]);
temp_band_names={'mb','g1','g2'};
temp_band_names=repmat(temp_band_names,[size(temp,1),1,size(temp,3)]);
sigmaplot.multi_elec_stats_labels=[num2cell(reshape(temp_anis,[],1)) reshape(temp_elec_names,[],1) reshape(temp_band_names,[],1)];
clear temp* multi* n_multi_elec