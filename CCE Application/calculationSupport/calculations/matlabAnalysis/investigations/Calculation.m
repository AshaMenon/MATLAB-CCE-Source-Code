classdef Calculation
    %UNTITLED6 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = public)
        BaseValue = 5;
        Value {mustBeNumeric}
    end
    
    methods
        function obj = Calculation(val)
            if nargin == 1
                obj.Value = val;
            end
        end
        
        function checkFlag = checkValue(obj)
            checkFlag = obj.Value > obj.BaseValue;
        end
        
    end
end

