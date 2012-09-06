classdef ERDMEPTrial < EERAT.ERDTrial & EERAT.MEPTrial
    methods
        function obj = ERDMEPTrial(varargin)
            obj = obj@EERAT.ERDTrial(varargin{:});
        end
    end
end