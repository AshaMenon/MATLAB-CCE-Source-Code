function deletedIDs = unAssignDeletedCoordinators(calculations, isDeleted, assignedZeroCoord, logger)
    
    deletedIDs = unique([calculations(isDeleted).CoordinatorID]);
    if any(isDeleted)
        deletedCoordinators = join(string(deletedIDs), ', ');
        logger.logInfo("%d Calculations are assigned to deleted Coordinators \nDeleted Coordinator ID(s): #%s", ...
            sum(isDeleted), deletedCoordinators);
    end
    if any(any(assignedZeroCoord))
        logger.logInfo("%d Calculations are in an active CalculationState but assigned to no CoordinatorID.", ...
            sum(assignedZeroCoord));
    end
    
    isImproperlyDeleted = isDeleted | assignedZeroCoord;
    isActive = cce.isCalculationActive([calculations(isImproperlyDeleted).CalculationState]);
    
    locImproperlyDeleted = find(isImproperlyDeleted);
    for k = 1:sum(isImproperlyDeleted)
        calculations(locImproperlyDeleted(k)).CoordinatorID = 0;
        if isActive(k)
            calculations(locImproperlyDeleted(k)).CalculationState = cce.CalculationState.NotAssigned;
        end
    end
end