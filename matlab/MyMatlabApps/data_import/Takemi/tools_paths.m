temp.currdir = pwd;
if ispc
    temp.root = temp.currdir(1:3);
else
    temp.root = filesep;
end
addpath(fullfile(temp.root,'BCI2000','tools','mex'));
addpath(fullfile(temp.root,'BCI2000','tools','matlab'));
addpath(fullfile(temp.root,'BCI2000','tools','OfflineAnalysis'));
addpath(genpath(fullfile(temp.root,'Tools','chronux')));
addpath(fullfile(temp.root,'Tools','mym'));
addpath(fullfile(temp.root,'Tools','EERAT','core','api','matlab'));
clear temp