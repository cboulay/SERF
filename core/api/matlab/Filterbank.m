classdef Filterbank < handle
    properties
        order = 4;
        freq_edges = [(8:2:26)' (10:2:28)'];
        fs
        filters
    end
    methods
        function obj=Filterbank(varargin)%constructor
            if nargin == 0
            else
                filter_metadata=varargin{1};
                obj.fs = filter_metadata.fs;
                if isfield(filter_metadata,'order')
                    obj.order = filter_metadata.order;
                end
                if isfield(filter_metadata,'freq_edges')
                    obj.freq_edges = filter_metadata.freq_edges;
                end
                %Prepare the bank of filters
                for ff=1:size(obj.freq_edges,1)
                    %freq_win = [obj.freq_edges(ff,1) obj.freq_edges(ff,2)];
                    %fnorm = [x y]/(z/2)
                    %fnorm = freq_win/(obj.fs/2);
                    fnorm=obj.freq_edges(ff,:)/(obj.fs/2);
                    [obj.filters(ff).b,obj.filters(ff).a] = butter(obj.order,fnorm);
                end
            end
            
        end
        function filtered_signal = process(fbank,signal)
            [n_samps,n_chans]=size(signal);
            n_filts = length(fbank.filters);
            filtered_signal = NaN(n_samps,n_chans,n_filts);
            for ff=1:n_filts
                b = fbank.filters(ff).b;
                a = fbank.filters(ff).a;
                filtered_signal(:,:,ff) = filter(b,a,signal);
                %test_signal = rand(1,6000) + 2*sin(10*2*pi*(1/600:1/600:10));
                %filtered_signal(:,:,ff) = filter(b,a,test_signal);
            end
        end
    end
end