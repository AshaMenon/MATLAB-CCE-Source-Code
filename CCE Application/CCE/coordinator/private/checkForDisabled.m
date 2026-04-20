function tf = checkForDisabled(coordinatorObj, logger)
    %checkForDisabled  Check RequestToDisable and CoordinatorState properties for Disable request

    %TODO: This refreshes AFDBCache twice, as both RequestToDisable and
    %Coordinator state uses the AFCoordinatorRecord.getField, and are set to
    %refresh DB. This is only needed once, but practically would change the
    %overall code design.

     %RefreshAttributes was intially used in this function - this is now handled
     % with the addition of RequestToDisable DB pull in readField - 30%
     % quicker.

    if coordinatorObj.RequestToDisable
        % User has requested a disable

        logger.logWarning("User requested Disable. Setting Coordinator to Disabled and exiting.");
        coordinatorObj.CoordinatorState = cce.CoordinatorState.Disabled;
        coordinatorObj.RequestToDisable = false; % Because we've disabled the coordinator.
        commit(coordinatorObj);
        tf = true;

    elseif isequal(coordinatorObj.CoordinatorState, cce.CoordinatorState.Disabled)
        logger.logWarning("Coordinator state set to Disabled by another process. Exiting.");
        tf = true;

    else
        tf = false;
    end
end

