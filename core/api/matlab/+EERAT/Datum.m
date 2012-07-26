classdef Datum < EERAT.Db_obj
    properties (Constant) %These are abstract in parent class
        table_name='datum';
        key_names={'datum_id'};
    end
    properties (Hidden = true)
        datum_id;
    end
    properties (Dependent = true, Transient = true)
        subject;
        datum_type;
        Number;
        span_type;
        IsGood;
        StartTime;
        EndTime;
        MeetsCriteria;
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
            obj = obj@EERAT.Db_obj(varargin);
        end
        function subject=get.subject(self)
            subject=self.get_x_to_one('subject_type_id',...
                'Subject','subject_type_id');
        end
        function set.subject(self,subject)
            self.set_x_to_one(subject,'subject_type_id','subject_type_id');
        end
        function datum_type=get.datum_type(self)
            datum_type=self.get_x_to_one('datum_type_id',...
                'DatumType','datum_type_id');
        end
        function set.datum_type(self,datum_type)
            self.set_x_to_one(datum_type,'datum_type_id','datum_type_id');
        end
        function value=get.Number(obj)
            value=obj.get_col_value('Number');
        end
        function set.Number(obj,Number)
            obj.set_col_value('Number',Number);
        end
        function value=get.span_type(obj)
            value=obj.get_col_value('span_type');
        end
        function set.span_type(obj,span_type)
            obj.set_col_value('span_type',span_type);
        end
        function value=get.IsGood(obj)
            value=obj.get_col_value('IsGood');
        end
        function set.IsGood(obj,IsGood)
            obj.set_col_value('IsGood',IsGood);
        end
        function value=get.StartTime(obj)
            value=obj.get_col_value('StartTime');
        end
        function set.StartTime(obj,StartTime)
            obj.set_col_value('StartTime',StartTime);
        end
        function value=get.EndTime(obj)
            value=obj.get_col_value('EndTime');
        end
        function set.EndTime(obj,EndTime)
            obj.set_col_value('EndTime',EndTime);
        end
        function value=get.MeetsCriteria(obj)
            value=obj.get_col_value('MeetsCriteria');
        end
        function set.MeetsCriteria(obj,MeetsCriteria)
            obj.set_col_value('MeetsCriteria',MeetsCriteria);
        end
        
        %TODO: Setters for store.
        function erp=get.erp(datum)%
            sel_stmnt=['SELECT erp FROM datum_store WHERE datum_id=',num2str(datum.datum_id)];
            mo=datum.dbx.statement(sel_stmnt);
            erp=mo.erp{1}; %size(erp)=38400,1, but 2 chans and 2400 samps. i.e. 8 erp entries per actual value.
            erp=typecast(erp,'double');
            erp=reshape(erp,datum.n_samples,datum.n_channels);
        end
        function xvec=get.xvec(datum)%
            sel_stmnt=['SELECT x_vec FROM datum_store WHERE datum_id=',num2str(datum.datum_id)];
            mo=datum.dbx.statement(sel_stmnt);
            xvec=mo.x_vec{1};
            xvec=typecast(xvec,'double');
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
            channel_labels=char(mo.channel_labels{1})';
            channel_labels=textscan(channel_labels,'%s','delimiter',',');
            channel_labels=channel_labels{1};
        end
        
        %TODO: Setters for features and details?
        %TODO: Further parameters to splice features/details?
        function features=get.features(datum)%
            features=EERAT.Db_obj.get_obj_array(datum.dbx,'DatumFeature','datum_id',datum.datum_id);
        end
        function details=get.details(datum)
            details=EERAT.Db_obj.get_obj_array(datum.dbx,'DatumDetail','datum_id',datum.datum_id);
        end
        
        function result=calculate_feature(datum,feature_type)
            if strcmpi(feature_type.Name,'MEP_p2p')
                x_start_name='dat_MEP_start_ms';
                x_stop_name='dat_MEP_stop_ms';
                chan_label_name='dat_MEP_chan_label';
                
                det_names={datum.details.Name};               
                x_start_ms=str2double(datum.details(strcmpi(det_names,x_start_name)).Value);
                x_stop_ms=str2double(datum.details(strcmpi(det_names,x_stop_name)).Value);
                chan_name=datum.details(strcmpi(det_names,chan_label_name)).Value;
                
                x_vec=datum.xvec;
                x_bool=x_vec>=x_start_ms & x_vec<=x_stop_ms;
                y_dat=datum.erp(x_bool,strcmpi(datum.channel_labels,chan_name));
                result=max(y_dat)-min(y_dat);
                
                dfv=datum.features(strcmpi({datum.features.Name},feature_type.Name));
                dfv.Value=result;
            else
                result=NaN;
            end
        end
    end
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