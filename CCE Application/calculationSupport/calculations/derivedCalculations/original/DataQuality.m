classdef DataQuality
    %DataQuality Data Quality Enumerations for Derived Calculations
    properties
        GoodQualityVal
        MissingQualityVal
        NotRunningQualityVal
        NotValidatedQualityVal
    end
    
    methods
        function obj = DataQuality(goodQualityVal,missingQualityVal,...
                notRunningQualityVal, notValidatedQualityVal)
            obj.GoodQualityVal = goodQualityVal;
            obj.MissingQualityVal = missingQualityVal;
            obj.NotRunningQualityVal = notRunningQualityVal;
            obj.NotValidatedQualityVal = notValidatedQualityVal;
        end
    end
end

