classdef Trial < E3.Datum
    properties (Dependent = true)
        Number
        Time
        TimeOfDay
    end
    properties (Constant = true, Hidden = true)
        table_name='trial';
        other_ind_name='Number';
        feature_table_name='trial_feature_value';
    end
    methods (Static = true)
        function trial_array=get_property_array_for_subject(ani)
            trial_array=get_property_array_for_subject@E3.Subject_property_array(ani,'Trial');
            if isempty(trial_array) && ~isempty(ani.E3Name)
                %Get basic details from all trials from the database and
                %create trial objects for each.
                %Don't forget to convert e3time(unixtime) to mysql time.
                %matlab time unit is days since Jan-01-0000
                %e3 time is seconds since gmt
                ss=['INSERT INTO `e3analysis`.`trial` (subject_id,Number,Time)',...
                    ' SELECT {Si}, et.trial, FROM_UNIXTIME(et.time)',...
                    ' FROM `{S}`.`{S}` AS et WHERE et.seq=0 AND et.fragment=1',...
                    ' ON DUPLICATE KEY UPDATE Time=Values(Time)'];
                fprintf('Copy trial details from E3 DB to analysis DB...\n');
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end %#ok<*TLEV>
                mym(cid,ss,ani.DB_id,ani.E3Name,ani.DataTableName);
                %mym(cid,'close');
                trial_array=get_property_array_for_subject@E3.Subject_property_array(ani,'Trial');
            end
        end
    end
    methods
        function value = get.Number(obj)
            value = obj.other_ind_value;
        end
        function set.Number(obj,value)
            obj.other_ind_value=value;
        end
        %!-- Getters and setters. These are really too slow and/or break
        %the mysql service for huge arrays of trials. There are optional
        %methods below for accessing trial properties en masse.
        function value = get.Time(obj)
            value=obj.get_property('Time','datetime');
        end
        function set.Time(obj,value)
            obj.set_property('Time',value,'datetime');
        end
        function value = get.TimeOfDay(obj)
            value=mod(datenum(obj.TimeOfDay),1);
            value=value-(13/24);
            value(value<0)=value(value<0)+1;
        end
        
        %!-- en masse getters for trials.
        function times = get_times(obj)
            n_trials=length(obj);
            times=cell(1,n_trials);
            numbers=NaN(1,n_trials);
            for tt=1:n_trials
                numbers(tt)=obj(tt).Number;
            end
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            ss='SELECT Number,DATE_FORMAT(Time,"%d-%b-%Y %H:%i:%S") as Time FROM `e3analysis`.`trial` WHERE subject_id={Si} AND Number>={Si} AND Number<={Si}';
            mo=mym(cid,ss,obj(1).subject_id,min(numbers),max(numbers));
            %mym(cid,'close');
            if ~isempty(mo.Number)
                [c,ia,ib]=intersect(numbers,mo.Number); %#ok<ASGLU>
                times(ia)=mo.Time(ib);
            end
            %It shouldn't be necessary to get times from raw database
            %because they are retrieved when trials are first created.
        end
        function time_rem = get_tod(obj)
            times = get_times(obj);
            time_nums=datenum(times);
            time_rem=mod(time_nums,1);
            time_rem=time_rem-(13/24);
            time_rem(time_rem<0)=time_rem(time_rem<0)+1;
            time_rem=2*pi*time_rem;
        end
        function isgood = get_isgood(obj)
            n_trials=length(obj);
            isgood=false(1,n_trials);
            numbers=NaN(1,n_trials);
            for tt=1:n_trials
                numbers(tt)=obj(tt).Number;
            end
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            ss='SELECT Number,IsGood FROM `e3analysis`.`trial` WHERE subject_id={Si} AND Number>={Si} AND Number<={Si}';
            mo=mym(cid,ss,obj(1).subject_id,min(numbers),max(numbers));
            %mym(cid,'close');
            if ~isempty(mo.Number)
                [c,ia,ib]=intersect(numbers,mo.Number); %#ok<ASGLU>
                isgood(ia)=logical(mo.IsGood(ib));
            end
        end
        function evoked = get_avg_evoked(trials,frag_ids)
            %function evoked = get_avg_evoked(trials,'paramater',value)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            ani=E3.Subject;
            ani.DB_id=trials(1).subject_id;
            frags=[ani.Fragments];
            chans=[ani.Channels];
            if isempty(frag_ids)
                frag_ids=[2 3];
            end
            samps=[frags.NSamples];
            var_args={'cid',cid,'dbname',ani.E3Name,'tablename',ani.DataTableName,'samps',samps,...
                'frag_ids',frag_ids,'conv',[chans.ad2uv],'checkbg',ani.CheckBG,'freqs',[frags.Fs],'rectified',[]};
            ntb=20;
            n_trials=length(trials);
            nPulls=ceil(n_trials/ntb);
            n_so_far=0;
            evoked=zeros(sum(samps(frag_ids)),length(chans),'double');
            fprintf('\nGetting average evoked from raw data');
            for pu=1:nPulls
                if pu<nPulls
                    trial_id=(pu-1)*ntb+1:pu*ntb;
                else
                    trial_id=(pu-1)*ntb+1:n_trials;
                end
                this_evoked = trials(trial_id).get_evoked(var_args{:});
                
                evoked=evoked+nansum(this_evoked,3);
                n_not_nan=sum(squeeze(any(~any(isnan(this_evoked)),2)));
                n_so_far=n_so_far+n_not_nan;
                if mod(pu,1000)==0
                    fprintf('\n');
                elseif mod(pu,20)==0
                    fprintf('.');
                end
            end
            evoked=evoked./n_so_far;
            %mym(cid,'close');
        end
        function evoked = get_evoked(trials,varargin)
            %function evoked = get_evoked(trials,'paramater',value)
            %Get raw data from elizan database for a set of trials.
            %NOTE - THIS FUNCTION RETURNS ALL CHANNELS FROM RAW DATA. IT IS
            %UP TO CALLER TO PICK AND CHOOSE CHANNELS.
            %NOTE - NaN DATA MAY BE RETURNED
            %This function can be sped up by providing paramaters:
            %cid is the MySQL connection ID
            %dbname (string) is the name of the raw elizan database
            %tablename (string) is the name of the data table in dbname
            %samps is a vector with elements n_samples for each fragment
            %frag_ids is a vector of indices for which fragments are used.
            %conv is a vector containing the conversion factor for ALL
            %channels.
            %checkbg is time in ms
            %freqs is the sampling frequencies for each fragment
            %do_avg tells the function whether the output should be the
            %running average of the supplied trials or the evoked signal
            %from each supplied trial
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            if ~isempty(find(strcmp(varargin, 'ani'), 1))
                ani = varargin{find(strcmp(varargin, 'ani'))+1};
            else
                ani=E3.Subject;
                ani.DB_id=trials(1).subject_id;
            end
            if ~isempty(find(strcmp(varargin, 'dbname'), 1))
                dbname = varargin{find(strcmp(varargin, 'dbname'))+1};
            else
                dbname=ani.E3Name;
            end
            if ~isempty(find(strcmp(varargin, 'tablename'), 1))
                tablename = varargin{find(strcmp(varargin, 'tablename'))+1};
            else
                tablename=ani.DataTableName;
            end
            if ~isempty(find(strcmp(varargin, 'frags'), 1))
                frags = varargin{find(strcmp(varargin, 'frags'))+1};
            else
                frags=[ani.Fragments];
            end
            if ~isempty(find(strcmp(varargin, 'samps'), 1))
                samps = varargin{find(strcmp(varargin, 'samps'))+1};
            else
                samps=[frags.NSamples];
            end
            if ~isempty(find(strcmp(varargin, 'frag_ids'), 1))
                frag_ids = varargin{find(strcmp(varargin, 'frag_ids'))+1};
            else
                frag_ids=1:length(frags);
            end
            if ~isempty(find(strcmp(varargin, 'freqs'), 1))
                freqs = varargin{find(strcmp(varargin, 'freqs'))+1};
            else
                freqs=[frags.Fs];
            end
            if ~isempty(find(strcmp(varargin, 'chans'), 1))
                chans = varargin{find(strcmp(varargin, 'chans'))+1};
            else
                chans=[ani.Channels];
            end
            if ~isempty(find(strcmp(varargin, 'conv'), 1))
                conv = varargin{find(strcmp(varargin, 'conv'))+1};
            else
                conv=[chans.ad2uv];
            end
            if ~isempty(find(strcmp(varargin, 'rectified'), 1))
                rectified = varargin{find(strcmp(varargin, 'rectified'))+1};
            else
                rectified=[];
            end
            if ~isempty(find(strcmp(varargin, 'checkbg'), 1))
                checkbg = varargin{find(strcmp(varargin, 'checkbg'))+1};
            else
                checkbg=ani.CheckBG;
            end
            %CheckBG only applies to the first frag.
            if any(frag_ids==1)
                %checkbg is in ms. Convert to samples.
                nSampsPerBlock=min(checkbg*freqs(1)/1000,samps(1));
                nBlocksPerFrag=samps(1)/nSampsPerBlock;
            end
            nchans=length(conv);
            evoked=NaN(sum(samps(frag_ids)),nchans,length(trials),'double');
            %Sometimes the requested trial range might span a huge gap and
            %using a SQL statement of >1 and <end will return too many
            %trials. Look at the trial numbers passed to this function and then, if
            %necessary, separate them into two groups and run this function
            %twice.
            numbers=[trials.Number];
            
            %I tried doing the following one-trial-at-a-time but it was
            %about half the speed of doing it multiple trials at a time.
            dnum=diff(numbers);
            if any(dnum>100)
                t_group{1}=trials(1:find(dnum==max(dnum),1));
                t_group{2}=trials(find(dnum==max(dnum),1)+1:end);
            else
                t_group{1}=trials;
            end
            %If some trials do not exist, NaN data will be returned.
            ss='SELECT trial,data FROM `{S}`.`{S}` WHERE seq=0 AND fragment={Si} and trial>={Si} AND trial<={Si} ORDER BY trial ASC';
            for tg=1:length(t_group)
                t_trials=t_group{tg};
                for fr=1:length(frag_ids)
                    mo=mym(cid,ss,dbname,tablename,frag_ids(fr)-1,t_trials(1).Number,t_trials(end).Number);
                    %Some trials are missing a fragment. For example, ap-10 trial # 361757
                    %is missing fragment 0.
                    [C,IA,IB] = intersect(numbers,mo.trial); %#ok<ASGLU>
                    temp=double(typecast(cell2mat(mo.data),'int16'));
                    temp=reshape(temp,[],nchans,length(mo.data));
                    if ~isempty(IA) && ~isempty(IB)
                        temp=temp(:,:,IB);
                        %CHECKBG
                        if frag_ids(fr)==1 && nBlocksPerFrag>1
                            X = [ones(nSampsPerBlock,1) (1:nSampsPerBlock)'];
                            for bb=1:nBlocksPerFrag-1
                                %Assume that the present block's mean is correct. For the first
                                %block, this will be a mean of 0. Then, fit a line to the present
                                %block. Save the endpoint of this line. Then, fit a line to the
                                %next block. Determine the y-intercept. Shift the next block so
                                %that it's y-intercept is the same as the end-point of the previous
                                %block.
                                thisBlock=temp((bb-1)*nSampsPerBlock+1:bb*nSampsPerBlock,:,:);
                                nextBlock=temp(bb*nSampsPerBlock+1:(bb+1)*nSampsPerBlock,:,:);
                                for cc=1:nchans
                                    if ~isempty(rectified) && ~rectified(cc)
                                        b1=X\squeeze(thisBlock(:,cc,:));
                                        b2=X\squeeze(nextBlock(:,cc,:));
                                        y1=X*b1;
                                        y2=X*b2;
                                        shifted=y2(1,:)-y1(end,:);
                                        shifted=repmat(shifted,nSampsPerBlock,1);
                                        temp(bb*nSampsPerBlock+1:(bb+1)*nSampsPerBlock,cc,:)=squeeze(nextBlock(:,cc,:))-shifted;
                                    end
                                end
                            end
                        end
                        evoked(sum(samps(frag_ids(1:fr-1)))+1:sum(samps(frag_ids(1:fr))),:,IA)=temp;
                    end
                end
            end 
            %Convert e3 data from A/D units to uV.
            for cc=1:size(evoked,2)
                evoked(:,cc,:)=evoked(:,cc,:).*conv(cc);
            end
        end
        function spectrum = get_spectrum(obj,chan_ids)
            %function spectrum = get_spectrum(trials)
            %This is called by datum.Spectrum.
            params=[25, 3, 197, 5, 10, 0, NaN];
            [spectrum,freqs]=get_power(obj,params,chan_ids); %#ok<NASGU>
        end
        
        %!-- en masse setters aren't really necessary:
        %subject_id and Number are primary keys so can't use setters.
        %Time is set when the trial is created from the e3 db.
        %IsGood is only set by triage trials which has its own function in
        %E3.Subject
        %Evoked and Spectrum aren't stored for trials.
        
        %!-- Datum has functions for getting feature values. They are
        %reasonly fast even for large arrays of trials.
    end
end