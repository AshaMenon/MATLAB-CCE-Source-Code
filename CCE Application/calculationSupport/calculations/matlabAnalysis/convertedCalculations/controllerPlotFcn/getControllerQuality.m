function [controllerStatus, inCtrlData, quality] = ...
        getControllerQuality(timespanData, goodQualityVal,...
        mappedGoodQualityVal, notRunningQualityVal,controllerConstraint,...
        normCtrlErrorThreshold,k)
    %GETCONTROLLERSTATUS Calculates the quality status for a controller
    %   Uses current data. 
    
    % Assign good data as large number
    timespanData.plotQuality{k}(timespanData.plotQuality{k}==goodQualityVal)...
        = mappedGoodQualityVal;
    % Identify minimum quality value of all sensors
    timespanData.quality{k} = nanmin(timespanData.plotQuality{k},[],2);
    % Reset good quality marker
    timespanData.quality{k}(timespanData.quality{k}==mappedGoodQualityVal) = goodQualityVal;
    % Identify where insturment data good & running & controller in auto
    
    if size(timespanData.plotCntrlData{k},2) == 4
        timespanData.inCtrlData{k} = (timespanData.quality{k}...
            ==goodQualityVal & timespanData.plotCntrlData{k}(:,4)==1);
    else
        timespanData.inCtrlData{k} = (timespanData.quality{k}==goodQualityVal);
    end
    
    % Assign default "(0)" to all controller quality
    timespanData.cntrlQuality{k} = zeros(size(timespanData.plotQuality{k},1),1);
    % Assign "Healthy (5)" to all not running data
    timespanData.cntrlQuality{k}(any(timespanData.plotQuality{k}...
        ==notRunningQualityVal,2)) = 5;
    % Assign "Instrument fault (1)" to faulty instrument data
    timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 ...
        & timespanData.quality{k}~=goodQualityVal) = 1;
    
    % Assign "Manual (2)" to controllers in manual data
    if size(timespanData.plotCntrlData{k},2) == 4
        timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 ...
            & timespanData.plotCntrlData{k}(:,4)==0) = 2;
    end
    
    % Calculate SP error - column 5
    timespanData.plotCntrlData{k}(:,5) = ...
        timespanData.plotCntrlData{k}(:,2) - timespanData.plotCntrlData{k}(:,1);
    
    % Assign "Unhealthy (4)" to controllers in exceeding control error threshold
    if strcmpi(controllerConstraint,'upper')
        timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 &...
            (timespanData.plotCntrlData{k}(:,5))<(-normCtrlErrorThreshold)) = 4;
    elseif strcmpi(controllerConstraint,'lower')
        timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 & ...
            (timespanData.plotCntrlData{k}(:,5))>normCtrlErrorThreshold) = 4;
    else
        timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 &...
            abs(timespanData.plotCntrlData{k}(:,5))>normCtrlErrorThreshold) = 4;
    end
    
    % Assign "Healthy (5)" to controllers within control error threshold
    if strcmpi(controllerConstraint,'upper')
        timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 &...
            (timespanData.plotCntrlData{k}(:,5))>=(-normCtrlErrorThreshold)) = 5;
    elseif strcmpi(controllerConstraint,'lower')
        timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 &...
            (timespanData.plotCntrlData{k}(:,5))<=normCtrlErrorThreshold) = 5;
    else
        timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 &...
            abs(timespanData.plotCntrlData{k}(:,5))<=normCtrlErrorThreshold) = 5;
    end
    
    controllerStatus = timespanData.cntrlQuality(k);
    inCtrlData = timespanData.inCtrlData(k);
    quality = timespanData.quality(k);
end
