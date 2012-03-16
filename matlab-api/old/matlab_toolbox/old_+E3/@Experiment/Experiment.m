classdef Experiment < E3.Named_db_object
    properties (Dependent = true)
        Subjects
        Analyses
    end
    properties (Transient = true, Hidden=true, Constant = true)
        table_name = 'experiment';
    end
    methods
        function obj = Experiment(name)
            %constructor
            if nargin>0
                obj.Name=name;
            end
        end
    end
    methods (Static = true)
        function array=get_obj_array
            array=get_obj_array@E3.Named_db_object('Experiment');
        end
    end
    methods
        function anis=get.Subjects(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT subject_id FROM `e3analysis`.`experiment_has_subject` WHERE experiment_id={Si}',obj.DB_id);
            %mym(cid,'close');
            if ~isempty(mo.subject_id)
                n_anis=length(mo.subject_id);
                anis(n_anis)=E3.Subject;
                for aa=1:n_anis
                    anis(aa).DB_id=mo.subject_id(aa);
                end
            else
                anis=[];
            end 
        end
        function set.Subjects(obj,anis)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT subject_id FROM `e3analysis`.`experiment_has_subject` WHERE experiment_id={Si}',obj.DB_id);
            prev_ani_ids=mo.subject_id;
            curr_ani_ids=[anis.DB_id];
            [c,ia,ib]=setxor(prev_ani_ids,curr_ani_ids); %#ok<ASGLU>
            for aa=1:length(ia)
                mym(cid,'DELETE FROM `e3analysis`.`experiment_has_subject` WHERE experiment_id={Si} AND subject_id={Si}',obj.DB_id,prev_ani_ids(ia(aa)));
            end
            for aa=1:length(ib)
                mym(cid,'INSERT INTO `e3analysis`.`experiment_has_subject` (experiment_id,subject_id) VALUES ({Si},{Si})',obj.DB_id,curr_ani_ids(ib(aa)));
            end
            %mym(cid,'close');
        end
        function analyses=get.Analyses(obj)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT analysis_id FROM `e3analysis`.`experiment_has_analysis` WHERE experiment_id={Si}',obj.DB_id);
            %mym(cid,'close');
            if ~isempty(mo.analysis_id)
                n_analyses=length(mo.analysis_id);
                analyses(n_analyses)=E3.Analysis;
                for aa=1:n_analyses
                    analyses(aa).DB_id=mo.analysis_id(aa);
                end
            else
                analyses=[];
            end 
        end
        function set.Analyses(obj,anas)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT analysis_id FROM `e3analysis`.`experiment_has_analysis` WHERE experiment_id={Si}',obj.DB_id);
            prev_ana_ids=mo.analysis_id;
            curr_ana_ids=[anas.DB_id];
            [c,ia,ib]=setxor(prev_ana_ids,curr_ana_ids); %#ok<ASGLU>
            for aa=1:length(ia)
                mym(cid,'DELETE FROM `e3analysis`.`experiment_has_analysis` WHERE experiment_id={Si} AND analysis_id={Si}',obj.DB_id,prev_ana_ids(ia(aa)));
            end
            for aa=1:length(ib)
                mym(cid,'INSERT INTO `e3analysis`.`experiment_has_analysis` (experiment_id,analysis_id) VALUES ({Si},{Si})',obj.DB_id,curr_ana_ids(ib(aa)));
            end
            %mym(cid,'close');
        end
        
        function run_analysis(experiment,analyses)
            for aa=1:length(analyses)
                analysis=analyses(aa);
                if ~isempty(analysis.FunctionName)
                    fh = str2func(analysis.FunctionName);
                    fh(experiment);
                end
            end
        end
        
        %!---------------------------------------------------------------
        bins_over_days(experiment);
    end
end