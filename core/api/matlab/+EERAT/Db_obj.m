classdef Db_obj < handle
    %This is a super class for most of the classes that
    %persist in the database.
    properties (Abstract, Constant, Hidden)
        table_name; %The name of the table in the EERAT database.
        key_names; %A cell array of key names.
    end
    properties
        dbx; %The db connection object through which an object accesses its data.
    end
    methods (Static)
        function array=get_obj_array(this_dbx,class_name,varargin) %Get an array of objects, possibly using kvps to search
            kns=EERAT.(class_name).key_names;
            select_string='SELECT ';
            for kk=1:length(kns)
                if kk>1
                    select_string=[select_string,', ']; %#ok<*AGROW>
                end
                select_string=[select_string,kns{kk}];
            end
            SQL_statement=[select_string,' FROM ',EERAT.(class_name).table_name];
            if ~isempty(varargin)
                kvps=varargin;
                [where_stmnt,where_args]=EERAT.Db_obj.build_search_where(kvps);
                SQL_statement=[SQL_statement,where_stmnt,' ORDER BY ',kns{1},' ASC'];
                mo=this_dbx.statement(SQL_statement,where_args);
            else
                mo=this_dbx.statement(SQL_statement);
            end
            n_objs=length(mo.(kns{1}));%The number of returned objects.
            if n_objs>0
                %Create an array of objects. Note that some object types
                %might have multiple keys. Here we only set the object's
                %key values. Once the object has its keys, any further gets
                %or sets to its other values will be handled by its own
                %class, not this super class.
                %Initialize the array with the correct class.
                array(n_objs)=EERAT.(class_name);
                for oo=1:n_objs
                    %build kvps for each object
                    kvps=[];
                    for kk=1:length(kns)
                        kvps=[kvps,kns(kk),mo.(kns{kk})(oo)];
                    end
                    obj_args=[{this_dbx},kvps];
                    array(oo)=EERAT.(class_name)(obj_args{:});
                end
            else
                array=[];
            end
        end
        function [SQL_statement,arg_array]=build_search_where(kvps) %Builds the WHERE part of an SQL statement when searching based on kvps
            SQL_statement=' WHERE ';
            arg_array=[];
            for kk=1:length(kvps)/2
                kn=kvps{2*kk-1};
                kv=kvps{2*kk};
                if kk>1
                    SQL_statement=[SQL_statement, ' AND '];
                end
                SQL_statement=[SQL_statement, '{S}'];
                arg_array=[arg_array, {kn}];
                if isnumeric(kv)
                    if mod(kv,1)==0
                        SQL_statement=[SQL_statement,'={Si}'];
                    else
                        SQL_statement=[SQL_statement,'={S4}'];
                    end
                else
                    SQL_statement=[SQL_statement,' LIKE "{S}"'];
                end
                arg_array=[arg_array, {kv}];
            end
        end
    end
    methods
        function select_string=build_key_selection(obj)
            select_string='SELECT ';
            for kk=1:length(obj.key_names)
                if kk>1
                    select_string=[select_string,', '];
                end
                select_string=[select_string,obj.key_names{kk}];
            end
            select_string=[select_string,' FROM ',obj.table_name];
        end
        function [SQL_statement,arg_array]=build_identifying_where(obj)
            SQL_statement=' WHERE ';
            arg_array=[];
            for kk=1:length(obj.key_names)
                kn=obj.key_names{kk};
                kv=obj.(kn);
                if kk>1
                    SQL_statement=[SQL_statement,' AND '];
                end
                SQL_statement=[SQL_statement, '{S}'];
                arg_array=[arg_array,{kn}];
                if isnumeric(kv)
                    if mod(kv,1)==0
                        SQL_statement=[SQL_statement,'={Si}'];
                    else
                        SQL_statement=[SQL_statement,'={S4}'];
                    end
                else
                    SQL_statement=[SQL_statement,' LIKE "{S}"'];
                end
                arg_array=[arg_array,{kv}];
            end
        end
        function obj=Db_obj(varargin) %Constructor
            if nargin>0 && strcmpi(class(varargin{1}),'EERAT.Dbmym')
                this_dbx=varargin{1};
            else
                this_dbx=EERAT.Dbmym('EERAT');
            end
            if nargin>1%length(varargin)>=2
                key_value_pairs=varargin(2:end);
                if strcmpi(key_value_pairs{1},'new')
                    do_new=key_value_pairs{2};
                    key_value_pairs=key_value_pairs(3:end);
                else
                    do_new=false;
                end
            else
                key_value_pairs={};
                do_new=false;
            end
            %Constructor.
            obj.dbx=this_dbx;
            %Get or Create
            %If we provided keys, then probe the database for this object.
            if length(key_value_pairs)>1 && mod(length(key_value_pairs),2)==0 && ~isempty(key_value_pairs{2})
                SQL_statement=obj.build_key_selection;
                [where_stmnt,where_args]=EERAT.Db_obj.build_search_where(key_value_pairs);
                SQL_statement=[SQL_statement, where_stmnt];
                mo=this_dbx.statement(SQL_statement,where_args);
                if ~do_new && length(mo.(obj.key_names{1}))==1 %We found exactly one entry matching these criteria.
                    for kk=1:length(obj.key_names)
                        val=mo.(obj.key_names{kk});
                        if iscell(val)
                            val=val{:};
                        end
                        obj.(obj.key_names{kk})=val;
                    end
                    return; %We are done.
                elseif ~do_new && length(mo.(obj.key_names{1}))>1
                    error('Multiple results found. Use EERAT.get_obj_array instead.');
                elseif do_new || isempty(mo.(obj.key_names{1}))
                    %kvps were provided but we did not find the object in the
                    %database, thus we should create it.
                    SQL_statement='INSERT IGNORE INTO `{S}`';
                    arg_array={obj.table_name};
                    col_string=[]; col_args=[];
                    val_string=[]; val_args=[];
                    for kk=1:length(key_value_pairs)/2
                        kn=key_value_pairs{2*kk-1};
                        kv=key_value_pairs{2*kk};
                        if kk>1
                            col_string=[col_string,', '];
                            val_string=[val_string,', '];
                        end
                        col_string=[col_string,'{S}'];
                        if isnumeric(kv)
                            if mod(kv,1)==0
                                val_string=[val_string,'{Si}'];
                            else
                                val_string=[val_string,'{S4}'];
                            end
                        else
                            val_string=[val_string,'"{S}"'];
                        end
                        col_args=[col_args,{kn}];
                        val_args=[val_args,{kv}];
                    end
                    SQL_statement=[SQL_statement,' (',col_string,') VALUES (',val_string,')'];
                    arg_array=[arg_array,col_args,val_args];
                    [~]=this_dbx.statement(SQL_statement,arg_array);
                    mo=this_dbx.statement('SELECT LAST_INSERT_ID()');
                    obj.(obj.key_names{1})=mo.('LAST_INSERT_ID()');
