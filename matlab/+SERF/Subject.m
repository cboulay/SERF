classdef Subject < EERF.Db_obj
    properties (Constant) %These are abstract in parent class
        table_name = 'subject';
        key_names = {'subject_id'};
    end
    properties (Hidden = true)
        subject_id; %subject_id
    end
    properties (Dependent = true, Transient = true)
        Name; %name
        DateOfBirth; %birthday
        Sex; %sex
        Weight; %weight
        Height;
        %HeadSize; %headsize
        %Handedness; %handedness
        %Smoking; %smoking
        %AlcoholAbuse; %alcohol_abuse
        %DrugAbuse; %drug_abuse
        %Medication; %medication
        %VisualImpairment; %visual_impairment
        %HeartImpairment; %heart_impairment
        periods;
        days;
        details;
    end
    
    methods
        function self = Subject(varargin)
%             assert(nargin>=5 && strcmpi(varargin{2},'Name') && strcmpi(varargin{4},'subject_type_id'),...
%                 'EERF.Subject needs Name and subject_type_id when instantiated.');
            self = self@EERF.Db_obj(varargin{:});
        end
        function value=get.Name(self)
            value=self.get_col_value('name');
        end
        function set.Name(self,name)
            self.set_col_value('name',name);
        end
        function value=get.DateOfBirth(self)
            value=self.get_col_value('birthday');
        end
        function set.DateOfBirth(self, DateOfBirth)
            self.set_col_value('birthday', DateOfBirth);
        end
        function value=get.Sex(self)
            value=self.get_col_value('sex');
        end
        function set.Sex(self, Sex)
            self.set_col_value('sex', Sex);
        end
        function value=get.Weight(self)
            value=self.get_col_value('weight');
        end
        function set.Weight(self,Weight)
            self.set_col_value('weight',Weight);
        end
        function periods=get.periods(self)
            periods=EERF.Db_obj.get_obj_array(self.dbx, 'Period',...
                'subject_id', self.subject_id, 'span_type', 'period');
        end
        function days=get.days(self)
            days=EERF.Db_obj.get_obj_array(self.dbx, 'Period',...
                'subject_id', self.subject_id, 'span_type', 'day');
        end
        %To modify a period's subject, do so on the period object.
        function details=get.details(self)
            details=EERF.Db_obj.get_obj_array(self.dbx,'SubjectDetail',...
                'subject_id',self.subject_id);
        end
    end
end