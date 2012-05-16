classdef Day < E3.Datum
    properties (Constant = true, Hidden = true)
        table_name='day';
        other_ind_name='Number';
        feature_table_name='day_feature_value';
    end
    properties (Dependent = true)
        Date
        Number
    end
    methods (Static = true)
        function day_array=get_property_array_for_subject(ani)
            day_array=get_property_array_for_subject@E3.Subject_property_array(ani,'Day');
            if isempty(day_array) && ~isempty(ani.E3Name)
                %get first and last trial from the raw database, then
                %create an array of days based on that.
                fprintf('Creating days in analysis DB from first and last trial in E3 DB');
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end %#ok<*TLEV>
                ss='SELECT FROM_UNIXTIME(time) as datestr FROM `{S}`.`{S}` WHERE seq=0 AND fragment=1 ORDER BY time ASC';
                mo=mym(cid,ss,ani.E3Name,ani.DataTableName);
                %mym(cid,'close');
                first_time = datenum(mo.datestr{1},'yyyy-mm-dd HH:MM:SS');
                if mod(first_time,1)<13/24
                    first_time=floor(first_time);
                else
                    first_time=ceil(first_time);
                end
                last_time = datenum(mo.datestr{end},'yyyy-mm-dd HH:MM:SS');
                if mod(last_time,1)<13/24
                    last_time=floor(last_time);
                else
                    last_time=ceil(last_time);
                end
                n_days=last_time-first_time;
                da(n_days)=E3.Day;
                for dd=1:n_days
                    this_date=first_time+dd-1;
                    da(dd).subject_id=ani.DB_id;
                    da(dd).Number=dd;
                    da(dd).Date=datestr(this_date);
                end
                day_array=da;
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
        function value = get.Date(obj)
            value=obj.get_property('Date','date');
        end
        function set.Date(obj,value)
            obj.set_property('Date',value,'date');
        end
    end
end