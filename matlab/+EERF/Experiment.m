classdef Experiment < EERAT.Db_obj
    properties (Constant) %These are abstract in parent class
        table_name='experiment';
        key_names={'experiment_id'};
    end
    properties (Hidden = true)
        experiment_id;
    end
    properties (Dependent = true, Transient = true)
        Name;
        Description;
        subjects;
    end
    methods
        function obj = Experiment(varargin)
            obj = obj@EERAT.Db_obj(varargin{:});
        end
        function Name=get.Name(obj)
            Name=obj.get_col_value('Name');
        end
        function set.Name(obj,Name)
            obj.set_col_value('Name',Name);
        end
        function Description=get.Description(obj)
            Description=obj.get_col_value('Description');
        end
        function set.Description(obj,Description)
            obj.set_col_value('Description',Description);
        end
        function subjects=get.subjects(self)
            subjects=self.get_many_to_many('experiment_has_subject',...
                'experiment_id','experiment_id','subject_id','subject_id','Subject');
        end
        function set.subjects(self,many)
            self.set_many_to_many(many,'experiment_has_subject',...
                'experiment_id','experiment_id','subject_id','subject_id');
        end
    end
end