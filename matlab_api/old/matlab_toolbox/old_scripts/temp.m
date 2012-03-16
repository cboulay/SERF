load('acute_ecog_sep_rsq.mat');
paths;
experiment=E3.Experiment('ECoG Acute SEPs');
anis=experiment.Animals;

%diurnal is sep features x time window
%lohi is sep features x ecog features x lo/hi
%lohi_evoked is {sep features x ecog features x lo/hi}
%RSq is sep features x ecog features
%simRSq is features x n_permutations x ecog_features
%realP is features x ecog features
%realB is features x ecog features x predictors ([ones controlX])
ax=0; clear temp temp_name
for aa=1:length(anis)
    if ~isempty(ECOG_SEP_ACUTE(aa).other_seps)
        ax=ax+1;
        ani=anis(aa);
        temp_csmc=mean(ECOG_SEP_ACUTE(aa).main_seps(:,6));
        temp_others=squeeze(mean(ECOG_SEP_ACUTE(aa).other_seps(:,1,:)));
        temp_others(:,any(temp_others==0))=[];
        temp(:,ax,:)=cat(1,temp_csmc,temp_others(1),temp_others(end));
        temp_name{ax}=ani.Name;
    end
end
ani_id=reshape(repmat(1:ax,3,1),[],1);
chan_id=repmat([1;2;3],18,1);
temp2=[ani_id chan_id reshape(temp,[],1)];

%??
for aa=1:ax
    ani_id=repmat(aa,3,1);
    chan_id=repmat([1;2;3],3,1);
    temp2=[temp2;[ani_id chan_id reshape(squeeze(temp(1,:,:,aa)),[],1) reshape(squeeze(temp(2,:,:,aa)),[],1)]];
end

temp=cat(3,ECOG_SEP_ACUTE.RSq);
temp=permute(temp,[3 2 1]);
temp=reshape(temp,[],2);
%I used eeg-emg-36 for g1 effect on SEP plots
ani_list=[13 17 20];
for aa=1:length(ani_list)
    ani=anis(ani_list(aa));
    t_vec=ani.T_vec;
    temp=ECOG_SEP_ACUTE(ani_list(aa));
    nchans=size(temp.lohi_evoked{1,1,1},2);
    
    figure;
    x=t_vec(t_vec>0)';
    for bb=1:3
        for cc=1:nchans
            y1=temp.lohi_evoked{1,bb,1}(:,cc);
            y2=temp.lohi_evoked{1,bb,2}(:,cc);
            subplot(3,nchans,(bb-1)*nchans+cc)
            plot(x,[y1 y2])
            axis tight
            if cc==1
                xlim([0 15])
            else
                xlim([0 100])
            end
            ylim([min(min([y1(x>3) y2(x>3)])) max(max([y1(x>3) y2(x>3)]))])
        end
    end
    title(ani.Name);
end