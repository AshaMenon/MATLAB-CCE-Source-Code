function newCoord = createNewCoordinator(coordIds, mode, freq, offset, load, lifetime, skipBackfill)
    
    if isempty(coordIds)
        id = int32(1);
    else
        orderedCoordinators = int32(1:max(coordIds));
        isSkippedID = ~ismember(orderedCoordinators, coordIds);
        if any(isSkippedID)
            missingCoordIDs = orderedCoordinators(isSkippedID);
            id = min(missingCoordIDs);
        else
            id = int32(max(coordIds) + 1);
        end
    end
    
    dbService = cce.AFCoordinatorDbService.getInstance();
    newCoord = cce.Coordinator.createNew(id, ...
        'ExecutionMode', mode, 'ExecutionFrequency', freq, 'ExecutionOffset', offset, ...
        'Lifetime', lifetime, 'CalculationLoad', load, ...
        'DatabaseService', dbService, 'SkipBackfill', skipBackfill);
end