classdef Subject < E3.Named_db_object
    properties (Dependent = true)
        Gender
        Strain
        Weight
        CheckBG
        Notes
        %The following object arrays are stored in their own dbs and do not
        %need setters.
        %The getters will have access to these object arrays as soon as
        %they are created.
        SubjectDetails
        Channels
        Fragments
        TrialCriteria
    end
    properties (Dependent = true, Hidden = true)
        E3Name
        DataTableName
        LogTableName
        %The following are hidden because their getters are too slow for
        %when the subject properties are viewed from the command line.
        Trials
        Days
        Periods
        T_vec
        Day_vec
        Freqs
    end
    properties (Transient = true, Hidden=true, Constant = true)
        table_name = 'subject';
    end
    methods (Static = true)
        function array=get_obj_array
            array=get_obj_array@E3.Named_db_object('Subject');
        end
    end
    methods
        function obj=Subject(name)
            if nargin>0
                obj.Name=name;
            end
        end %Constructor
        
        %!--- Getters and setters
        function gender=get.Gender(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT Gender FROM `e3analysis`.`subject` WHERE id={Si}',obj.DB_id);
            %mym(cid,'close');
            if ~isempty(mo.Gender)
                gender=mo.Gender{1};
            else
                gender=[];
            end
        end
        function set.Gender(obj,gender)
            if ~any(strcmpi([{'male'},{'female'}],gender))
                gender='male';
            end
            if ~isempty(obj.DB_id)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                mym(cid,'UPDATE `e3analysis`.`subject` SET Gender="{S}" WHERE id={Si}',gender,obj.DB_id);
                %mym(cid,'close');
            end
        end
        function strain=get.Strain(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT Strain FROM `e3analysis`.`subject` WHERE id={Si}',obj.DB_id);
            %mym(cid,'close');
            if ~isempty(mo.Strain)
                strain=mo.Strain{1};
            else
                strain=[];
            end
        end
        function set.Strain(obj,strain)
            if ~isempty(obj.DB_id) && ~isempty(strain)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                mym(cid,'UPDATE `e3analysis`.`subject` SET Strain="{S}" WHERE id={Si}',strain,obj.DB_id);
                %mym(cid,'close');
            end
        end
        function weight=get.Weight(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT Weight FROM `e3analysis`.`subject` WHERE id={Si}',obj.DB_id);
            %mym(cid,'close');
            if ~isempty(mo.Weight)
                weight=mo.Weight(1);
            else
                weight=[];
            end
        end
        function set.Weight(obj,weight)
            if ~isempty(obj.DB_id) && ~isempty(weight)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                mym(cid,'UPDATE `e3analysis`.`subject` SET Weight="{S}" WHERE id={Si}',weight,obj.DB_id);
                %mym(cid,'close');
            end
        end
        function notes=get.Notes(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT CAST(Notes AS CHAR) as Notes FROM `e3analysis`.`subject` WHERE id={Si}',obj.DB_id);
            %mym(cid,'close');
            if ~isempty(mo.Notes)
                notes=mo.Notes{1};
            else
                notes=[];
            end
        end
        function set.Notes(obj,notes)
            if ~isempty(obj.DB_id) && ~isempty(notes)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end %#ok<*TLEV>
                mym(cid,'UPDATE `e3analysis`.`subject` SET Notes="{S}" WHERE id={Si}',notes,obj.DB_id);
                %mym(cid,'close');
            end
        end
        function e3name=get.E3Name(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT E3Name FROM `e3analysis`.`subject` WHERE id={Si}',obj.DB_id);
            %mym(cid,'close');
            if ~isempty(mo.E3Name)
                e3name=mo.E3Name{1};
            else
                e3name=[];
            end
        end
        function set.E3Name(obj,e3name)
            if ~isempty(obj.DB_id) && ~isempty(e3name)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                mym(cid,'UPDATE `e3analysis`.`subject` SET E3Name="{S}" WHERE id={Si}',e3name,obj.DB_id);
                %mym(cid,'close');
            end
        end
        function datatablename=get.DataTableName(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT DataTableName FROM `e3analysis`.`subject` WHERE id={Si}',obj.DB_id);
            if ~isempty(mo.DataTableName) && ~isempty(mo.DataTableName{1})
                datatablename=mo.DataTableName{1};
            elseif ~isempty(obj.E3Name)
                mo=mym(cid,'SHOW TABLES from `{S}`',obj.E3Name);
                fnames=fieldnames(mo);
                tnames=mo.(fnames{1});
                isdata=false(length(tnames),1);
                for tt=1:length(tnames)
                    isdata(tt)=any(strfind(tnames{tt},'data'));
                end
                datatablename=tnames{isdata};
                obj.DataTableName=datatablename;
            else
                datatablename=[];
            end
            %mym(cid,'close');
        end
        function set.DataTableName(obj,datatablename)
            if ~isempty(obj.DB_id) && ~isempty(datatablename)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                mym(cid,'UPDATE `e3analysis`.`subject` SET DataTableName="{S}" WHERE id={Si}',datatablename,obj.DB_id);
                %mym(cid,'close');
            end
        end
        function logtablename=get.LogTableName(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT LogTableName FROM `e3analysis`.`subject` WHERE id={Si}',obj.DB_id);
            if ~isempty(mo.LogTableName) && ~isempty(mo.LogTableName{1})
                logtablename=mo.LogTableName{1};
            elseif ~isempty(obj.E3Name)
                mo=mym(cid,'SHOW TABLES from `{S}`',obj.E3Name);
                fnames=fieldnames(mo);
                tnames=mo.(fnames{1});
                islog=false(length(tnames),1);
                for tt=1:length(tnames)
                    islog(tt)=any(strfind(tnames{tt},'log'));
                end
                logtablename=tnames{islog};
                obj.LogTableName=logtablename;
            else
                logtablename=[];
            end
            %mym(cid,'close');
        end
        function set.LogTableName(obj,logtablename)
            if ~isempty(obj.DB_id) && ~isempty(logtablename)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                mym(cid,'UPDATE `e3analysis`.`subject` SET LogTableName="{S}" WHERE id={Si}',logtablename,obj.DB_id);
                %mym(cid,'close');
            end
        end
        function checkbg=get.CheckBG(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT CheckBG FROM `e3analysis`.`subject` WHERE id={Si}',obj.DB_id);
            if ~isempty(mo.CheckBG) && ~isnan(mo.CheckBG)
                checkbg=mo.CheckBG(1);
            elseif (isempty(mo.CheckBG) || isnan(mo.CheckBG)) && ~isempty(obj.E3Name)
                ss='SELECT text as text FROM `{S}`.`{S}` WHERE seq=0 AND type=8 AND fragment=0 ORDER BY trial DESC limit 1';
                mo=mym(cid,ss,obj.E3Name,obj.LogTableName);
                text=char(mo.text{1}');
                checkbg=regexpi(text,'(?<=CheckBackground= )\d*','match');
                checkbg=str2num(checkbg{1});
                obj.CheckBG=checkbg;
            else
                checkbg=[];
            end
            %mym(cid,'close');
        end
        function set.CheckBG(obj,checkbg)
            if ~isempty(obj.DB_id) && ~isempty(checkbg)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                mym(cid,'UPDATE `e3analysis`.`subject` SET CheckBG="{S}" WHERE id={Si}',checkbg,obj.DB_id);
                %mym(cid,'close');
            end
        end
        function t_vec=get.T_vec(obj)
            frags=obj.Fragments;
            nsamps=[frags.NSamples];
            fs=[frags.Fs];
            t_vec=cell(1,length(frags));
            for ff=1:length(frags)
                switch frags(ff).Number
                    case 1
                        t_vec{frags(ff).Number}=(-1*nsamps(ff)+1)/fs(ff):1/fs(ff):0;
                    case 2
                        t_vec{frags(ff).Number}=1/fs(ff):1/fs(ff):nsamps(ff)/fs(ff);
                    case 3
                        last=nsamps(2)/fs(2);
                        t_vec{frags(ff).Number}=last+1/fs(ff):1/fs(ff):last+nsamps(ff)/fs(ff);
                end
            end
            t_vec=cell2mat(t_vec);
            t_vec=t_vec.*1000;
        end
        function day_vec=get.Day_vec(obj)
            %if we have ad for conditioning onset.
            ads=obj.SubjectDetails;
            co_bool=strcmpi({ads.Name},'cond_onset_date');
            if any(co_bool)
                co_ad=ads(co_bool);
                day_dates={obj.Days.Date};
                day_datenums=datenum(day_dates);
                day_vec=day_datenums-datenum(co_ad.Value)+1;
            else
                day_vec=1:length(ani.Days);
            end
        end
        function freqs=get.Freqs(obj)
            trial=E3.Trial;
            trial.subject_id=obj.DB_id;
            trial.Number=1;
            params=[25, 3, 197, 5, 10, 0, NaN];
            params(end)=obj.Fragments(1).Fs;
            [temp_pow,freqs]=mem(trial.Evoked,params); %#ok<ASGLU>
        end
        
        %Object arrays
        function chans=get.Channels(obj)
            chans=E3.Channel.get_property_array_for_subject(obj);
            if isempty(chans) && ~isempty(obj.E3Name)
                nChannels=obj.Fragments(1).NChannels;
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                ss='SELECT text as text FROM `{S}`.`{S}` WHERE seq=0 AND type=8 AND fragment=0 ORDER BY trial DESC limit 1';
                mo=mym(cid,ss,obj.E3Name,obj.LogTableName);
                %mym(cid,'close');
                
                text=char(mo.text{1}');
                
                HRPeriod=regexpi(text,'(?<=HRPeriod= )[\d*\.*\d* ]*','match');
                HRPeriod=str2num(HRPeriod{1});
                HRPeriod=HRPeriod(3:2+nChannels*2);
                HRPeriod=reshape(HRPeriod',2,nChannels)';
                
                MRPeriod=regexpi(text,'(?<=MRPeriod= )[\d*\.*\d* ]*','match');
                MRPeriod=str2num(MRPeriod{1});
                MRPeriod=MRPeriod(3:2+nChannels*2);
                MRPeriod=reshape(MRPeriod',2,nChannels)';
                
                chansRectified=regexpi(text,'(?<=ChannelsRectified= )[\d* ]*','match');
                chansRectified=str2num(chansRectified{1});
                chansRectified=chansRectified(2:nChannels+1);
                chansRectified=logical(chansRectified);
                
                rewCriteria=regexpi(text,'(?<=RewardCriteria= )[-*\d*\.*\d* ]*','match');
                rewCriteria=str2num(rewCriteria{1});
                rewCriteria=rewCriteria(3:2+nChannels*2);
                rewCriteria=reshape(rewCriteria',2,nChannels)';
                
                k=strfind(text,'InputRange');
                if size(k)>0
                    l=strfind(text(k:k+30),' ');
                    Range=strfind(text(k+l(1):k+l(2)-1));
                else
                    Range=5;
                end
                
                chan_array(nChannels)=E3.Channel;
                for cc=1:nChannels
                    chan_array(cc).subject_id=obj.DB_id;
                    chan_array(cc).Number=cc;
                    chan_array(cc).IsRectified=chansRectified(cc);
                    chan_array(cc).ADRange=Range;
                    chan_array(cc).MRStartms=MRPeriod(cc,1);
                    chan_array(cc).MRStopms=MRPeriod(cc,2);
                    chan_array(cc).HRStartms=HRPeriod(cc,1);
                    chan_array(cc).HRStopms=HRPeriod(cc,2);
                    chan_array(cc).RewardLow=rewCriteria(cc,1);
                    chan_array(cc).RewardHigh=rewCriteria(cc,2);
                end
                chans=chan_array;
            end
        end
        function frags=get.Fragments(obj)
            frags=E3.Fragment.get_property_array_for_subject(obj);
            if isempty(frags) && ~isempty(obj.E3Name)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                ss='SELECT text as text FROM `{S}`.`{S}` WHERE seq=0 AND type=4 AND fragment=0 AND trial=0';
                mo=mym(cid,ss,obj.E3Name,obj.LogTableName);
                %mym(cid,'close');
                text=char(mo.text{1}');
                %seqInfo int nFrags= 3 --> use lookbehind before finding
                %digit(s)
                nFrags=regexpi(text,'(?<=seqInfo int nFrags= )\d*','match');
                nFrags=str2num(nFrags{1}); %#ok<*ST2NM>
                nChannels=regexpi(text,'(?<=seqInfo int nChannels= )\d*','match');
                nChannels=str2num(nChannels{1});
                freqs=regexpi(text,'(?<=seqInfo floatlist freqs=\s)(?:\d*+\.*+\d* ){4,}','match');
                freqs=str2num(freqs{1});
                freqs=freqs(2:end);
                nSamples=regexpi(text,'(?<=seqInfo intlist nSamples=\s)(?:\d* ){4,}','match');
                nSamples=str2num(nSamples{1});
                nSamples=nSamples(2:end);
                frag_array(nFrags)=E3.Fragment;
                for ff=1:nFrags
                    frag_array(ff).subject_id=obj.DB_id;
                    frag_array(ff).Number=ff;
                    frag_array(ff).Fs=freqs(ff);
                    frag_array(ff).NSamples=nSamples(ff);
                    frag_array(ff).NChannels=nChannels;
                end
                frags=frag_array;
            end
        end
        
        function trials=get.Trials(obj)
            trials=E3.Trial.get_property_array_for_subject(obj);
        end
        function days=get.Days(obj)
            days=E3.Day.get_property_array_for_subject(obj);
        end
        function periods=get.Periods(obj)
            periods=E3.Period.get_property_array_for_subject(obj);
        end
        
        function crits=get.TrialCriteria(obj)
            crits=E3.Trial_criterion.get_criteria_for_ani(obj);
        end
        function ads=get.SubjectDetails(obj)
            ads=E3.Subject_detail.get_property_array_for_subject(obj);
        end
        
        %!--- Custom delete function
        function remove_from_db(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            for oo=1:length(obj)
                this_obj=obj(oo);
                mym(cid,'DELETE FROM `e3analysis`.`subject` WHERE id={Si}',this_obj.DB_id);
            end
            %mym(cid,'close');
        end %Delete the subject from the database (and cascade).
        
        %!--- Helper functions exclusive to subjects.
        function triage_trials(obj)
            %Prepare the MySQL statements.
            s1='UPDATE `e3analysis`.`trial` SET IsGood=1 WHERE subject_id={Si}';        
            s2=['UPDATE `e3analysis`.`trial` as et, `e3analysis`.`trial_feature_value` as etfv SET et.IsGood=0',...
                ' WHERE et.subject_id=etfv.subject_id AND et.Number=etfv.Number',...
                ' AND etfv.subject_id={Si} AND etfv.feature_type_id={Si} AND etfv.Value {S} {S4}'];
            s3=['UPDATE `e3analysis`.`trial` as et, `e3analysis`.`trial_feature_value` as etfvls',...
                ', `e3analysis`.`trial_feature_value` as etfvrs SET et.IsGood=0',...
                ' WHERE et.subject_id=etfvls.subject_id AND et.Number=etfvls.Number',...
                ' AND etfvls.subject_id={Si} AND etfvls.feature_type_id={Si} AND etfvls.Value {S} etfvrs.Value',...
                ' AND etfvrs.subject_id=etfvls.subject_id AND etfvrs.feature_type_id={Si} AND etfvrs.Number=etfvls.Number'];
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            for oo=1:length(obj)
                ani=obj(oo);
                mym(cid,s1,ani.DB_id);
                %For each criterion
%                 trials=ani.Trials;
                for cc=1:length(ani.TrialCriteria)
                    crit=ani.TrialCriteria(cc);
%                     lsft=E3.Feature_type;
%                     lsft.DB_id=crit.ls_feature_type_id;
%                     ls_vals=trials.get_feature_value_for_ft(lsft); %#ok<NASGU> %To make sure the feature has been calculated.
                    %Are two features required?
                    if ~isempty(crit.rs_feature_type_id) && ~isnan(crit.rs_feature_type_id)
%                         rsft=E3.Feature_type;
%                         rsft.DB_id=crit.rs_feature_type_id;
%                         rs_vals=trials.get_feature_value_for_ft(rsft); %#ok<NASGU> %To make sure the feature has been calculated.
                        mym(cid,s3,ani.DB_id,crit.ls_feature_type_id,crit.Comparison_operator,crit.rs_feature_type_id);
                    else
                        mym(cid,s2,ani.DB_id,crit.ls_feature_type_id,crit.Comparison_operator,crit.Rs_value);
                    end
                end
            end
            %mym(cid,'close');
        end%Set IsGood=false for trials that meet exclusion criteria.
        
        function triage_days(obj)
            for aa=1:length(obj)
                ani=obj(aa);
                n_chans=length(ani.Channels);
                days=ani.Days;
                n_days=length(days);
                t_vec=ani.T_vec;
                %I'm not proud of this hack, but I need to avoid evoked for
                %intermittent subjects.
                if ~strcmpi(ani.Name(end),'i')
                    evoked=cat(3,days.Evoked);
                end
                freqs=obj.Freqs;
                spectra=cat(3,days.Spectrum);
                day_vec=ani.Day_vec;
                day_vec=1:n_days;
                button=0;
                f1=figure('Position',[100 100 1200 700]);
                while button~=3
                    days_isgood=[days.IsGood];
                    if ~strcmpi(ani.Name(end),'i')
                        tmp_evoked=evoked;
                        tmp_evoked(:,:,~days_isgood)=NaN;
                        plotLims=nanmax(nanmax(abs(tmp_evoked(t_vec>2,:,days_isgood))),[],3);
                    end
                    tmp_spectra=spectra;
                    tmp_spectra(:,:,~days_isgood)=NaN;
                    
                    for cc=1:n_chans
                        figure(f1)
                        if ~strcmpi(ani.Name(end),'i')
                            subplot(2,n_chans,cc),
                            if cc==1
                                imagesc(day_vec,t_vec(t_vec>=-5 & t_vec<=15),squeeze(tmp_evoked(t_vec>=-5 & t_vec<=15,cc,:)))
                            else
                                imagesc(day_vec,t_vec(t_vec>=-10 & t_vec<=100),squeeze(tmp_evoked(t_vec>=-10 & t_vec<=100,cc,:)))
                            end
                            axis xy
                            if ani.Channels(cc).IsRectified
                                caxis([0 plotLims(cc)])
                                title(ani.Name)
                            else
                                caxis([-1*plotLims(cc) plotLims(cc)])
                            end
                        end
                        figure(f1)
                        subplot(2,n_chans,n_chans+cc)
                        imagesc(day_vec,freqs,squeeze(tmp_spectra(:,cc,:)))
                        axis xy
                        if cc==1
                            title('Left click on a day to toggle, Right click when done')
                        end
                    end
                    [x,~,button] = ginput(1);
                    if button==1 && x<n_days+1
                        x=round(x);
                        if x<day_vec(1)
                            x=day_vec(1);
                        elseif x>day_vec(end)
                            x=day_vec(end);
                        end
                        x=find(day_vec==x);
                        days(x).IsGood=~days_isgood(x);
                    end
                end
                close(f1);
            end
        end
        
        function show_periods(obj)
            for aa=1:length(obj)
                ani=obj(aa);
                periods=ani.Periods;
%                 n_periods=length(periods);
                t_vec=ani.T_vec;
                evoked=cat(3,periods.Evoked);
                freqs=obj.Freqs;
                spectra=cat(3,periods.Spectrum);
                figure('Position',[100 100 1200 700]);
                n_channels=size(spectra,2);
                ylim_evoked=cat(1,squeeze(min(min(evoked(t_vec>3,:,:),[],3))),squeeze(max(max(evoked(t_vec>3,:,:),[],3))));
                ylim_spec=[min(min(min(spectra))) max(max(max(spectra)))];
                for cc=1:n_channels
                    subplot(2,n_channels,cc)
                    plot(t_vec,squeeze(evoked(:,cc,:)))
                    axis tight
                    if cc==1
                        xlim([-5 15])
                    else
                        xlim([-10 100])
                    end
                    ylim(ylim_evoked(:,cc))
                    xlabel('TIME TO STIM (ms)')
                    ylabel('AVG AMPLITUDE (uV)')
                    subplot(2,n_channels,n_channels+cc)
                    plot(freqs,squeeze(spectra(:,cc,:)))
                    axis tight
                    ylim(ylim_spec)
                    xlabel('FREQUENCY (Hz)')
                    ylabel('POWER (dB)')
                    legend({periods.Name});
                end
            end
        end
        
        function clear_calculated(obj)
            %This function clears calculated feature values, and calculated
            %evoked and spectra for days and periods for this subject.
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            s{1}='DELETE FROM `e3analysis`.`period_feature_value` WHERE subject_id={Si}';
            s{2}='DELETE FROM `e3analysis`.`day_feature_value` WHERE subject_id={Si}';
            s{3}='DELETE FROM `e3analysis`.`trial_feature_value` WHERE subject_id={Si}';
            s{4}='UPDATE `e3analysis`.`period` SET Evoked="",Spectrum="",IsGood=1 WHERE subject_id={Si}';
            s{5}='UPDATE `e3analysis`.`day` SET Evoked="",Spectrum="",IsGood=1 WHERE subject_id={Si}';
            s{6}='UPDATE `e3analysis`.`trial` SET IsGood=1 WHERE subject_id={Si}';
            for aa=1:length(obj)
                ani=obj(aa);
                for ss=1:length(s)
                    mym(cid,s{ss},ani.DB_id);
                end
            end
            %mym(cid,'close');
        end
        
        function calc_evoked_spec_for_days_pers(ani)
            %function calc_evoked_spec_for_days_pers(ani)
            %The purpose of this function is to calculate and store to db
            %the evoked potentials and the spectra from each day and
            %period, and to minimize the calls to mem in doing so.
            
            %Prepare variables needed for get_evoked
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            frags=[ani.Fragments];
            chans=[ani.Channels];
            frag_ids=[1 2 3];
            samps=[frags.NSamples];
            var_args={'cid',cid,'dbname',ani.E3Name,'tablename',ani.DataTableName,'samps',samps,...
                'frag_ids',frag_ids,'conv',[chans.ad2uv],'checkbg',ani.CheckBG,'freqs',[frags.Fs],'rectified',[]};
            
            %Get days and periods
            days=ani.Days;
            periods=ani.Periods;
            per_limits=[datenum({periods.StartTime}) datenum({periods.EndTime})];
            
            %Create zero-evoked, zero-spectra and counters for periods
            p_trials=periods(1).get_trials(true);
            tmp_evoked=p_trials(1).Evoked;
            [n_samps,n_chans]=size(tmp_evoked);
            periods_evoked=zeros(n_samps,n_chans,length(periods));
            tmp_spectrum=p_trials(1).Spectrum;
            n_freqs=size(tmp_spectrum,1);
            periods_spectra=zeros(n_freqs,n_chans,length(periods));
            n_evoked_so_far=zeros(length(periods),1);
            n_spectrum_so_far=zeros(length(periods),1);
            
            %day-by-day, get trials, get evoked for trials, get spectra for
            %trials
            for dd=1:length(days)
                day_start=datenum(days(dd).Date)+13/24;
                d_per_bool=day_start>=per_limits(:,1) & day_start<(per_limits(:,2));
                
                d_trials=days(dd).get_trials(true);
                if ~isempty(d_trials)
                    if ~strcmpi(ani.Name(end),'i')
                        tmp_evoked=d_trials.get_evoked(var_args);
                        days(dd).Evoked=mean(tmp_evoked,3);
                        nanbool=squeeze(any(any(isnan(tmp_evoked))));
                        if sum(~nanbool)>0 && any(d_per_bool)
                            periods_evoked(:,:,d_per_bool)=periods_evoked(:,:,d_per_bool)+sum(tmp_evoked(:,:,~nanbool),3);
                            n_evoked_so_far(d_per_bool)=n_evoked_so_far(d_per_bool)+sum(~nanbool);
                        end
                    end
                    tmp_spectra=d_trials.get_spectrum([]);
                    days(dd).Spectrum=mean(tmp_spectra,3);
                    nanbool=squeeze(any(any(isnan(tmp_spectra))));
                    if sum(~nanbool)>0 && any(d_per_bool)
                        periods_spectra(:,:,d_per_bool)=periods_spectra(:,:,d_per_bool)+sum(tmp_spectra(:,:,~nanbool),3);
                        n_spectrum_so_far(d_per_bool)=n_spectrum_so_far(d_per_bool)+sum(~nanbool);
                    end
                else
                    days(dd).Evoked=NaN(n_samps,n_chans);
                    days(dd).Spectrum=NaN(n_freqs,n_chans);
                end
            end
            for pp=1:2
                if ~strcmpi(ani.Name(end),'i')
                    periods(pp).Evoked=periods_evoked(:,:,pp)./n_evoked_so_far(pp);
                end
                periods(pp).Spectrum=periods_spectra(:,:,pp)./n_spectrum_so_far(pp);
            end
        end
    end
end