%                     %Now search the database again to obtain any PKs that may have
%                     %been created. This might return more than one result.
%                     SQL_statement=obj.build_key_selection;
%                     [where_stmnt,where_args]=EERAT.Db_obj.build_search_where(key_value_pairs);
%                     mo=statement(this_dbx,[SQL_statement,where_stmnt],where_args);
%                     for kk=1:length(obj.key_names)
%                         val=mo.(obj.key_names{kk});
%                         if iscell(val)
%                             val=val{:};
%                         end
%                         obj.(obj.key_names{kk})=val;
%                     end
                end
            else %if kvps were not provided, then we cannot search.
                return;
            end
        end
        function remove_from_db(obj) %Only way to delete an object.
            for oo=1:length(obj)
                this_obj=obj(oo);
                SQL_statement='DELETE FROM `{S}`';
                arg_array={this_obj.table_name};
                [where_stmnt,where_args]=obj.build_identifying_where(key_value_pairs);
                [~]=statement(this_obj.dbx,[SQL_statement,where_stmnt],[arg_array,where_args]);
            end
        end
        function value=get_col_value(obj,col_name) %Single attribute retrieval
            %Does not handle joins thus not useful for getting
            %datum_feature_value or datum_detail_value.
            SQL_statement='SELECT {S} FROM `{S}`';
            arg_array=[{col_name},{obj.table_name}];
            [where_stmnt,where_args]=obj.build_identifying_where;
            mo=statement(obj.dbx,[SQL_statement,where_stmnt],[arg_array,where_args]);
            if ~isempty(mo.(col_name))
                if iscell(mo.(col_name))
                    value=mo.(col_name){1};
                else
                    value=mo.(col_name)(1);
                end
            else
                value=[];
            end
        end
        function set_col_value(obj,col_name,col_value) %Single attribute save
            SQL_statement='UPDATE `{S}` SET {S}=';
            if isnumeric(col_value)
                if ~isnan(col_value)
                    SQL_statement=[SQL_statement,'{S}'];
                    col_value='NULL';
                elseif mod(col_value,1)==0
                    SQL_statement=[SQL_statement,'{Si}'];
                else
                    SQL_statement=[SQL_statement,'{S4}'];
                end
            else
                SQL_statement=[SQL_statement,'"{S}"'];
            end
            arg_array=[{obj.table_name},{col_name},{col_value}];
            [where_stmnt,where_args]=obj.build_identifying_where;
            [~]=statement(obj.dbx,[SQL_statement,where_stmnt],[arg_array,where_args]);
        end
        function one=get_x_to_one(self,one_key_in_self,one_class_name,one_key_in_class)
            stmnt='SELECT {S} FROM {S} WHERE ';
            arguments={one_key_in_self,self.table_name};
            for kk=1:length(self.key_names)
                if kk>1
                    stmnt=[stmnt,' AND '];
                end
                stmnt=[stmnt,'{S}={Si}'];
                arguments=[arguments,self.key_names(kk),self.(self.key_names{kk})];
            end
            mo=self.dbx.statement(stmnt,arguments);
            if length(mo.(one_key_in_self))==1
                one=EERAT.(one_class_name)(self.dbx,one_key_in_class,mo.(one_key_in_self)(1));
            else
                one='Not exactly 1 result returned in x-to-one relationship';
            end
        end
        function set_x_to_one(self,one,one_key_in_self,one_key_in_class)
            stmnt='UPDATE {S} SET {S}={Si} WHERE ';
            arguments={self.table_name,one_key_in_self,one.(one_key_in_class)};
            for kk=1:length(self.key_names)
                if kk>1
                    stmnt=[stmnt,' AND '];
                end
                stmnt=[stmnt,'{S}={Si}'];
                arguments=[arguments,self.key_names(kk),self.(self.key_names{kk})];
            end
            self.dbx.statement(stmnt,arguments);
        end
        function many=get_many_to_many(self,assoc_table,self_key_in_assoc,self_key_in_class,many_key_in_assoc,many_key_in_class,many_class)
            stmnt='SELECT {S} FROM {S} WHERE {S}={Si} ORDER BY {S} ASC';
            mo=self.dbx.statement(stmnt,{many_key_in_assoc,assoc_table,...
                self_key_in_assoc,self.(self_key_in_class),many_key_in_assoc});
            n_result=length(mo.(many_key_in_assoc));
            if n_result>0
                many(n_result)=EERAT.(many_class);
                for mm=1:n_result
                    many(mm)=EERAT.(many_class)(self.dbx,many_key_in_class,mo.(many_key_in_assoc)(mm));
                end
            else
                many=[];
            end
        end
        function set_many_to_many(self,many,assoc_table,self_key_in_assoc,self_key_in_class,many_key_in_assoc,many_key_in_class)
            stmnt='INSERT IGNORE INTO {S} ({S},{S}) VALUES ({Si},{Si})';
            for mm=1:length(many)
                self.dbx.statement(stmnt,{assoc_table,self_key_in_assoc,many_key_in_assoc,...
                    self.(self_key_in_class),many(mm).(many_key_in_class)});
            end
        end
        %get_one_to_many not necessary. Use EERAT.Db_obj.get_obj_array
        %set_one_to_many doesn't make sense. Should be done on the many
    end
end