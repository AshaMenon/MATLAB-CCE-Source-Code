function [executionMode, executionFrequency, executionOffset, skipBackfill] = findCalculationTreeExecutionParameters(executionModes, executionFrequencies, executionOffsets, skipBackfills, logger)
    %FINDCALCULATIONTREEEXECUTIONPARAMETERS return the most likely execution parameters
    %for the Calculation tree. If all of the Calculations are configured with the same
    %execution parameters - return those, otherwise the execution parameters returned will
    %be the minimum frequency, the minimum offset, and if the set contains cyclic mode,
    %return that.
    
    arguments
        executionModes cce.CalculationExecutionMode;
        executionFrequencies duration;
        executionOffsets duration;
        skipBackfills logical
        logger
    end
    
    if all(executionModes == executionModes(1))
        executionMode = executionModes(1);
    else
        if any(ismember(executionModes, cce.CalculationExecutionMode.Periodic))
            executionMode = cce.CalculationExecutionMode.Periodic;
        else
            executionMode = mode(executionModes);
        end
    end
    
    if all(executionFrequencies == executionFrequencies(1)) || all(isnan(executionFrequencies))
        executionFrequency = executionFrequencies(1);
    else
        executionFrequency = min(executionFrequencies, [], 'omitnan');
        logger.logWarning("Calculations in dependency chain have varying frequencies, ..." + ...
            "setting execution frequency to %d", min(executionFrequencies, [], 'omitnan'))
    end
    if all(executionOffsets == executionOffsets(1))
        executionOffset = executionOffsets(1);
    else
        executionOffset = min(executionOffsets, [], 'omitnan');
        logger.logWarning("Calculations in dependency chain have varying offsets, ..." + ...
            "setting execution offset to %d", min(executionOffsets, [], 'omitnan'))
    end
    if all(skipBackfills == skipBackfills(1))
        skipBackfill = skipBackfills(1);
    else
        skipBackfill = false;
        logger.logWarning("Calculations in dependency chain have varying skip backfill properties, ..." + ...
            "setting SkipBackfill to false")
    end
end