%Looks at MEP recruitment curves before and after an intervention.
%Before and after are separated by periods.

% PATHS
toolpath=pwd;
toolpath=toolpath(1:strfind(toolpath,'EERAT')+4);
toolpath=[toolpath,filesep,'core',filesep,'api',filesep,'matlab',filesep];
addpath(toolpath);
addpath([toolpath,'mym']);
clear toolpath

% DATABASE OBJECT
import EERAT.* %Object interfaces.
dbx=EERAT.Dbmym('eerat'); %Open a connection to the database.

experiment = EERAT.Experiment(dbx,'Name','Chad_MEP_RC');
subjects = experiment.subjects;

%Unfortunately, as with all experiments, there needs to be some manual
%selection of which data to include.
sub_meta(1).Name='KODAMA';
sub_meta(1).good_dates={'2012-05-25';'2012-06-01';'2012-06-08'};
sub_meta(1).condition={'A';'B';'C'};
sub_meta(2).Name='MOMOSE';
sub_meta(2).good_dates={'2012-05-17';'2012-05-24';'2012-05-31'};
sub_meta(2).condition={'A';'C';'B'};
sub_meta(3).Name='SUZUKI';
sub_meta(3).good_dates={'2012-05-10';'2012-05-17';'2012-05-24'};
sub_meta(3).condition={'A';'C';'B'};
sub_meta(4).Name='TSUCHI';
sub_meta(4).good_dates={'2012-05-25';'2012-06-01';'2012-06-11'};
sub_meta(4).condition={'A';'B';'C'};

%Feature type for mep_p2p
feature_type = EERAT.FeatureType(dbx,'Name','MEP_p2p');

for ss=1:length(subjects)
    sub = subjects(ss);
    this_sub_meta=sub_meta(strcmpi(sub.Name,{sub_meta.Name}));
    
    %Extract only the relevant periods, and indicate which period is which.
    pers=sub.periods;
    period_score = zeros(length(pers),1); %1=Apre, 2=Apost, 3=Bpre, 4=Bpost, 5=Cpre, 6=Cpost
    for pp=1:length(pers)
        this_per = pers(pp);
        this_datenum=floor(datenum(this_per.StartTime));
        this_dateix=find(datenum(this_sub_meta.good_dates)==this_datenum);
        if any(this_dateix) && strcmpi(this_per.datum_type.Name,'mep_io');
            if strcmpi(this_sub_meta.condition(this_dateix),'A')
                period_score(pp)=1;
            elseif strcmpi(this_sub_meta.condition(this_dateix),'B')
                period_score(pp)=3;
            elseif strcmpi(this_sub_meta.condition(this_dateix),'C')
                period_score(pp)=5;
            end
        end
        clear this_per this_datenum
    end
    clear pp
    pers=pers(period_score>0);
    period_score=period_score(period_score>0);
    for pp=2:length(period_score)
        if any(period_score(1:pp-1)==period_score(pp))
            period_score(pp)=period_score(pp)+1;
        end
    end
    
    %Get the good trials for each period, plot the MEP recruitment curve
    figure('Name',sub.Name);
    for pp=1:length(pers)
        %For some reason, my feature values got screwed up. I will recalculate them
        %here. This should only be needed once per subject.
%         for tt=1:length(pers(pp).trials)
%             result=calculate_feature(pers(pp).trials(tt),feature_type);
%         end
        x=pers(pp).get_trials_details('dat_TMS_powerA');
        x=str2double(x);
        y=pers(pp).get_trials_features('MEP_p2p');
        trial_bool=logical([pers(pp).trials.IsGood]);
        x=x(trial_bool);
        y=y(trial_bool);
        
%         beta0=[max(y) 1 (max(x)-min(x))/2 min(y)];
%         beta=nlinfit(x,y,@EERAT.Datum.sigmoid,beta0);
        beta0=[1 (max(x)-min(x))/2];
        mep_limit=str2double(pers(pp).details(strcmpi({pers(pp).details.Name},'dat_MEP_detection_limit')).Value);
        y=y>mep_limit;
        beta=nlinfit(x,y,@EERAT.Datum.sigmoid_simple,beta0);
            
        x_fit=linspace(min(x),max(x));
%         y_fit=EERAT.Datum.sigmoid(beta,x_fit);
        y_fit=EERAT.Datum.sigmoid_simple(beta,x_fit);
        
        subplot(3,1,ceil(period_score(pp)/2))
        if mod(period_score(pp)+1,2)==0
            color='b';
        else
            color='r';
        end
        scatter(x,y,color), hold on
        plot(x_fit,y_fit,color)
        
        if period_score(pp)==1 || period_score(pp)==2
            title('A - Imagery Only')
        elseif period_score(pp)==3 || period_score(pp)==4
            title('B - Real Feedback')
        elseif period_score(pp)==5 || period_score(pp)==6
            title('C - Fake Feedback')
        end
        
        xlabel('TMS STIMULATOR INTENSITY (% Max)')
        %ylabel('MEP P2P (uV)')
        ylabel('MEP DETECTED')
    end
    
    clear sub pers period_score
end