classdef Datum < EERF.Db_obj
    properties (Constant) %These are abstract in parent class
        table_name='datum';
        key_names={'datum_id'};
    end
    properties (Hidden = true)
        datum_id;
    end
    properties (Dependent = true, Transient = true)
        subject; %subject
        Number; %number
        span_type; %span_type
        IsGood; %is_good
        StartTime; %start_time
        StopTime; %stop_time
        erp;
        xvec;
        n_channels;
        n_samples;
        channel_labels;
        features;
        details;
    end
    methods
        function obj = Datum(varargin)
            obj = obj@EERF.Db_obj(varargin{:});
        end
        
        function subject=get.subject(self)
            subject=self.get_x_to_one('subject_id',...
                'Subject', 'subject_id');
        end
        %TODO: FIXME
%         function set.subject(self,subject)
%             self.set_x_to_one(subject,'subject_type_id','subject_type_id');
%         end

        function value=get.Number(obj)
            value=obj.get_col_value('number');
        end
        
        function set.Number(obj,Number)
            obj.set_col_value('number',Number);
        end
        
        function value=get.span_type(obj)
            value=obj.get_col_value('span_type');
        end
        
        function set.span_type(obj,span_type)
            obj.set_col_value('span_type',span_type);
        end
        
        function value=get.IsGood(obj)
            value=obj.get_col_value('is_good');
        end
        
        function set.IsGood(obj,IsGood)
            obj.set_col_value('is_good',IsGood);
        end
        
        function value=get.StartTime(obj)
            value=obj.get_col_value('start_time');
        end
        
        function set.StartTime(obj,StartTime)
            StartTime = datestr(StartTime, 'yyyy-mm-dd HH:MM:SS');%reformat StartTime to something mysql likes
            obj.set_col_value('start_time',StartTime);
        end
        
        function value=get.StopTime(obj)
            value=obj.get_col_value('stop_time');
        end
        
        function set.StopTime(obj,StopTime)
            StopTime = datestr(StopTime, 'yyyy-mm-dd HH:MM:SS');%reformat EndTime to something mysql likes
            obj.set_col_value('stop_time', StopTime);
        end
        
        function erp=get.erp(datum)%
            sel_stmnt=['SELECT erp FROM datum_store WHERE datum_id=',num2str(datum.datum_id)];
            mo=datum.dbx.statement(sel_stmnt);
            erp=mo.erp{1}; %size(erp)=38400,1, but 2 chans and 2400 samps. i.e. 8 erp entries per actual value.
            erp=typecast(erp,'double');
            erp=reshape(erp,datum.n_samples,datum.n_channels);
        end
        
        function set.erp(datum, values)
            [n_samples, n_channels] = size(values);
            values = reshape(values,[],1);
            values = typecast(values, 'uint8');
            stmnt = 'UPDATE datum_store SET erp = "{uB}", n_channels={Si}, n_samples={Si} WHERE datum_id={Si}';
            parms = {values;n_channels;n_samples;datum.datum_id};
            datum.dbx.statement(stmnt, parms);
        end
        
        function xvec=get.xvec(datum)%
            sel_stmnt=['SELECT x_vec FROM datum_store WHERE datum_id=',num2str(datum.datum_id)];
            mo=datum.dbx.statement(sel_stmnt);
            xvec=mo.x_vec{1};
            xvec=typecast(xvec,'double');
        end
        
        function set.xvec(datum,xvec)
            %TODO: Convert xvec to vector of uint8 from vector of double.
            xvec = typecast(xvec,'uint8');
            stmnt = 'UPDATE datum_store SET x_vec = "{uB}" WHERE datum_id={Si}';
            parms = {xvec;datum.datum_id};
            datum.dbx.statement(stmnt, parms);
        end
        
        function n_channels=get.n_channels(datum)%
            sel_stmnt=['SELECT n_channels FROM datum_store WHERE datum_id=',num2str(datum.datum_id)];
            mo=datum.dbx.statement(sel_stmnt);
            n_channels=mo.n_channels(1);
        end
        
        function n_samples=get.n_samples(datum)%
            sel_stmnt=['SELECT n_samples FROM datum_store WHERE datum_id=',num2str(datum.datum_id)];
            mo=datum.dbx.statement(sel_stmnt);
            n_samples=mo.n_samples(1);
        end
        
        function channel_labels=get.channel_labels(datum)%
            sel_stmnt=['SELECT channel_labels FROM datum_store WHERE datum_id=',num2str(datum.datum_id)];
            mo=datum.dbx.statement(sel_stmnt);
            channel_labels = mo.channel_labels{1};
            channel_labels=char(channel_labels)';
            channel_labels=textscan(channel_labels,'%s','delimiter',',');
            channel_labels=channel_labels{1};
        end
        
        function set.channel_labels(datum,channel_labels)
            n_chans = length(channel_labels);
            channel_labels = cellstr(channel_labels);
            if size(channel_labels,1)==1 && size(channel_labels,2)>1
                channel_labels = channel_labels';
            end
            channel_labels = [channel_labels repmat({','},n_chans,1)];
            channel_labels = reshape(channel_labels',1,[]);
            channel_labels = cell2mat(channel_labels);
            channel_labels = channel_labels(1:end-1);
%             channel_labels = cast(channel_labels','uint8');
            stmnt = 'UPDATE datum_store SET channel_labels = "{S}" WHERE datum_id={Si}';
            parms = {channel_labels;datum.datum_id};
            datum.dbx.statement(stmnt, parms);
        end
        
        %TODO: Setters for features and details? -> Subclasses?
        %TODO: Further parameters to splice features/details?
        function features = get.features(datum)%
            features = EERF.Db_obj.get_obj_array(datum.dbx,'DatumFeature','datum_id',datum.datum_id);
        end
        
        function feature = get_single_feature(datum, feature_name)
            %Instead of relying on trial.features, it is faster to call upon
            %it directly.
            stmnt = ['SELECT dfv.value as val FROM datum_feature_value AS dfv, feature_type as ft',...
                ' WHERE ft.name LIKE "{S}"',...
                ' AND dfv.feature_type_id = ft.feature_type_id',...
                ' AND dfv.datum_id = {Si}'];
            mo = datum.dbx.statement(stmnt,{feature_name,datum.datum_id});
            feature = mo.val;
        end
        
        function set_single_feature(datum, feature_type, value)
            %TODO: Use Db_obj functions.
            %TODO: If feature_type is a string it is the feature_name
            stmnt = ['INSERT INTO datum_feature_value (datum_id, feature_type_id, value) '...
                'VALUES ({Si}, {Si}, {S4}) '...
                'ON DUPLICATE KEY UPDATE value={S4}'];
            mo = datum.dbx.statement(stmnt, {datum.datum_id, feature_type.feature_type_id, value, value});
        end
            
        function details = get.details(datum)
            details = EERF.Db_obj.get_obj_array(datum.dbx, 'DatumDetail', 'datum_id', datum.datum_id);
        end
        
        function detail = get_single_detail(datum, detail_name)
            %Instead of relying on trial.details, it is faster to call upon
            %it directly.
            stmnt = ['SELECT ddv.Value as val FROM datum_detail_value AS ddv, detail_type as dt',...
                ' WHERE dt.name LIKE "{S}"',...
                ' AND ddv.detail_type_id = dt.detail_type_id',...
                ' AND ddv.datum_id = {Si}'];
            mo = datum.dbx.statement(stmnt,{detail_name,datum.datum_id});
            detail = mo.val{1};
        end
        
        function result=calculate_feature(datum, feature_type)
            if strcmpi(feature_type.Name,'MEP_p2p')
                x_start_name = 'MEP_start_ms';
                x_stop_name = 'MEP_stop_ms';
                chan_label_name = 'MEP_chan_label';
                
                det_names = {datum.details.name};
                x_start_ms = str2double(datum.details(strcmpi(det_names, x_start_name)).Value);
                x_stop_ms = str2double(datum.details(strcmpi(det_names, x_stop_name)).Value);
                chan_name = datum.details(strcmpi(det_names, chan_label_name)).Value;
                
                x_vec = datum.xvec;
                x_bool = x_vec >= x_start_ms & x_vec <= x_stop_ms;
                y_dat = datum.erp(x_bool,strcmpi(datum.channel_labels,chan_name));
                result=max(y_dat)-min(y_dat);
                
                dfv=datum.features(strcmpi({datum.features.Name},feature_type.Name));
                dfv.Value=result;
            else
                result=NaN;
            end
        end
        
        function plot(datum)
            plot(datum.xvec, datum.erp)
            legend(datum.channel_labels);
        end
    end
    
    %TODO: Move these to a different class.
    methods (Static)
        function yhat=sigmoid(b,X)
            %b(1) = max value
            %b(2) = slope
            %b(3) = x at which y is halfmax
            %b(4) = offset (when x=0)
            yhat = b(1) ./ (1 + exp(-1*b(2)*(X-b(3)))) + b(4);
            %yhat = X(:,2) ./ (1 + exp(-1*b(1)*(X(:,1)-b(2)))) + X(:,3);
        end
        function yhat=sigmoid_simple(b,X)
            yhat = 1 ./ (1 + exp(-1*b(1)*(X-b(2))));
        end
    end
end