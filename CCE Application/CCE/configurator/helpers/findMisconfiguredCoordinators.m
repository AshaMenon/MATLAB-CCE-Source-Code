function misconfiguredIdx = findMisconfiguredCoordinators(coordinators)

    misconfiguredIdx = false(length(coordinators),1);

    for idx = 1:length(coordinators)
        coord = coordinators(idx);

        coordID = coord.CoordinatorID;
        execFreq = coord.ExecutionFrequency;
        execMode = coord.ExecutionMode;
        execOffset = coord.ExecutionOffset;

        % check if any value doesn't exist
        if isempty(coordID) || isempty(execFreq) || isempty(execMode) || isempty(execOffset)
            misconfiguredIdx(idx) = true;
            continue
        end
        
        % check for incorrect values
        if ~ismember(execMode,enumeration("cce.CoordinatorExecutionMode")) || extractAfter(coord.ElementName,"CCECoordinator") ~= string(coordID)
            misconfiguredIdx(idx) = true;
            continue
        end        

    end
end