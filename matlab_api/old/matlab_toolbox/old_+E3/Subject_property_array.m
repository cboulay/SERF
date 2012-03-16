classdef Subject_property_array < handle
    %This will be a parent class for objects that typically exist as an
    %array of objects in an Subject property.
    properties (Abstract = true, Constant = true, Hidden=true)
        table_name;
        other_ind_name;
    end
    properties (Transient = true, Hidden = true)
        subject_id;
        other_ind_value;
    end
    methods (Static = true)
        %gets the other_ind from the database for a given ani
        function prop_array=get_property_array_for_subject(ani,class_name)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            oin=E3.(class_name).other_ind_name;
            tn=E3.(class_name).table_name;
            mo=mym(cid,'SELECT {S} from `e3analysis`.`{S}` WHERE subject_id={Si}',oin,tn,ani.DB_id);
            %mym(cid,'close');
            inds=mo.(oin);
            n_inds=length(inds);
            if n_inds>0
                prop_array(n_inds)=E3.(class_name);
                for pp=1:n_inds
                    prop_array(pp).subject_id=ani.DB_id;
                    prop_array(pp).other_ind_value=inds(pp);
                end
            else
                prop_array=[];
            end
        end
    end
    %Can't use getters and setters for primary keys. Just use INSERT ON
    %DUPLICATE KEY UPDATE for all other (non-primary-key) properties and
    %make the child's getters and setters impotent if the primary keys are
    %not defined.
    %Getters are called individually for each object. I can't batch them.
    %Getting a property for a huge array of objects (e.g. [trials.IsGood])
    %can break the mysql service. Since huge arrays will only ever occur in
    %trials, maybe E3.Trial should have a couple custom functions.
    methods
        function value=get_property(obj,prop_name,type)
            if ~isempty(obj.subject_id) && ~isempty(obj.other_ind_value)
                switch type
                    case {'float','int','bool','string'}
                        m_s='{S}';
                    case 'datetime'
                        m_s='DATE_FORMAT({S},"%d-%b-%Y %H:%i:%S") as datetime';
                    case 'date'
                        m_s='DATE_FORMAT({S},"%d-%b-%Y") as datetime';
                end
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                ss=['SELECT ',m_s,' FROM `e3analysis`.`{S}` WHERE subject_id={Si} AND {S}={Si}'];
                mo=mym(cid,ss,prop_name,obj.table_name,obj.subject_id,obj.other_ind_name,obj.other_ind_value);
                switch type
                    case {'float','int'}
                        if ~isempty(mo.(prop_name))
                            value=mo.(prop_name)(1);
                        end
                    case 'bool'
                        if ~isempty(mo.(prop_name))
                            value=logical(mo.(prop_name)(1));
                        end
                    case 'string'
                        if ~isempty(mo.(prop_name))
                            value=mo.(prop_name){1};
                        end
                    case {'datetime','date'}
                        if ~isempty(mo.datetime)
                            value=mo.datetime{1};
                        end
                end
                %mym(cid,'close');
            end
        end
        function set_property(obj,prop_name,value,type)
            if ~isempty(obj.subject_id) && ~isempty(obj.other_ind_value)
                switch type
                    case 'float'
                        m_s='{S4}';
                    case 'int'
                        m_s='{Si}';
                    case 'string'
                        m_s='"{S}"';
                    case 'datetime'
                        m_s='STR_TO_DATE("{S}","%d-%b-%Y %H:%i:%S")';
                    case 'date'
                        m_s='STR_TO_DATE("{S}","%d-%b-%Y")';
                end
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end %#ok<*TLEV>
                ss=['INSERT INTO `e3analysis`.`{S}` (subject_id,{S},{S}) VALUES ({Si},{Si},',m_s,')',...
                    ' ON DUPLICATE KEY UPDATE {S}=VALUES({S})'];
                mym(cid,ss,obj.table_name,obj.other_ind_name,prop_name,obj.subject_id,obj.other_ind_value,value,prop_name,prop_name);
                %mym(cid,'close');
            end
        end
        function remove_from_db(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mym(cid,'BEGIN');
            for oo=1:length(obj)
                this_obj=obj(oo);
                ss='DELETE FROM `e3analysis`.`{S}` WHERE subject_id={Si} AND {S}={Si}';
                mym(cid,ss,this_obj.table_name,this_obj.subject_id,this_obj.other_ind_name,this_obj.other_ind_value);
            end
            mym(cid,'COMMIT');
            %mym(cid,'close');
        end
    end
end