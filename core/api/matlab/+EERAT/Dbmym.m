classdef Dbmym < handle
    properties (Constant, Hidden)
        host='localhost';
        user='root';
        pass='';
    end
    properties (Transient)
        status
    end
    properties
        cid=-1;
    end
    properties (Hidden = true)
        db;
    end
    methods
        function obj = Dbmym(db)%constructor
            if nargin>0
                obj.db=db;
                obj.keepalive;
            else
                obj.cid=mym(-1,'open',obj.host,obj.user,obj.pass);
            end
        end
        function [mo]=statement(obj,SQL_statement,mym_parameters)
            if obj.status~=0
                obj.keepalive;
            end
            if nargin>2
                mo=mym(obj.cid,SQL_statement,mym_parameters{:});
            else
                mo=mym(obj.cid,SQL_statement);
            end
        end
        function delete(obj)
            mym(obj.cid,'close');
        end
        function keepalive(obj)
            obj.cid=mym(obj.cid,'open',obj.host,obj.user,obj.pass);
            [~]=mym(obj.cid,'use',obj.db);
        end
        function val=get.status(obj)
            val=mym(obj.cid);
        end
    end
end