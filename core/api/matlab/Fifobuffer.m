classdef Fifobuffer < handle
    properties
        contents
        n_samples
        n_channels
    end
    methods
        function obj=Fifobuffer(varargin)%constructor
            if nargin == 0
            else
                buffer_metadata=varargin{1};
                obj.n_samples=buffer_metadata.n_samples;
                obj.n_channels=buffer_metadata.n_channels;
                obj.contents = nan(obj.n_samples,obj.n_channels);
            end
        end
        function add(buff,data)%data is samples x channels
            [in_samps,in_chans]=size(data);
            if in_chans < buff.n_channels
                data = [data nan(in_samps,buff.n_channels-in_chans)];
            end
            n_to_keep = buff.n_samples - in_samps;
            buff.contents = [buff.contents(end-n_to_keep:end,:);data];
        end
    end
end