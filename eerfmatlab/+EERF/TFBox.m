classdef TFBox < handle
    %This is a black-box to process data and return the timefrequency
    %transform of that data. Change some of the constant properties if you
    %would like to change how the blackbox functions.
    properties (Constant = true)
        ft_type = 'fft'; %'fft', 'filterbank' (hilbert), 'mem'
        freq_edges_hz = [[(3:3:45) 1]' [(6:3:48) 5]'];
        win_sec = 1;
        win_step_sec = 1/8;
    end
    methods (Static = true)
        function [tf_amp,varargout] = process(temp_dat,varargin)
            %Static function to take data input (and possibly a time
            %vector) and return the time-frequency representation.
            %temp_dat is samples x channels.
            %tf_amp is steps x channels x freqs.
            [n_samps, n_chans] = size(temp_dat);
            if nargin>1
                tvec = varargin{1};
            else
                tvec = 1/1000:1/1000:n_samps/1000; %Assume 1kHz if no tvec provided.
            end
            if nargin>2
                tfparms = varargin{2};
            else
                tfparms.ft_type = EERF.TFBox.ft_type;
                tfparms.freq_edges_hz = EERF.TFBox.freq_edges_hz;
                tfparms.win_sec = EERF.TFBox.win_sec;
                tfparms.win_step_sec = EERF.TFBox.win_step_sec;
            end
            
            %Prepare the analysis.
            n_freqs = size(tfparms.freq_edges_hz,1);
            fs = 1/mean(diff(tvec));
            n_samps_per_win = ceil(tfparms.win_sec * fs);
            n_samps_per_step = ceil(tfparms.win_step_sec * fs);
            step_starts = 1 : n_samps_per_step : n_samps - n_samps_per_win + 1;
            last_step_start = n_samps - n_samps_per_win + 1;
            do_extra_block = step_starts(end) ~= last_step_start;
            if do_extra_block
                step_starts = [step_starts last_step_start];
            end
            n_steps = length(step_starts);
            
            %reindex the data into its windows.
            reindex_col = (0:1:n_samps_per_win-1)';%The window.
            reindex_chans = shiftdim(0:n_samps:n_samps*n_chans-1,-1);
            reindex = bsxfun(@plus,bsxfun(@plus,step_starts,reindex_col),reindex_chans);

            if strcmpi(tfparms.ft_type,'filterbank')
                if ~isfield(tfparms,'filterbank')
                    persistent filterbank%#ok<TLEV> %Instantiating a filterbank on every trial is rather slow.
                    if ~strcmpi(class(filterbank),'EERF.Filterbank')
                        filter_meta.fs = fs;
                        filter_meta.freq_edges = tfparms.freq_edges_hz;
                        filterbank = EERF.Filterbank(filter_meta);
                    end
                    tfparms.filterbank = filterbank;
                end
                temp_ft = tfparms.filterbank.process(temp_dat);
                temp_ft = reshape(temp_ft,[n_samps, n_chans*n_freqs]);
                temp_ft = abs(hilbert(temp_ft));
                temp_ft = temp_ft.^2;
                temp_ft = reshape(temp_ft,[n_samps n_chans n_freqs]);
                reindex_freqs = shiftdim(0:n_samps*n_chans:n_samps*n_chans*n_freqs-1,-2);
                reindex = bsxfun(@plus,reindex,reindex_freqs);
                temp_ft = temp_ft(reindex);
                temp_ft = mean(temp_ft);
                tf_amp = shiftdim(temp_ft,1); %steps x chans x freqs
            elseif strcmpi(tfparms.ft_type,'mem')
                temp_dat = temp_dat(reindex);
                temp_dat = reshape(temp_dat,[n_samps_per_win n_chans*n_steps]);
                temp_ft = NaN(n_freqs,n_chans*n_steps);%Instantiate our output variable.
                for ff=1:n_freqs
                    order = min(floor(fs/tfparms.freq_edges_hz(ff,1)),fs/2);
                    width = tfparms.freq_edges_hz(ff,2)-tfparms.freq_edges_hz(ff,1);
                    f_cent = mean(tfparms.freq_edges_hz(ff,:));
                    %parms = [order f_cent f_cent width 10 2 trial.fs n_samps_per_step n_samps_per_win/n_samps_per_step];
                    parms = [order f_cent f_cent width 10 2 fs];
                    temp_ft(ff,:) = mem(temp_dat,parms);
                end
                temp_ft = reshape(temp_ft,[n_freqs n_chans n_steps]); %freqs x chans x steps
                tf_amp = permute(temp_ft,[3 2 1]); %steps x chans x freqs
            elseif strcmpi(tfparms.ft_type,'fft')
                temp_dat = temp_dat(reindex); %[n_samps_per_win x n_steps x n_chans]
                temp_dat = reshape(temp_dat,[n_samps_per_win n_steps*n_chans]);
                temp_dat = detrend(temp_dat,'linear');
                blwindow = blackman(size(temp_dat,1));%like a gaussian window
                temp_dat = bsxfun(@times,temp_dat,blwindow);%window the steps
                NFFT = round(fs);
                n_fft_freqs = NFFT/2+1;
                freq_out = fs/2*linspace(0,1,n_fft_freqs);
                temp_ft = fft(temp_dat,NFFT)/fs;
                temp_ft = 2*abs(temp_ft(1:n_fft_freqs,:,:));
                gt_bool = bsxfun(@ge,freq_out,tfparms.freq_edges_hz(:,1));
                lt_bool = bsxfun(@le,freq_out,tfparms.freq_edges_hz(:,2));
                freq_bool = gt_bool & lt_bool;
                temp_ft = freq_bool * temp_ft;%This sums up values for each frequency bin.
                temp_ft = bsxfun(@rdivide, temp_ft, sum(freq_bool,2));%Divide by the number of frequencies.
                temp_ft = reshape(temp_ft,[n_freqs n_steps n_chans]);
                tf_amp = permute(temp_ft,[2 3 1]);%steps x chans x freqs
            end
            
            %Prepare the output.
            if nargout>1
                varargout{1} = tvec(step_starts + n_samps_per_win - 1);%The time of the last sample included in the window.
            end
            if nargout>2
                varargout{2} = mean(tfparms.freq_edges_hz,2);%The middle frequency.
            end
        end
    end
end