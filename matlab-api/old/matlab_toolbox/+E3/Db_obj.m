classdef Db_obj < handle
    %This is a super class for most of the classes that
    %persist in the database.
    properties (Abstract, Constant)
        table_name; %The name of the table in the e3analysis database.
        key_names; %A cell array of key names.
    end
    properties
        e3dbx; %The db connection object through which an object accesses its data.
    end
    methods (Static)
        function array=get_obj_array(e3dbx,class_name)
            tn=E3.(class_name).table_name;
            kns=E3.(class_name).key_names;
            SQL_statement='SELECT';
            for kk=1:length(kns)
                if kk>1
                    SQL_statement=[SQL_statement,',']; %#ok<*AGROW>
                end
                SQL_statement=[SQL_statement,' ',kns{kk}];
            end
            SQL_statement=[SQL_statement,' FROM `{S}`'];
            mo=statement(e3dbx,SQL_statement,{tn});
            n_objs=length(mo.(kns{1}));%The number of returned objects.
            if n_objs>0
                %Create an array of objects. Note that some object types
                %might have multiple keys. Here we only set the object's
                %key values. Once the object has its keys, any further gets
                %or sets to its other values will be handled by its own
                %class, not this super class.
                array(n_objs)=E3.(class_name);
                n_cols=length(kns);
                for oo=1:n_objs
                    array(oo).e3dbx=e3dbx;
                    for cc=1:n_cols
                        array(oo).(kns{cc})=mo.(kns{cc}){oo};
                    end
                end
            else
                array=[];
            end
        end
    end
    methods
        function obj=Db_obj(key_value_pairs,e3dbx)
            SQL_statement='INSERT IGNORE INTO `{S}`';
            arg_array={obj.table_name};
            if nargin<2
                e3dbx=E3.Dbmym('e3analysis');
            end
            if nargin==0 || length(key_value_pairs)<2 || isempty(key_value_pairs{2})
            else
                col_string=[]; col_args=[];
                val_string=[]; val_args=[];
                for kk=1:length(obj.key_names)
                    key_ind=find(strcmp(key_value_pairs,obj.key_names{kk}));
                    kn=key_value_pairs{key_ind};
                    kv=key_value_pairs{key_ind+1};
                    if kk>1
                        col_string=[col_string,', '];
                        val_string=[val_string,', '];
                    else
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
                    end
                    col_args=[col_args,{kn}];
                    val_args=[val_args,{kv}];
                end
                SQL_statement=[SQL_statement,' (',col_string,') VALUES (',val_string,')'];
                arg_array=[arg_array,col_args,val_args];
            end
            this_obj.e3dbx=e3dbx;
            [~]=statement(this_obj.e3dbx,SQL_statement,arg_array);
        end
        function remove_from_db(obj)
            for oo=1:length(obj)
                this_obj=obj(oo);
                SQL_statement='DELETE FROM `{S}` WHERE';
                arg_array={this_obj.table_name};
                for kk=1:length(this_obj.key_names)
                    if kk>1
                        SQL_statement=[SQL_statement,' AND'];
                    end
                    if ischar(this_obj.(this_obj.key_names{kk}))
                        SQL_statement=[SQL_statement,' {S} LIKE "{S}"'];
                    else
                        SQL_statement=[SQL_statement,' {S}={Si}'];
                    end
                    arg_array=[arg_array,this_obj.key_names(kk),{this_obj.(this_obj.key_names{kk})}];
                end
                [~]=statement(this_obj.e3dbx,SQL_statement,arg_array);
            end
        end
        function value=get_col_value(obj,col_name)
            SQL_statement='SELECT {S} FROM `{S}` WHERE';
            arg_array=[{col_name},{obj.table_name}];
            for kk=1:length(obj.key_names)
                if kk>1
                    SQL_statement=[SQL_statement,' AND'];
                end
                if ischar(obj.(obj.key_names{kk}))
                    SQL_statement=[SQL_statement,' {S} LIKE "{S}"'];
                else
                    SQL_statement=[SQL_statement,' {S}={Si}'];
                end
                arg_array=[arg_array,obj.key_names(kk),{obj.(obj.key_names{kk})}];
            end
            mo=statement(obj.e3dbx,SQL_statement,arg_array);
            if ~isempty(mo.(col_name))
                value=mo.(col_name){1};
            else
                value=[];
            end
        end
        function set_col_value(obj,col_name,col_value)
            SQL_statement='UPDATE `{S}` SET {S}=';
            if isnumeric(col_value)
                if mod(col_value,1)==0
                    SQL_statement=[SQL_statement,'{Si} WHERE'];
                else
                    SQL_statement=[SQL_statement,'{S4} WHERE'];
                end
            else
                SQL_statement=[SQL_statement,'"{S}" WHERE'];
            end
            arg_array=[{obj.table_name},{col_name},{col_value}];
            for kk=1:length(obj.key_names)
                if kk>1
                    SQL_statement=[SQL_statement,' AND'];
                end
                if ischar(obj.(obj.key_names{kk}))
                    SQL_statement=[SQL_statement,' {S} LIKE "{S}"'];
                else
                    SQL_statement=[SQL_statement,' {S}={Si}'];
                end
                arg_array=[arg_array,obj.key_names(kk),{obj.(obj.key_names{kk})}];
            end
            [~]=statement(obj.e3dbx,SQL_statement,arg_array);
        end
    end
end