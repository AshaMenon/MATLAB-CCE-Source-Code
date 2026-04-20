classdef PlantBCalc < Calculation
    
    properties
        MultiplyVal {mustBeNumeric}
    end
    
    methods
        function obj = PlantBCalc(val1,val2)
            obj@Calculation(val1);
            if nargin == 2
                obj.MultiplyVal = val2;
            end
        end
        
        function productValue = multiplyValues(obj)
            productValue = obj.MultiplyVal * obj.Value;
        end
        
    end
end