function removeCalculationsFromCoordinators(removedCalcs, coordinators, logger)
    %REMOVECALCULATIONSFROMCOORDINATORS Remove a calculation from a coordinator
    %   removeCalculationsFromCoordinators(removedCalcs, coordinators, logger)
    
    %Get the existing CoordinatorIDs
    coordIds = [coordinators.CoordinatorID];
    
    % Get the CoordinatorIDs to which the to be removed Calculations are currently assigned
    calcCoordIds = [removedCalcs.CoordinatorID];

    % Reset the Calculation's CoordinatorID to 0
    for c = 1:numel(removedCalcs)
        removedCalcs(c).CoordinatorID = 0;
        removedCalcs(c).commit();
    end
    
    % Find the unique CoordinatorIDs to which the to be removed Calculations are assigned
    % and how many calculations are to be removed from each Coordinator
    uniqueIds = unique(calcCoordIds);
    instancesOfIds = sum(calcCoordIds == uniqueIds(:), 2);
    uniqueIds = uniqueIds(uniqueIds ~= 0);
    instancesOfIds = instancesOfIds(uniqueIds ~= 0);
    for c = 1:numel(uniqueIds)
        % Reduce the load of the Coordinator by the number of Calculations that were
        % assigned to it and have been removed.
        loadToRemove = instancesOfIds(c);
        thisCoord = coordinators(coordIds == uniqueIds(c));
        if isempty(thisCoord)
            % Coordinator doesn't exist. Report a misconfigured coordinator.
            logger.logWarning("Coordinator %d associated with calculations for removal not found.", uniqueIds(c));
        else
            thisCoord.CalculationLoad = thisCoord.CalculationLoad - loadToRemove;
            thisCoord.commit();
        end
    end
end
