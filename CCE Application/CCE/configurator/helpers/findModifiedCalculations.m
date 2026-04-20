function [isModified] = findModifiedCalculations(calculations, coordinators)
    %FINDMODIFIEDCALCULATIONS find the index of calculations that no longer have the same
    %execution parameters as the coordinator that they are assigned to.
    
    calcExecModes = [calculations.ExecutionMode];
    idxPeriodic = ismember(calcExecModes, cce.CalculationExecutionMode.Periodic);
    idxEvent = ismember(calcExecModes, cce.CalculationExecutionMode.Event);
    idxManual = ismember(calcExecModes, cce.CalculationExecutionMode.Manual);
    
    % Get each Coordinator's Execution Parameters and CoordinatorID
    coordIDs = [coordinators.CoordinatorID];
    coordExecModes = [coordinators.ExecutionMode];
    coordExecFrequency = [coordinators.ExecutionFrequency];
    coordExecOffsets = [coordinators.ExecutionOffset];
    
    % Get the Calculation's Execution Parameters and it's currently assigned CoordinatorID
    calcCoordIDs = [calculations.CoordinatorID];
    calcExecFrequencies = [calculations.ExecutionFrequency];
    calcExecOffsets = [calculations.ExecutionOffset];
        
    % Remove from the list, any Coordinators that aren't currently used by the
    % Calculations
    [isUsed, locCoords] = ismember(calcCoordIDs, coordIDs);
    % For each Calculation - extract it's current assigned Coordinator's Execution
    % Parameters into a list for comparison to the current Execution Parameters.
    calcsCoordExecModes = coordExecModes(locCoords(isUsed));
    calcsCoordExecFrequency = coordExecFrequency(locCoords(isUsed));
    calcsCoordExecOffsets = coordExecOffsets(locCoords(isUsed));
    
    % If any of the Calculation's Execution Parameters no longer match its assigned
    % Coordinator's Execution Parameters, flag the Calculation as Modified
    isModified = false(size(calculations));
    isModified(idxManual) = true;
    isModified(idxEvent) = ~ismember(calcsCoordExecModes(idxEvent), cce.CoordinatorExecutionMode.Event);
    
    isDiffMode = ~ismember(calcsCoordExecModes(idxPeriodic), ...
        [cce.CoordinatorExecutionMode.Cyclic, cce.CoordinatorExecutionMode.Single]);
    isDiffFreq = (calcsCoordExecFrequency(idxPeriodic) ~= calcExecFrequencies(idxPeriodic)) &...
        ~(isnan(calcsCoordExecFrequency(idxPeriodic)) & isnan(calcExecFrequencies(idxPeriodic)));
    isDiffOffset = (calcsCoordExecOffsets(idxPeriodic) ~= calcExecOffsets(idxPeriodic));
    isModified(idxPeriodic) = isDiffMode | isDiffFreq | isDiffOffset;
end