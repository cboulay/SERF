classdef Datum < E3.Subject_property_array
    %This is a second parent class for Trial, Day, and Period.
    properties (Dependent = true)
        IsGood
    end
    properties (Abstract = true, Constant = true)
        feature_table_name;
    end
    properties (Transient = true, Hidden = true)
        salient_ft_id;
        mym_cid; %Useful for transactions and large batches of selects.
    end
    properties (Dependent = true, Hidden = true)
        salient_ft_name;
        FeatureValue
        Evoked
        Spectrum
    end
    %Dynamic property values can only be accessed one instance at a
    %time, not for a whole object array. So can't use for Features.
    methods
        %!--- Setter and getters
        function value = get.IsGood(obj)
            value=obj.get_property('IsGood','bool');
        end
        function set.IsGood(obj,value)
            obj.set_property('IsGood',value,'int');
        end
        function value = get.salient_ft_name(obj)
            if ~isempty(obj.salient_ft_id)
                ft=E3.Feature_type;
                ft.DB_id=obj.salient_ft_id;
                value=ft.Name;
            else
                value='set salient_ft_id first';
            end
        end
        function feature_value = get.FeatureValue(obj)
            if ~isempty(obj.feature_table_name) && ~isempty(obj.subject_id) && ~isempty(obj.salient_ft_id) ...
                    && ~isempty(obj.other_ind_name) && ~isempty(obj.other_ind_value)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end %#ok<*TLEV>
                ss='SELECT Value FROM `e3analysis`.`{S}` WHERE subject_id={Si} AND feature_type_id={Si} AND {S}={Si}';
                mo=mym(cid,ss,obj.feature_table_name,obj.subject_id,obj.salient_ft_id,obj.other_ind_name,obj.other_ind_value);
                if ~isempty(mo.Value)
                    feature_value=mo.Value(1);
                else
                    %feature has not been calculated previously.
                    %Calculate now.
                    ft=E3.Feature_type;
                    ft.DB_id=obj.salient_ft_id;
                    feature_value=obj.calculate_feature(ft);
                end
                %mym(cid,'close');
            else
                feature_value='set salient_ft_id first';
            end
        end
        function set.FeatureValue(obj,value)
            if ~isempty(obj.feature_table_name) && ~isempty(obj.subject_id) && ~isempty(obj.salient_ft_id) ...
                    && ~isempty(obj.other_ind_name) && ~isempty(obj.other_ind_value)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                ss=['INSERT INTO `e3analysis`.`{S}` (subject_id,feature_type_id,{S},Value) VALUES ({Si},{Si},{Si},{S4})',...
                    ' ON DUPLICATE KEY UPDATE Value=VALUES(Value)'];
                mym(cid,ss,obj.feature_table_name,obj.other_ind_name,obj.subject_id,obj.salient_ft_id,obj.other_ind_value,value);
                %mym(cid,'close');
            end
        end
        function evoked = get.Evoked(datum)
            %I can't overload getters and setters for subclass Trial, so I
            %have to use a switch here with two separate sections of code.
            ani=E3.Subject;
            ani.DB_id=datum.subject_id;
            chans=ani.Channels;
%             channel_bool=[chans.IsGood];
            switch class(datum)
                case {'E3.Day','E3.Period'}
                    evoked=[];
                    ss='SELECT Evoked FROM `e3analysis`.`{S}` WHERE subject_id={Si} AND {S}={Si}';
                    global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                    mo=mym(cid,ss,datum.table_name,datum.subject_id,datum.other_ind_name,datum.other_ind_value);
                    if ~isempty(mo.Evoked{1})
                        %convert blob to data. This should return a matrix
                        %of size samps x chans. If not, then delete it.
                        evoked=mo.Evoked{1};
                        if size(evoked,2)~=length(chans)
                            evoked=[];
                        end
                    end
                    if isempty(evoked)
                        trials=datum.get_trials(true);
                        evoked=trials.get_avg_evoked([1 2 3]);
%                         evoked=evoked(:,channel_bool);
                        datum.Evoked=evoked;
                    end
                case 'E3.Trial'
                    %Single-trial evoked is never stored in the new
                    %database because it would take up too much space.
                    varargs={'ani';ani};
                    evoked=datum.get_evoked(varargs);
