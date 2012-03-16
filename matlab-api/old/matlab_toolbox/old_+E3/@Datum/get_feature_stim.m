function stim=get_feature_stim(data)
%function feature_value=get_feature_stim(data)
%argument data is an array or instance of Trial, Day, or Period object(s).
%This function retrieves the stimulus size for each trial.
%This feature is only defined for Trials

%Determine the class of data.
class_name=class(data(1));
switch class_name
    case 'E3.Trial'
        n_trials=length(data);
        stim=NaN(1,n_trials);
        ani=E3.Subject;
        ani.DB_id=data(1).subject_id;
        dbname=ani.E3Name;
        tablename=ani.DataTableName;
        global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end %#ok<*TLEV>
        for tt=1:n_trials
            mo=mym(cid,'SELECT CAST(extData AS CHAR) as extData FROM `{S}`.`{S}` WHERE seq=0 AND trial={Si} AND fragment=0',dbname,tablename,data(tt).Number);
            if ~any(size(mo.extData)==0)
                stim(tt)=str2double(regexpi(mo.extData{1},'(?<=stim1=)[\d*\.*\d* ]*','match'));
            else
                stim(tt)=NaN;
            end
            if mod(tt,20000)==0
                fprintf('\n');
            elseif mod(tt,400)==0
                fprintf('.');
            end
        end
        %mym(cid,'close');
    case {'E3.Period','E3.Day'}
        warning('Stim not defined for days or periods') %#ok<*WNTAG>
        stim=[];
end