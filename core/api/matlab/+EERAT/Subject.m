classdef Subject < EERAT.Db_obj
    properties (Constant) %These are abstract in parent class
        table_name='subject';
        key_names={'subject_id'};
    end
    properties (Hidden = true)
        subject_id;
    end
    properties (Dependent = true, Transient = true)
        subject_type;
        Name;
        DateOfBirth;
        IsMale;
        Weight;
        Notes;
        species_type;
        periods;
        experiments;
        details;
    end
    methods
        function self = Subject(varargin)
            temp=varargin;
            self = self@EERAT.Db_obj(temp);
        end
        function subject_type=get.subject_type(self)
            subject_type=self.get_x_to_one('subject_type_id',...
                'SubjectType','subject_type_id');
        end
        function set.subject_type(self,one)
            self.set_x_to_one(one,'subject_type_id','subject_type_id');
        end
        function value=get.Name(self)
            value=self.get_col_value('Name');
        end
        function set.Name(self,name)
            self.set_col_value('Name',name);
        end
        function value=get.DateOfBirth(self)
            value=self.get_col_value('DateOfBirth');
        end
        function set.DateOfBirth(self,DateOfBirth)
            self.set_col_value('DateOfBirth',DateOfBirth);
        end
        function value=get.IsMale(self)
            value=self.get_col_value('IsMale');
        end
        function set.IsMale(self,IsMale)
            self.set_col_value('IsMale',IsMale);
        end
        function value=get.Weight(self)
            value=self.get_col_value('Weight');
        end
        function set.Weight(self,Weight)
            self.set_col_value('Weight',Weight);
        end
        function value=get.Notes(self)
            value=self.get_col_value('Notes');
        end
        function set.Notes(self,Notes)
            self.set_col_value('Notes',Notes);
        end
        function value=get.species_type(self)
            value=self.get_col_value('species_type');
        end
        function set.species_type(self,species_type)
            self.set_col_value('species_type',species_type);
        end
        function periods=get.periods(self)
            periods=EERAT.Db_obj.get_obj_array(self.dbx,'Period','subject_id',self.subject_id,'span_type','period');
        end
        %To modify a period's subject, do so on the period object.
        function experiments=get.experiments(self)
            experiments=self.get_many_to_many('experiment_has_subject',...
                'subject_id','subject_id','experiment_id','experiment_id','Experiment');
        end
        function set.experiments(self,many)
            self.set_many_to_many(many,'experiment_has_subject',...
                'subject_id','subject_id','experiment_id','experiment_id');
        end
        function details=get.details(self)
            details=EERAT.Db_obj.get_obj_array(self.dbx,'SubjectDetail','subject_id',self.subject_id);
        end
    end
end