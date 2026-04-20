function setCoordinatorStateIfNotDisabled(coordObj, newState, logger)
    %setCoordinatorStateIfNotDisabled  Set Coordinator State as long as it's not disabled (and new state is different)
    if ~isequal(coordObj.CoordinatorState, cce.CoordinatorState.Disabled) && ...
            ~isequal(coordObj.CoordinatorState, newState)
        logger.logTrace("Setting coordinator state to %s", string(newState));
        coordObj.CoordinatorState = newState;
    end
end
