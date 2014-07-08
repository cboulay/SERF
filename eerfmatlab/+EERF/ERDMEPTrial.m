classdef ERDMEPTrial < EERF.ERDTrial & EERF.MEPTrial
    methods
        function obj = ERDMEPTrial(varargin)
            obj = obj@EERF.ERDTrial(varargin{:});
        end
    end
end