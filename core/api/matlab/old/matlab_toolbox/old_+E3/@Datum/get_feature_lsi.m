function feature_value=get_feature_lsi(data)
%function feature_value=get_feature_lsi(data)
%argument data is an array or instance of Trial, Day, or Period object(s).

%This function calculates the time since the last stimulus.
%This feature is only defined for Trials
%Determine the class of data.
class_name=class(data(1));
switch class_name
    case 'E3.Trial'
        n_trials=length(data);
        feature_value=NaN(1,n_trials);
        t_times=datenum(data.get_times)*60*60*24;
        %Get the subject object these data belong to.
        ani=E3.Subject;
        ani.DB_id=data(1).subject_id;
        dbname=ani.E3Name;
        ad_id=find(strcmp({ani.SubjectDetails.Name},'stim_db_name'));
        if any(ad_id)
            fprintf('Calculating trials'' times since last stimulus. This takes a while.\n');
            stimdbname=ani.SubjectDetails(ad_id).Value;
            if strcmp(stimdbname,dbname) %stim db is trial db
                s_times=t_times;
            else
                global cid;if isempty(cid);cid=mym(-1,'open', 'localhost', 'root');end %#ok<*TLEV>
                mo=mym(cid,'SHOW TABLES from `{S}`',stimdbname);
                fnames=fieldnames(mo);
                tnames=mo.(fnames{1});
                isdata=false(length(tnames),1);
                for tt=1:length(tnames)
                    isdata(tt)=any(strfind(tnames{tt},'data'));
                end
                stimtablename=tnames{isdata};
                mo=mym(cid,'SELECT time FROM `{S}`.`{S}` WHERE seq=0 AND fragment=1',stimdbname,stimtablename);
                s_times=mo.time;
            end
            for tt=1:length(t_times)
                temp_s_times=s_times(s_times<t_times(tt));
                if isempty(temp_s_times)
                    feature_value(tt)=999;
                else
                    feature_value(tt)=t_times(tt)-max(temp_s_times);
                end
            end
        else
            warning('No stimulus database selected.') %#ok<*WNTAG>
        end
    case {'E3.Period','E3.Day'}
        warning('Flats not defined for days or periods') %#ok<*WNTAG>
end