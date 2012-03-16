function dbnames=get_db_names
global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end
mo=mym(cid,'SHOW DATABASES');
%mym(cid,'close');
dbnames=mo.Database;
dbnames(strcmpi(dbnames,'analysisdb'))=[];
dbnames(strcmpi(dbnames,'information_schema'))=[];
dbnames(strcmpi(dbnames,'e3analysis'))=[];
dbnames(strcmpi(dbnames,'global'))=[];
dbnames(strcmpi(dbnames,'mysql'))=[];
dbnames(strcmpi(dbnames,'performance_schema'))=[];
dbnames(strcmpi(dbnames,'test'))=[];
