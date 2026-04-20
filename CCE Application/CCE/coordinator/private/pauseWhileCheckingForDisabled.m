function isDisableTriggered = pauseWhileCheckingForDisabled(coordinatorObj, logger, pauseTimeSeconds, coordStartTime,...
        checkNextOutputTime)
    %pauseWhileCheckingForDisabled  Wait while checking periodically for user changes to state
    timeWaited = 0;
    pauseGranularity = 2; % Wait 2 seconds between checks
    isDisableTriggered = false;
    calcReady = false;
    while ((timeWaited + pauseGranularity) < pauseTimeSeconds) && ~isDisableTriggered && ~calcReady
        %Check if the coordinator gets manually disabled
        if checkForDisabled(coordinatorObj, logger) 
            isDisableTriggered = true;
        end

        %Check if a calc ouput gets ready (in the case where all
        %nextoutputs are NaN
        if checkNextOutputTime && ~isnat(coordinatorObj.getNextOutputTime(coordStartTime)) %Check if any calculations should be run
            calcReady = true;
        end

        pause(pauseGranularity);
        timeWaited = timeWaited + pauseGranularity;
    end
    if ~isDisableTriggered
        pause(pauseTimeSeconds - timeWaited);
    end
end