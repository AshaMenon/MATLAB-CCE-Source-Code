classdef DataQuality < double
    %DATAQUALITY Enumeration for Data Quality
    %   Detailed explanation goes here
    
    enumeration
        Good(0)
        MissingData(1)
        NotRunning(2)
        RunUp(3)
        Simulated(4)
        OutOfService(5)
        High(6)
        Low(8)
        NotUpdating(16)
        ROC(32)
        Outliers(64)
        MappedGood(65534)
        NotValidated(65535)
    end
end

