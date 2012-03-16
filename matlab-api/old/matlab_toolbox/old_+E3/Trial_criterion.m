classdef Trial_criterion < handle
    properties (Dependent = true)
        Full_name %useful for GUI only
        Feature_name
    end
    properties (Dependent = true, Hidden = true)
        Rs_value
        rs_feature_type_id
    end
    properties (Transient = true, Hidden = true)
        subject_id
        ls_feature_type_id
    end
    properties (Transient = true)
        Comparison_operator
    end
    methods (Static = true)
        function crits=get_criteria_for_ani(ani)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            ss=['SELECT subject_id,ls_feature_type_id,Comparison_operator',...
                ' FROM `e3analysis`.`trial_criterion` WHERE subject_id={Si}'];
            mo=mym(cid,ss,ani.DB_id);
            n_crits=length(mo.subject_id);
            if n_crits>0
                crits(n_crits)=E3.Trial_criterion;
                for cc=1:n_crits
                    crits(cc).subject_id=mo.subject_id(cc);
                    crits(cc).ls_feature_type_id=mo.ls_feature_type_id(cc);
                    crits(cc).Comparison_operator=mo.Comparison_operator{cc};
                end
            else
                crits=[];
                %New crits can only be created by a GUI. Be sure to set
                %subject_id, ls_feature_type_id and Comparison_operator
                %before setting anything else.
            end
            %mym(cid,'close');
        end
    end
    methods
        function value=get.Full_name(obj)
            if ~isempty(obj.Rs_value) && ~isnan(obj.Rs_value)
                value=[obj.Feature_name,' ',obj.Comparison_operator,' ',num2str(obj.Rs_value)];
            elseif ~isempty(obj.rs_feature_type_id) && ~isnan(obj.rs_feature_type_id)
                rs_ft=E3.Feature_type;
                rs_ft.DB_id=obj.rs_feature_type_id;
                value=[obj.Feature_name,' ',obj.Comparison_operator,' ',rs_ft.Name];
            end
        end
        function value=get.Feature_name(obj)
            ls_ft=E3.Feature_type;
            ls_ft.DB_id=obj.ls_feature_type_id;
            value=ls_ft.Name;
        end
        function value=get.Rs_value(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            ss=['SELECT Rs_value FROM `e3analysis`.`trial_criterion`',...
                ' WHERE subject_id={Si} AND ls_feature_type_id={Si} AND Comparison_operator LIKE "{S}"'];
            mo=mym(cid,ss,obj.subject_id,obj.ls_feature_type_id,obj.Comparison_operator);
            if any(size(mo.Rs_value)==0)
                value=[];
            else
                value=mo.Rs_value(1);
            end
            %mym(cid,'close');
        end
        function set.Rs_value(obj,value)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            ss=['INSERT INTO `e3analysis`.`trial_criterion` (subject_id,ls_feature_type_id,Comparison_operator,Rs_value)',...
                ' VALUES ({Si},{Si},"{S}",{S4}) ON DUPLICATE KEY UPDATE Rs_value=VALUES(Rs_value)'];
            mym(cid,ss,obj.subject_id,obj.ls_feature_type_id,obj.Comparison_operator,value);
            %mym(cid,'close');
        end
        function value=get.rs_feature_type_id(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            ss=['SELECT rs_feature_type_id FROM `e3analysis`.`trial_criterion`',...
                ' WHERE subject_id={Si} AND ls_feature_type_id={Si} AND Comparison_operator LIKE "{S}"'];
            mo=mym(cid,ss,obj.subject_id,obj.ls_feature_type_id,obj.Comparison_operator);
            value=mo.rs_feature_type_id(1);
            %mym(cid,'close');
        end
        function set.rs_feature_type_id(obj,value)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            ss=['INSERT INTO `e3analysis`.`trial_criterion` (subject_id,ls_feature_type_id,Comparison_operator,rs_feature_type_id)',...
                ' VALUES ({Si},{Si},"{S}",{Si}) ON DUPLICATE KEY UPDATE rs_feature_type_id=VALUES(rs_feature_type_id)'];
            mym(cid,ss,obj.subject_id,obj.ls_feature_type_id,obj.Comparison_operator,value);
            %mym(cid,'close');
        end
        function remove_from_db(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            ss='DELETE FROM `e3analysis`.`trial_criterion` WHERE subject_id={Si} AND ls_feature_type_id={Si} AND Comparison_operator LIKE "{S}"';
            for oo=1:length(obj)
                to=obj(oo);
                mym(cid,ss,to.subject_id,to.ls_feature_type_id,to.Comparison_operator);
            end
            %mym(cid,'close');
        end
    end
end