classdef Named_db_object < handle
    properties (Dependent = true)
        Name
    end
    properties (Transient = true, Hidden = true)
        DB_id
    end
    properties (Abstract = true, Constant = true, Hidden=true)
        table_name
    end
    methods
        function name=get.Name(obj)
            if ~isempty(obj.DB_id)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end %#ok<*TLEV>
                mo=mym(cid,'SELECT Name FROM `e3analysis`.`{S}` WHERE id={Si}',obj.table_name,obj.DB_id);
                %mym(cid,'close');
                name=mo.Name{1};
            end
        end
        function set.Name(obj,name)
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            if ~isempty(obj.DB_id)
                %If we are given the obj.DB_id, update the name.
                mym(cid,'UPDATE `e3analysis`.`{S}` SET Name="{S}" WHERE id={Si}',obj.table_name,name,obj.DB_id);
            else
                %We don't know the object id, but we have a name. First
                %search to see if the name exists.
                mo=mym(cid,'SELECT id FROM `e3analysis`.`{S}` WHERE Name LIKE "{S}"',obj.table_name,name);
                if ~isempty(mo.id)
                    %If the id exists, add it to the object and proceed.
                    obj.DB_id=mo.id(1);
                else
                    %If the id does not exist, add a new entry into the database.
                    mym(cid,'INSERT INTO `e3analysis`.`{S}` (Name) VALUES("{S}")',obj.table_name,name);
                    mo=mym(cid,'SELECT LAST_INSERT_ID() as id');
                    obj.DB_id=mo.id(1);
                end
            end
            %mym(cid,'close');
        end
        function remove_from_db(obj)
            for oo=1:length(obj)
                this_obj=obj(oo);
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                mymOutput=mym(cid,'DELETE FROM `e3analysis`.`{S}` WHERE id={Si}',this_obj.table_name,this_obj.DB_id);
                %mym(cid,'close');
            end
        end
    end
    methods (Static)
        function array=get_obj_array(class_name)
            tn=E3.(class_name).table_name;
            global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
            mo=mym(cid,'SELECT id,Name FROM `e3analysis`.`{S}`',tn);
            %mym(cid,'close');
            if ~isempty(mo.id)
                array(length(mo.id))=E3.(class_name);
                for aa=1:length(mo.id)
                    array(aa).DB_id=mo.id(aa);
                    array(aa).Name=mo.Name{aa};
                end
            else
                array=[];
                %The only way a new named db object (adt, pt, ft, analysis)
                %can be created is with a GUI. Be sure to set DB_id and
                %Name before setting any other properties (ft and analysis)
            end
        end
    end
end