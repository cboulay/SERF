classdef Fragment < E3.Subject_property_array
    properties (Constant = true, Hidden = true)
        table_name='fragment';
        other_ind_name='Number';
    end
    properties (Dependent = true)
        Number
        Fs
        NSamples
        NChannels
    end
    methods (Static = true)
        function frag_array=get_property_array_for_subject(ani)
            frag_array=get_property_array_for_subject@E3.Subject_property_array(ani,'Fragment');
        end
    end
    methods
        function number=get.Number(obj)
            number=obj.other_ind_value;
        end
        function set.Number(obj,number)
            obj.other_ind_value=number;
        end
        function fs=get.Fs(obj)
            fs=obj.get_property('Fs','float');
        end
        function set.Fs(obj,fs)
            obj.set_property('Fs',fs,'float');
        end
        function nsamples=get.NSamples(obj)
            nsamples=obj.get_property('NSamples','int');
        end
        function set.NSamples(obj,nsamples)
            obj.set_property('NSamples',nsamples,'int');
        end
        function nchannels=get.NChannels(obj)
            nchannels=obj.get_property('NChannels','int');
        end
        function set.NChannels(obj,nchannels)
            obj.set_property('NChannels',nchannels,'int');
        end
    end
end