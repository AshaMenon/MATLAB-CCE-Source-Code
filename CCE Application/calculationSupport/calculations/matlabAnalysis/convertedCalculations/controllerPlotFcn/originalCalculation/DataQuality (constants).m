classdef DataQuality
    %DataQuality Constants defining DataQuality
    %
    % Copyright 2013 Anglo American Platinum
    % $Revision: 1.4 $ $Date: 2012/02/07 19:45:35 $
    
    properties (Constant)
        
        ClassName     = 'ap.DataQuality'
        Constructor   = @ap.DataQuality
        Empty         =  ap.DataQuality.empty
        
        QualityStr    = {'Good','Missing Data','Not Running','Run-up',...
            'Simulated','Out-of-service','High','Low','Not Updating',...
            'ROC','Outliers','Mapped Good','Not Validated'}
        QualityEnum   = [0,1,2,3,4,5,6,8,16,32,64,65534,65535]
        QualityExport = [0,1,2,3,4,5,6,7,8,9,10,11,12]
        UnknownStr    = 'Unknown'
        UnknownEnum   = []
        AllEnumFlag   = '-all'
        Untested      = 65535
        
    end
    
end