%                     evoked=evoked(:,channel_bool);
            end
        end
        function set.Evoked(obj,evoked)
            switch class(obj)
                case {'E3.Day','E3.Period'}
                    global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                    ss=['INSERT INTO `e3analysis`.`{S}` (subject_id,{S},Evoked) VALUES ({Si},{Si},"{M}")',...
                        ' ON DUPLICATE KEY UPDATE Evoked=VALUES(Evoked)'];
                    mym(cid,ss,obj.table_name,obj.other_ind_name,obj.subject_id,obj.other_ind_value,evoked);
                    %mym(cid,'close');
            end
        end
        function spectrum = get.Spectrum(obj)
            ani=E3.Subject;
            ani.DB_id=obj.subject_id;
%             channel_bool=[ani.Channels.IsGood];
            switch class(obj)
                case {'E3.Day','E3.Period'}
                    spectrum=[];
                    global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                    ss='SELECT Spectrum FROM `e3analysis`.`{S}` WHERE subject_id={Si} AND {S}={Si}';
                    mo=mym(cid,ss,obj.table_name,obj.subject_id,obj.other_ind_name,obj.other_ind_value);
                    %mym(cid,'close');
                    if ~isempty(mo.Spectrum{1})
                        %convert blob to data.
                        spectrum=squeeze(mo.Spectrum{1});
                    end
                    if isempty(spectrum)
                        fprintf('\nCalculating average-spectrum from raw data\n');
                        trials=obj.get_trials(true);
                        spectrum = trials.get_spectrum([]);
                        spectrum=nanmean(spectrum,3);
                        obj.Spectrum=spectrum; %save to db.
                    end
                case 'E3.Trial'
                    spectrum = obj.get_spectrum([]);
            end
        end
        function set.Spectrum(obj,spectrum)
            switch class(obj)
                case {'E3.Day','E3.Period'}
                    global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                    ss=['INSERT INTO `e3analysis`.`{S}` (subject_id,{S},Spectrum) VALUES ({Si},{Si},"{M}")',...
                        ' ON DUPLICATE KEY UPDATE Spectrum=VALUES(Spectrum)'];
                    mym(cid,ss,obj.table_name,obj.other_ind_name,obj.subject_id,obj.other_ind_value,spectrum);
                    %mym(cid,'close');
            end
        end
        
        %!--- Helpers
        function trials=get_trials(datum,good_only)
            %function trials=get_trials(data,good_only)
            %Retrieves an array of trials that exist within the defined
            %period. good_only determines whether or not to use IsGood in
            %retrieval of trials.
            %This function is only defined for Period and Day.
            if length(datum)>1
                warning('get_trials not defined for more than one datum object. Only first object used.'); %#ok<WNTAG>
                datum=datum(1);
            end
            class_name=class(datum);
            switch class_name
                case 'E3.Period'
                    tbl='period';
                    s1='datum.StartTime';
                    s2='datum.EndTime';
                    s3='period_type_id';
                case 'E3.Day'
                    tbl='day';
                    s1='ADDTIME(datum.Date,"13:00:00")';
                    s2='ADDTIME(datum.Date,"1 13:00:00")';
                    s3='Number';
            end
            ss=['SELECT et.Number FROM `e3analysis`.`trial` AS et, `e3analysis`.`',tbl,'` AS datum',...
                ' WHERE datum.subject_id=et.subject_id AND et.subject_id={Si}',...
                ' AND et.Time>=',s1,' AND et.Time<',s2,' AND datum.',s3,'={Si}'];
            if good_only
                ss=[ss,' AND et.IsGood=1'];
            end
            %ss needs subject_id and the other ind id
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,ss,datum.subject_id,datum.other_ind_value);
            n_trials=length(mo.Number);
            clear trials
            if n_trials>0
                trials(n_trials)=E3.Trial;
                for tt=1:length(trials)
                    trials(tt).subject_id=datum.subject_id;
                    trials(tt).Number=mo.Number(tt);
                end
            else
                trials=[];
            end
        end
        
        %!--- Custom setters and getters. These are much faster for large
        %arrays of objects (e.g. trials)
        %Feature getters use parameter ft, instead of requiring salient_ft_id to be set.
        function feature_value=get_feature_value_for_ft(obj,ft)
            %This function pulls ALL feature values for a given subject x
            %object type (e.g. all of an subject's trials, when obj is a
            %trial) x feature type within the range of requested objects.
            %It only returns values corresponding to requested objects.
            %Do not use this function if you are trying to get feature
            %values for a few objects when there are many such objects in
            %the database.
