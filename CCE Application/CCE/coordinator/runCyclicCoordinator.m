function runCyclicCoordinator(coordinatorObj, cID, logger, coordinatorStartTime)
    % runCyclicCoordinator  Execute the Cyclic or Single-shot Execution Coordinator until the Coordinator's Lifetime is reached

    arguments
        coordinatorObj cce.Coordinator %Coordinator object
        cID int32 %Coordinator ID
        logger Logger %Instantiated logger object
        coordinatorStartTime datetime
    end

    % Determine Coordinator Exit Time. (Now plus Lifetime)
    coordinatorExitTime = coordinatorStartTime + coordinatorObj.Lifetime;
    if (coordinatorObj.ExecutionMode == cce.CoordinatorExecutionMode.Single)
        % This is a single-shot execution, so run once.
        logger.logTrace("Coordinator %d running once (ExecutionMode = %s)", cID, string(coordinatorObj.ExecutionMode));
        runOnceOnly = true;
    else
        logger.logTrace("Coordinator %d exit time calculated as %s", cID, string(coordinatorExitTime));
        runOnceOnly = false;
    end

    % Run once, or until exit time is exceeded
    keepRunning = true; % We run at least once.
    while keepRunning && (coordinatorExitTime > datetime('now'))
        % If user requests a disable, or State is disabled, exit loop

        coordinatorObj.Calculations.refreshAttributesForCyclicCoord; % Only refresh attributes that need to be refreshed
        
        % For all my calculations, determine if they must be disabled.
        newlyDisabled = checkForDisableRequest(coordinatorObj.Calculations);

        % Only log if level debug and higher
        if logger.LogLevel >= LogMessageLevel.Debug
            if any(newlyDisabled)
                calcsDisabled = coordinatorObj.Calculations(newlyDisabled);
                for oI = 1:numel(calcsDisabled)
                    logger.logDebug("Calculation %s set to disabled by user request.", calcsDisabled(oI).RecordPath);
                end
            end
        end

        coordinatorObj.checkLag(coordinatorStartTime, coordinatorObj.ExecutionFrequency, logger)

        % Determine next output time to run. Need updated calculation attributes here
        nextOutputTime = coordinatorObj.getNextOutputTime(coordinatorStartTime);

        % Before we wait in the loop, check if user requested a disable, or State is disabled
        if checkForDisabled(coordinatorObj, logger) %This checks if the coordinator is requested to
            % stop/if state changes. Removed call at the beginning of function -
            % this will mean slight delay of user disabling, but will improve
            % coordinator efficiency.
            keepRunning = false;
        else
            % If nextOutputTime is in the future, we wait or terminate
            if (datetime('now') < nextOutputTime )
                if (nextOutputTime < coordinatorExitTime) % before coordinatorExitTime, set state to Idle and wait
                    % reload calculations if any are in a network error
                    % state

                    if any([coordinatorObj.Calculations.LastError] == cce.CalculationErrorState.NetworkError)
                        idx = find([coordinatorObj.Calculations.LastError] == cce.CalculationErrorState.NetworkError,1,'first');
                        lastFailedTime = getNetworkFailedTime(coordinatorObj.Calculations(idx).CalculationID);
                        timeDiff = datetime("now") - lastFailedTime;

                        if timeDiff > seconds(coordinatorObj.RetryFrequency)
                            coordinatorObj.loadCalculations(logger);
                        end
                    end

                    pauseTimeSeconds = seconds(nextOutputTime - datetime('now'));
                    logger.logTrace("Waiting %f seconds for next output time.", pauseTimeSeconds);
                    setCoordinatorStateIfNotDisabled(coordinatorObj, cce.CoordinatorState.Idle, logger);

                    isDisableTriggered = pauseWhileCheckingForDisabled(coordinatorObj, logger, pauseTimeSeconds,...
                        coordinatorStartTime, false);
                    if isDisableTriggered
                        keepRunning = false;
                    end
                else
                    % nextOutputTime is after coordinatorExitTime, so exit.
                    keepRunning = false;
                end
            end
        end

        if keepRunning
            % If the NextOutputTime is NaT, this means there's no calculation that can provide a next output time, so wait before we check again.
            if isnat(nextOutputTime)
                % Get the first calculation's executionfrequency; they're all the same.
                if all(ismember([coordinatorObj.Calculations.CalculationState],...
                        [cce.CalculationState.Disabled, cce.CalculationState.ConfigurationError, cce.CalculationState.SystemDisabled]))
                    % Have to wait longer to allow the user to re-enable a calculation
                    waitTime = min(60, 0.1*seconds(coordinatorObj.Lifetime));
                else
                    % One of the calculations is waiting for inputs. Give it time.
                    waitTime = 0.5*seconds(coordinatorObj.Calculations(1).ExecutionFrequency);
                end
                logger.logInfo("No calculations can provide a next output time. Waiting %.2f seconds.", waitTime);
                setCoordinatorStateIfNotDisabled(coordinatorObj, cce.CoordinatorState.Idle, logger);
                isDisableTriggered = pauseWhileCheckingForDisabled(coordinatorObj, logger, waitTime,...
                    coordinatorStartTime, true);

                if isDisableTriggered
                    keepRunning = false;
                end
            else % Have a nextOutputTime; run
                logger.logInfo("Executing calculations with OutputTime: %s", string(nextOutputTime));
                % Determine if we are backfilling or running normally. We are backfilling if the NextOutputTime + ExecutionFrequency is in the past. Set the CoordinatorState appropriately.
                if (nextOutputTime + coordinatorObj.ExecutionFrequency) < datetime('now')
                    currentState = cce.CoordinatorState.Backfilling;
                else
                    currentState = cce.CoordinatorState.Executing;
                end
                setCoordinatorStateIfNotDisabled(coordinatorObj, currentState, logger)
                % Run calculations for that output time.
                coordinatorObj.executeCalculations(nextOutputTime, logger);
                if runOnceOnly && (currentState == cce.CoordinatorState.Executing)
                    % We've done our job.
                    keepRunning = false;
                end
            end
        end
    end

    setCoordinatorStateIfNotDisabled(coordinatorObj, cce.CoordinatorState.ShuttingDown, logger)
end