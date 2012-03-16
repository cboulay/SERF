classdef Function_db_object < E3.Named_db_object
    properties (Transient)
        Description
        FunctionName
    end
    methods
        function value=get.Description(obj)
            if ~isempty(obj.DB_id) && ~isempty(obj.Name)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end %#ok<*TLEV>
                mo=mym(cid,'SELECT CAST(Description AS CHAR) as Description FROM `e3analysis`.`{S}` WHERE id={Si} AND Name LIKE "{S}"',obj.table_name,obj.DB_id,obj.Name);
                if ~isempty(mo.Description)
                    value=mo.Description{1};
                end
                %mym(cid,'close');
            end
        end
        function set.Description(obj,value)
            if ~isempty(obj.DB_id) && ~isempty(obj.Name)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                ss=['INSERT INTO `e3analysis`.`{S}` (id,Name,Description) VALUES ({Si},"{S}","{S}")',...
                    ' ON DUPLICATE KEY UPDATE Description=VALUES(Description)'];
                mym(cid,ss,obj.table_name,obj.DB_id,obj.Name,value);
                %mym(cid,'close');
            end
        end
        function value=get.FunctionName(obj)
            if ~isempty(obj.DB_id) && ~isempty(obj.Name)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                mo=mym(cid,'SELECT FunctionName FROM `e3analysis`.`{S}` WHERE id={Si} AND Name LIKE "{S}"',obj.table_name,obj.DB_id,obj.Name);
                if ~isempty(mo.FunctionName)
                    value=mo.FunctionName{1};
                end
                %mym(cid,'close');
            end
        end
        function set.FunctionName(obj,value)
            if ~isempty(obj.DB_id) && ~isempty(obj.Name)
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
                ss=['INSERT INTO `e3analysis`.`{S}` (id,Name,FunctionName) VALUES ({Si},"{S}","{S}")',...
                    ' ON DUPLICATE KEY UPDATE FunctionName=VALUES(FunctionName)'];
                mym(cid,ss,obj.table_name,obj.DB_id,obj.Name,value);
                %mym(cid,'close');
            end
        end
    end
end