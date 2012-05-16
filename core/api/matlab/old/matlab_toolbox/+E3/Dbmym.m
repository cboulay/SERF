classdef Dbmym < handle
    properties (Constant, Hidden)
        e3anahost='localhost';
        e3anauser='e3ana';
        e3anapass='e3ana';
    end
%     properties (Transient)
%         db
%     end
    properties
        cid=-1;
    end
    methods
        function obj = Dbmym(db)%constructor
            if nargin>0
                obj.cid=mym(-1,'open',obj.e3anahost,obj.e3anauser,obj.e3anapass);
                [~]=mym(obj.cid,'use',db);
            else
                obj.cid=mym(-1,'open',obj.e3anahost,obj.e3anauser,obj.e3anapass);
            end
        end
        function [mo]=statement(obj,SQL_statement,mym_parameters)
            if nargin>2
                mo=mym(obj.cid,SQL_statement,mym_parameters{:});
            else
                mo=mym(obj.cid,SQL_statement);
            end
        end
        function delete(obj)
            mym(obj.cid,'close');
        end
    end
end