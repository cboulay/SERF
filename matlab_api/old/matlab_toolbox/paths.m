%paths_and_parms
addpath('mym');
addpath('mem');
addpath('gui');
%addpath('+E3');

% %If it is accessed because it is already on the path, then we need to
% %determine the root directory from the path.
% p=path;
% pos_tools=strfind(p,'tools');
% if any(pos_tools<100)
%     pos_seps=strfind(p,':');
%     pos_seps=[0 pos_seps];
%     pos_sep=pos_seps(pos_seps<pos_tools(1));
%     pos_sep=pos_sep(end);
%     root_path=p(pos_sep+1:pos_tools(1)+5);
% else
%     %if this file is accessed from within the directory, then we can determine
%     %the root path based on pwd
%     currdir=pwd;
%     pos=strfind(currdir,'tools');
%     root_path=currdir(1:pos(1)+5);
% end
% 
% temp_path=[root_path,'elizan_tools'];
% if exist(temp_path,'dir')
%     P=genpath(temp_path);
%     addpath(P);
%     import E3.*
% end
% 
% temp_path=[root_path,'chronux',filesep,'spectral_analysis'];
% if exist(temp_path,'dir')
%     P=genpath(temp_path);
%     addpath(P);
% end
% 
% temp_path=[root_path,'lsq'];
% if exist(temp_path,'dir')
%     P=genpath(temp_path);
%     addpath(P);
% end
% 
% temp_path=[root_path,'mem'];
% if exist(temp_path,'dir')
%     P=genpath(temp_path);
%     addpath(P);
% end
% 
% temp_path=[root_path,'mym'];
% if exist(temp_path,'dir')
% %     P=genpath(temp_path);
%     addpath(temp_path);
%     %For mym to work in osx, we also need to copy the mysql dylib file to a
%     %directory that already exists in getenv('DYLD_LIBRARY_PATH')
% end
% 
% clear P currdir pos root_path temp_path pos_* p