classdef PlantACalc < Calculation
    
    properties
        AddVal {mustBeNumeric}
    end
    
    methods
        function obj = PlantACalc(val1, val2)
            obj@Calculation(val1);
            if nargin == 2
                
                obj.AddVal = val2;
            end
        end
        
        function sumValue = addValues(obj)
            sumValue = obj.AddVal + obj.Value;
        end
        
    end
end