%             fprintf('\nGetting %s for trials\n',ft.Name);
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            ss=['SELECT Value,{S} FROM `e3analysis`.`{S}`',...
                ' WHERE subject_id={Si} AND feature_type_id={Si} AND {S}>={Si} AND {S}<={Si}'];
            mo=mym(cid,ss,obj(1).other_ind_name,obj(1).feature_table_name,obj(1).subject_id,ft.DB_id,obj(1).other_ind_name,obj(1).other_ind_value,obj(1).other_ind_name,obj(end).other_ind_value);
            %mym(cid,'close');
            %compare the other_ind_name with that of the passed in obj
            %array, in case features aren't calculated for some trials.
            feature_value=NaN(1,length(obj));
            %Get arrays of indices for the passed objects and returned
            %values.
            obj_other_ind=[obj.other_ind_value];
            new_other_ind=mo.(obj(1).other_ind_name)';
            %See where the indices intersect and use those feature_values.
            [c,ia,ib]=intersect(obj_other_ind,new_other_ind); %#ok<ASGLU>
            feature_value(ia)=mo.Value(ib);
            %See where the indices do not intersect and calculate features.
            [c,ia]=setdiff(obj_other_ind,new_other_ind); %#ok<ASGLU>
            ia=union(ia,find(isnan(feature_value)));
            if any(ia) %Some passed objects did not have features in the db.
                %Calculate features for remaining objects.
                feature_value(ia)=calculate_feature(obj(ia),ft);
            end
        end
        function feature_value=calculate_feature(data,ft)
            %function feature_value=calculate_feature(data,ft)
            %If the passed datum is a Period or a Day, then this will pull
            %the trials for that P/D, then get the feature values for those
            %trials, then average them.
            %If the passed data are trials, then this will calculate the
            %trial feature values from the function specified by the
            %feature type.
            switch class(data(1))
                case {'E3.Day','E3.Period'}
                    feature_value=NaN(1,length(data));
                    for dd=1:length(data)
                        trials=data(dd).get_trials(true); %good trials only.
                        if ~isempty(trials)
                            vals=trials.get_feature_value_for_ft(ft);
                            feature_value(dd)=nanmean(vals);
                        end
                    end
                case 'E3.Trial'
                    fname=ft.FunctionName;
                    if ~isempty(fname)
                        fh = str2func(fname);
                        feature_value=fh(data);
                        if length(feature_value)~=length(data)
                            warning('Wrong number of features returned'); %#ok<WNTAG>
                        end
                    end
            end
            %Save to database so they don't have to be calculated
            %again.
            data.set_feature_value_for_ft(ft,feature_value);
        end
        function set_feature_value_for_ft(obj,ft,value)
            sv=size(value);
            %This check allows me to calculate and return features that are
            %not stored in the database because they are
            %multidimensional.
            if length(sv(sv>1))==1
%                 fprintf('Saving newly calculated feature to db\n');
                ss=['INSERT INTO `e3analysis`.`{S}` (subject_id,feature_type_id,{S},Value) VALUES ({Si},{Si},{Si},{S4})',...
                    ' ON DUPLICATE KEY UPDATE Value=VALUES(Value)'];
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                mym(cid,'BEGIN');
                for dd=1:length(obj)
                    if ~isnan(value(dd))
                        mym(cid,ss,obj(dd).feature_table_name,obj(dd).other_ind_name,obj(dd).subject_id,ft.DB_id,obj(dd).other_ind_value,value(dd));
                    end
                end
                mym(cid,'COMMIT');
                %mym(cid,'close');
            end
        end
        
        %!---------------------------------------------------------------
        %Each of the following are functions that calculate specific
        %features. They must be able to accommodate one or many Trials.
        %Each function is defined in a separate file.
        feature_value=get_feature_flats(data);
        feature_value=get_feature_lsi(data);
        feature_value=get_feature_sixty(data);
        feature_value=get_feature_mb(data);
        feature_value=get_feature_g1(data);
        feature_value=get_feature_g2(data);
        feature_value=get_feature_stim(data);
        feature_value=get_sep_p1(data);
        feature_value=get_sep_n1(data);
        feature_value=get_sep_p2(data);
        feature_value=get_sep_n2(data);
        feature_value=get_feature_bge(data);
        feature_value=get_feature_mw(data);
        feature_value=get_feature_hr(data);
    end
end