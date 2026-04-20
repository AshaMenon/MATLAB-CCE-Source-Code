function setCalculationExecutionOrder(calculations, executionOrder, fullDependencyList, logger)
    %SETCALCULATIONEXECUTIONORDER sets the ExecutionIndex for all Calculations.
    % For Calculations that are not part of a Circular Dependency Chain, the Calculation's
    % Execution Order is set to the correct ExecutionOrder found by the dependency
    % algorithm.
    %
    % If the Calculation is part of a Circular Dependency Chain, its Execution Order is
    % set to 0 and the Calculation is set to a Configuration Error State.
    %
    % If the Calculation is dependent on a Disabled Calculation, a warning is logged to
    % the local logs.
    %
    % If the Calculation is dependent on a Retired Calculation, the Calculation is set to
    % a Configuration Error State.
    
    idxCircularDepend = isnan(executionOrder);
    for k = 1:numel(calculations)
        
        % Check for Circular Dependency Chains
        if ~idxCircularDepend(k)
            calculations(k).ExecutionIndex = executionOrder(k);
        else
            % Set the ExecutionIndex to zero, set the Calculation to a Configuration Error
            % State and log this to the Calculation DB & the local logs
            calculations(k).ExecutionIndex = 0;
            setCalculationErrorState(calculations(k), cce.CalculationErrorState.CircularDependencyChain);
            %Add Message to local logs
            calcPath = join([fullDependencyList{k}.RecordPath], ', ');
            logger.logError(join(["Calculations ID(s): %s form part of a circular dependency chain.", ...
                "\nExecution Order set to 0." ,...
                "\nCalculations in this list must be inspected and the circular dependency resolved"]), ...
                calcPath);
        end
        
        % Check for Dependency on Disabled and or Retired Calculations
        if ~isempty(fullDependencyList{k})
            dependencyState = [fullDependencyList{k}.CalculationState];
            % Find Disabled Dependencies
            isDisabled = ismember(dependencyState, cce.CalculationState.Disabled);
            % Find SystemDisabled Dependencies
            isSystemDisabled = ismember(dependencyState, cce.CalculationState.SystemDisabled);
            % Find Retired Dependencies
            isRetired = ismember(dependencyState, cce.CalculationState.Retired);
            
            if any(isDisabled)
                % Log a warning for Calculations with Disabled Dependencies
                disabledDepend = fullDependencyList{k}(isDisabled);
                calcPath = join([disabledDepend.RecordPath], ', ');
                %Log a warning to the local logs
                logger.logWarning(join(["Calculation %s is dependent on Calculation(s)", ...
                    "in the Disabled CalculationState.\nCalculation: %s Disabled."]), ...
                    calculations(k).RecordPath, calcPath);
            end

            if any(isSystemDisabled)
                % Log a warning for Calculations with SystemDisabled Dependencies
                systemDisabledDepend = fullDependencyList{k}(isSystemDisabled);
                calcPath = join([systemDisabledDepend.RecordPath], ', ');
                %Log a warning to the local logs
                logger.logWarning(join(["Calculation %s is dependent on Calculation(s)", ...
                    "in the SystemDisabled CalculationState.\nCalculation: %s Disabled."]), ...
                    calculations(k).RecordPath, calcPath);
            end
            
            if any(isRetired)
                % Set the Calculation to a Configuration Error State and log this to the
                % Calculation DB & the local logs for Calculations dependent on Retired
                % Calculations
                setCalculationErrorState(calculations(k), cce.CalculationErrorState.RetiredCalculationDependency);
                
                %Add Message to local logs with the retired dependencies
                retiredDepend = fullDependencyList{k}(isRetired);
                calcPaths = join([retiredDepend.RecordPath], ', ');
                %Log a warning to the local logs
                logger.logError(join(["Calculation: %s is dependent on Calculation(s)", ...
                    "in the Retired CalculationState.\nCalculation(s): %s are retired."]), ...
                    calculations(k).RecordPath, calcPaths);
            end
        end
    end
end

function setCalculationErrorState(calculation, ErrorCode)
    %SETCIRCULARDEPENDENCYERRORSTATE set a Calculation that is part of a Circular
    %Dependency Chain to a ConfigurationError State and Log the error to the Calculation
    %DB and the local logs.
    
    %Set CalculationState to ConfigurationError
    calculation.CalculationState = cce.CalculationState.ConfigurationError;
    %Add LastError
    calculation.LastError = ErrorCode;
end