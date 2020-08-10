classdef GenericDetail < EERF.Db_obj
    %Parent of SubjectDetail and DatumDetail
    properties (Hidden=true)
        detail_type_id;
    end
    properties (Dependent=true)
        Value;
        Name; %Read-only
        Description; %Read-only
        DefaultValue; %Read-only
        detail_type;
    end
    methods
        function obj = GenericDetail(varargin)
            obj = obj@EERF.Db_obj(varargin{:});
        end
        function value=get.Value(detail)
            value=detail.get_col_value('Value');
        end
        function set.Value(detail,value)
            detail.set_col_value('Value',value);
        end
        function Name=get.Name(self)
            stmnt = ['SELECT Name FROM detail_type WHERE detail_type_id=',num2str(self.detail_type_id)];
            mo=self.dbx.statement(stmnt);
            Name=mo.Name{1};
        end
        function Description=get.Description(self)
            stmnt = ['SELECT Description FROM detail_type WHERE detail_type_id=',num2str(self.detail_type_id)];
            mo=self.dbx.statement(stmnt);
            Description=mo.Description{1};
        end
        function DefaultValue=get.DefaultValue(self)
            stmnt = ['SELECT DefaultValue FROM detail_type WHERE detail_type_id=',num2str(self.detail_type_id)];
            mo=self.dbx.statement(stmnt);
            DefaultValue=mo.DefaultValue{1};
        end
        function detail_type=get.detail_type(self)
            detail_type=self.get_x_to_one('detail_type_id',...
                'DetailType','detail_type_id');
        end
    end
end