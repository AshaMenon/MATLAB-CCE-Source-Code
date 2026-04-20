function runEventBasedCoordinator(coordinatorObj, cID, logger, coordinatorStartTime)
    % RUNEVENTBASEDCOORDINATOR runs the Coordinator as an Event-Based Coordinator.
    % RUNEVENTBASEDCOORDINATOR runs until the Coordinator's Lifetime is reached/ exceeded
    % and executes a Calculation once an update event has been recieved for that
    % Calculation. Once the Lifetime is reached, the Coordinator will exit.
    
    % Create the CalcServer object. Requires a ClientID
    clientID = sprintf('coordinator%d', coordinatorObj.CoordinatorID);
    calcServer = CalcServer(clientID);
    
    % Find the Coordinator's Calculations' Trigger Attributes & Sign them up for
    % Update Events
    dataPipe = cce.AFDataPipe.getInstance();
    
    idxActiveCalcs = cce.isCalculationActive([coordinatorObj.Calculations.CalculationState]);
    activeCalcs = find(idxActiveCalcs);
    calcIDs = strings(size(activeCalcs));
    for c = 1:sum(idxActiveCalcs)
        calcIDs(c) = coordinatorObj.Calculations(activeCalcs(c)).signUpForUpdateEvents(dataPipe);
    end
    
    % Determine Coordinator Exit Time. (Now plus Lifetime)
    coordinatorExitTime = coordinatorStartTime + coordinatorObj.Lifetime;
    
    logger.logTrace("Event-based Coordinator %d exit time calculated as %s", cID, string(coordinatorExitTime));
    
    % We need to check for disable periodically, but not as frequently as we check for events.
    lastDisableCheck = datetime('now');
    disableCheckInterval = seconds(30); % TODO: Decide if this must be configurable, or is too long.
    keepRunning = true;
    % While exit time is in the future
    
    while keepRunning && (coordinatorExitTime > datetime('now'))
        % If State is disabled, exit loop
        if (datetime('now')-lastDisableCheck > disableCheckInterval)
            keepRunning = ~checkForDisabled(coordinatorObj, logger);
            lastDisableCheck = datetime('now');
        end
        
        if keepRunning
            % Check if there are any update events
            [ids, changeTime, action, previousAction] = dataPipe.getNewEvents();
            
            % If any change events are returned, run the calculations. If not, wait 1
            % second and check again.
            if ~isempty(ids)
                setCoordinatorStateIfNotDisabled(coordinatorObj, cce.CoordinatorState.Executing, logger)
                logger.logInfo("Executing %d calculation(s) that received an update event.", numel(ids));
                
                %Run Calculations in order of updateTime
                [changeTime, idxChangeTime] = sort(changeTime);
                ids = ids(idxChangeTime);
                action = action(idxChangeTime);
                previousAction = previousAction(idxChangeTime);
                outputTimes = unique(changeTime);
                for c = 1:numel(outputTimes)
                    thisOutTime = outputTimes(c);
                    [idx, indCalcs] = ismember(ids(changeTime == thisOutTime), calcIDs);
                    currentIds = ids(changeTime == thisOutTime);
                    currentActions = action(changeTime == thisOutTime);
                    currentPrevActions = previousAction(changeTime == thisOutTime);
                    for trace = 1:numel(currentIds)
                        logger.logTrace("Calculation %s received update events at time %s with Action: %s and Previous Action: %s", ... ...
                            currentIds(trace), thisOutTime, currentActions(trace), currentPrevActions(trace));
                    end

                    calcs = coordinatorObj.Calculations;
                    calcsToRun = calcs(indCalcs(idx));
                    coordinatorObj.runCalculations(thisOutTime, calcsToRun, calcServer, logger);
                end
            else
                setCoordinatorStateIfNotDisabled(coordinatorObj, cce.CoordinatorState.Idle, logger)
                pause(1)
            end
        end
    end
    % Remove Calculations from Update Events
    setCoordinatorStateIfNotDisabled(coordinatorObj, cce.CoordinatorState.ShuttingDown, logger)
    for calc = 1:numel(coordinatorObj.Calculations)
        coordinatorObj.Calculations(calc).removeForUpdateEvents(dataPipe);
    end
end