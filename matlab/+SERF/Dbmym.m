classdef Dbmym < handle
    properties (Constant, Hidden)
        host = 'localhost';
        user = 'root';
        pass = '';
    end
    properties (Transient)
        status
    end
    properties
        cid = -1;
    end
    properties (Hidden = true)
        db; %TODO: Setting this should call obj.keepalive.
    end
    methods
        function obj = Dbmym(db)%constructor
            if nargin > 0
                obj.db = db;
                keepalive(obj);
            else
                obj.cid = mym(-1, 'open', obj.host, obj.user, obj.pass);
            end
        end
        function [mo] = statement(obj, SQL_statement, mym_parameters)
%             if obj.status~=0 %This probably slows things down. Maybe I should do a try/catch instead.
%                 obj.keepalive;
%             end
            repeat = true;
            while repeat
                if nargin>2
                    try
                        repeat = false;
                        mo = mym(obj.cid, SQL_statement, mym_parameters{:});
                    catch err
                        if strcmpi(err.message,'Not connected')
                            obj.keepalive;
                            repeat = true(1,1);
                        else
                            rethrow(err);
                        end
                    end
                else
                    try
                        repeat = false;
                        mo = mym(obj.cid, SQL_statement);                        
                    catch err
                        if strcmpi(err.message,'Not connected')
                            keepalive(obj);
                            repeat = true;
                        else
                            rethrow(err);
                        end
                    end
                end
            end
        end
        function delete(obj)
            mym(obj.cid,'close');
        end
        function keepalive(obj)
            obj.cid = mym(obj.cid,'open',obj.host,obj.user,obj.pass);
            [~] = mym(obj.cid,'use',obj.db);
        end
        function val = get.status(obj)
            val = mym(obj.cid);
        end
    end
end