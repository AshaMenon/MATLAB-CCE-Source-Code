function runManualExecutionCoordinator(coordinator, cID, logger, coordinatorStartTime)
    
    keepRunning = true;
    exitTime = coordinatorStartTime + coordinator.Lifetime;
    while keepRunning && exitTime > datetime('now')
        if checkForDisabled(coordinator, logger)
            keepRunning = false;
        else
            %Search DB for Calcs that are in a BackfillingState == Running or == Requested
            backfillCalculations = cce.Calculation.fetchBackfillingFromDb();
            
            if isempty(backfillCalculations)
                %If we don't find any Calculations for Backfilling, wait a bit and then
                %try again on the next loop
                logger.logTrace("Manual Execution Coordinator: %d, idle. Waiting for backfilling/manual calculations", cID);
                setCoordinatorStateIfNotDisabled(coordinator, cce.CoordinatorState.Idle, logger);
                
                pauseTimeSeconds = 30;
                isDisableTriggered = pauseWhileCheckingForDisabled(coordinator, logger, pauseTimeSeconds, NaT, false);
                if isDisableTriggered
                    keepRunning = false;
                end
            else
                % Run the Calculations that the Coordinator found
                coordinator.CoordinatorState = cce.CoordinatorState.Backfilling;
                logger.logInfo("Manual Execution Coordinator: %d, backfilling. %d Calculations for backfilling/manual found", ...
                    cID, numel(backfillCalculations));
                for bfillcalcs = 1:numel(backfillCalculations)
                    logger.logTrace("Calculation %s found for backfilling\n", backfillCalculations(bfillcalcs).RecordPath);
                end
                
                %If we found some Calculations for Backfilling, let's work through each
                %one.
                idxRunning = ismember([backfillCalculations.BackfillState], cce.CalculationBackfillState.Running);
                idxRequested = ismember([backfillCalculations.BackfillState], cce.CalculationBackfillState.Requested);
                indCalculationsToRun = [find(idxRunning), find(idxRequested)];
                for c = 1:sum(idxRunning | idxRequested)
                    % Let's start by finding out what times we need to run it for
                    primaryCalc = backfillCalculations(indCalculationsToRun(c));
                    mode = primaryCalc.ExecutionMode;
                    backfillStart = primaryCalc.BackfillStartTime;
                    backfillEnd = primaryCalc.BackfillEndTime;
                    if primaryCalc.BackfillState == cce.CalculationBackfillState.Requested
                        progress = 0;
                        primaryCalc.BackfillProgress = progress;
                    else
                        progress = primaryCalc.BackfillProgress;
                    end
                    overwriteSettings = primaryCalc.BackfillOverwrite;
                    % Set the state to Running, if the state is not set to Off, Error, or already set to Running
                    if ~ismember(primaryCalc.BackfillState, [cce.CalculationBackfillState.Running, cce.CalculationBackfillState.Error, cce.CalculationBackfillState.Off])
                        primaryCalc.BackfillState = cce.CalculationBackfillState.Running;
                        primaryCalc.commit();
                    end
                    
                    logger.logDebug("Manual execution of Calculation  %s, in range: (%s) - (%s). Overwrite settings: %s", ...
                        primaryCalc.RecordPath, string(backfillStart), string(backfillEnd), string(overwriteSettings));
                    
                    % Find the output times for the backfilling
                    calcsToBackfill = primaryCalc;
                    %If the start time is larger than the end time - swap the times
                    outputStartTime = min([backfillStart, backfillEnd]);
                    outputEndTime = max([backfillStart, backfillEnd]);
                    if ismember(mode, cce.CalculationExecutionMode.Event)
                        % Find the timestamps of the events that happened for this calculation's event
                        % trigger attributes between the
                        backfillOutputTimes = primaryCalc.getEventTimes(outputStartTime, outputEndTime);
                        
                        %Event-based calculations can't be dependent on other calculations
                        %(because they don't run cyclicly). So we don't look for events
                        %here
                    elseif ismember(mode, [cce.CalculationExecutionMode.Periodic, cce.CalculationExecutionMode.Manual])
                        % Find the output times from the execution frequency + offset between the
                        % backfill start and end times
                        backfillOutputTimes = primaryCalc.getBackfillOutputTimes(outputStartTime, outputEndTime);
                        
                        %Now we check if we have any dependencies
                        [dependentCalcs] = findDependencies(primaryCalc, logger);
                        if ~isempty(dependentCalcs)
                            logger.logInfo("Found %d dependent Calculations of Calculation %s", ...
                                numel(dependentCalcs), primaryCalc.RecordPath);
                            dependentCalcNames = strjoin([dependentCalcs.RecordName], ', ');
                            logger.logTrace("Calculations %s found as dependent Calculation of Calculation %s", dependentCalcNames, primaryCalc.RecordPath)
                            calcsToBackfill = [dependentCalcs, primaryCalc];
                        end

                    end
                    
                    %If the calculation has errored or been turned off do not run the rest
                    %of backfilling
                    if ismember(primaryCalc.BackfillState, ...
                            [cce.CalculationBackfillState.Error, cce.CalculationBackfillState.Off])
                        logger.logInfo("Calculation %s has been set to the %s backfilling state before backfilling completion.", ...
                            primaryCalc.RecordPath, string(primaryCalc.BackfillState));
                        
                    else
                        %Check our progress and update the backfillOutputTimes to start at the
                        %last progress that we marked
                        if (primaryCalc.BackfillState == cce.CalculationBackfillState.Running) && progress > 0
                            t = floor(progress/100*numel(backfillOutputTimes));
                            if t < 1
                                t = 1;
                            end
                            logger.logInfo("Restarting manual execution of Calculation %s at last progress mark: %d%% (%s)", ...
                                primaryCalc.RecordPath, progress, string(backfillOutputTimes(t)));
                        else
                            t = 1;
                            logger.logInfo("Starting manual execution of Calculation %s at time %s", ...
                                primaryCalc.RecordPath, string(min(backfillOutputTimes)));
                        end
                        
                        %Now we check our overwrite settings, if we are not overwriting, we can fill in the missing gaps
                        if ismember(primaryCalc.BackfillState, [cce.CalculationBackfillState.Error, cce.CalculationBackfillState.Off])
                            logger.logInfo("Calculation %s has been set to the %s backfilling state before backfilling completion.", ...
                                primaryCalc.RecordPath, string(primaryCalc.BackfillState));
                        elseif ismember(overwriteSettings, cce.BackfillOverwrite.PrimaryOnly)
                            
                            %If we are overwriting we must 'nuke' all previous values in our
                            %backfilling time range
                            
                            logger.logInfo("Overwriting data for manual execution of Calculation %s (only) in range: (%s) - (%s)", ...
                                primaryCalc.RecordPath, string(backfillStart), string(backfillEnd));
                            clearOutputs(primaryCalc, min(backfillOutputTimes), max(backfillOutputTimes), logger);
                        elseif ismember(overwriteSettings, cce.BackfillOverwrite.All)
                            %If there are dependents and we've chosen to overwrite those too,
                            %then let's 'nuke' the values in the backfilling time range too
                            logger.logInfo("Overwriting data for manual execution of Calculation %s and all dependencies in range: (%s) - (%s)", ...
                                primaryCalc.RecordPath, string(backfillStart), string(backfillEnd));
                            
                            for calc = 1:numel(calcsToBackfill)
                                clearOutputs(calcsToBackfill(calc), min(backfillOutputTimes), max(backfillOutputTimes), logger);
                            end
                        else
                            logger.logInfo("Filling the gaps in data for manual execution of Calculation %s and all dependencies in range: (%s) - (%s)", ...
                                primaryCalc.RecordPath, string(backfillStart), string(backfillEnd));
                        end
                        
                        %Now we are ready to run. Run all of these calculations for each
                        %OutTime
                        backfilling = true;
                        %Setup progress markers
                        progressGranularity = ceil(5/100*numel(backfillOutputTimes));
                        progressPercentage = unique(floor(progressGranularity:progressGranularity:numel(backfillOutputTimes)));
                        
                        currentOutTime = backfillOutputTimes(t);
                        success = true;
                        timeOutCount = 0;
                        timeOutLimit = 10;
                        while backfilling && currentOutTime < max(backfillOutputTimes)
                            if checkForDisabled(coordinator, logger)
                                keepRunning = false;
                            end
                            if ismember(primaryCalc.BackfillState, [cce.CalculationBackfillState.Error, cce.CalculationBackfillState.Off])
                                logger.logInfo("Calculation %s has been set to the %s backfilling state before backfilling completion.", ...
                                    primaryCalc.RecordPath, string(primaryCalc.BackfillState));
                                backfilling = false;
                            else
                                %Run the calculations
                                try
                                    
                                    idxNeedToRun = true(size(calcsToBackfill));
                                    for calc = 1:numel(calcsToBackfill)
                                        hasData = calcsToBackfill(calc).checkOutputHasData(currentOutTime);
                                        idxNeedToRun(calc) = ~hasData;
                                    end
                                    executeBackfilling(coordinator, currentOutTime, primaryCalc, calcsToBackfill(idxNeedToRun), logger);
                                    
                                    % If we have successfully reached any of the progress markers,
                                    % mark the progress in the calculation DB
                                    if any(t == progressPercentage)
                                        primaryCalc.BackfillProgress = floor(t/numel(backfillOutputTimes)*100);
                                        primaryCalc.commit();
                                    end
                                    % If the calculations ran successfully, move to the next outputtime
                                    t = t + 1;
                                    currentOutTime = backfillOutputTimes(t);
                                    timeOutCount = 0;
                                    
                                catch err
                                    isQueueTimeOutError = err.identifier == "MATLAB:webservices:Timeout";
                                    
                                    %If the error is a timeout error, we try again for
                                    %TIMEOUTRETRIESLIMIT number of times for this output time
                                    if isQueueTimeOutError
                                        timeOutCount = timeOutCount +1;
                                    end
                                    %If the error is not a timeout error
                                    if ~isQueueTimeOutError || timeOutCount > timeOutLimit
                                        %Set the backfilling calculation to a backfill error
                                        %state, set the error and quit backfilling this
                                        %calculation.
                                        
                                        primaryCalc.BackfillState = cce.CalculationBackfillState.Error;
                                        
                                        if ~contains(err.identifier, "CCE:ManualExecution")
                                            primaryCalc.BackfillLastError = cce.CalculationErrorState.UnhandledException;
                                            try
                                                msgReport = getReport(err, "extended","hyperlinks","off");
                                            catch
                                                msgReport = getReport(err, "extended");
                                            end
                                            logger.logError("Backfilling Calculation: %s returned an unhandled error: Error Id: %s, Error Message: %s", ...
                                                primaryCalc.RecordPath, ...
                                                err.identifier, msgReport);
                                        end
                                        
                                        primaryCalc.commit();
                                        success = false;
                                        backfilling = false;
                                    end
                                end
                            end
                        end
                        
                        %If we ran to completion set the progress to 100% and set the state to
                        %finished
                        if success
                            primaryCalc.BackfillProgress = 100;
                            primaryCalc.BackfillState = cce.CalculationBackfillState.Finished;
                            primaryCalc.commit();
                            logger.logInfo("Backfilling Calculation: %s Finished", primaryCalc.RecordPath);
                        end
                    end
                end
            end
        end
    end
    setCoordinatorStateIfNotDisabled(coordinator, cce.CoordinatorState.ShuttingDown, logger);
end

function [dependentCalcs] = findDependencies(primaryCalculation, logger)
    
    calculations = cce.Calculation.fetchFromDb([], "Logger", logger);
    
    primaryID = primaryCalculation.CalculationID;
    idxPrimary = [calculations.CalculationID] == primaryID;
    
    directDependencies = cce.findDirectDependencies(calculations);

    % Find the execution order of each calculation
    [executionOrder, fullDependencyList] = cce.getExecutionOrder(calculations, directDependencies);
    
    % Extract the full lower tree of the primary calculation, set the dependencies
    % execution index
    dependentCalcs = fullDependencyList{idxPrimary};
    
    if ~isempty(dependentCalcs)
        [idxDependentCalcs, locDependentCalc] = ismember([calculations.CalculationID], [dependentCalcs.CalculationID]);
        dependentExecutionOrder = executionOrder(idxDependentCalcs);
        dependentExecutionOrder(locDependentCalc(idxDependentCalcs)) = dependentExecutionOrder;
        calculationTree = [dependentCalcs, primaryCalculation];
        treeOrder = [dependentExecutionOrder, executionOrder(idxPrimary)];
    else
        calculationTree = primaryCalculation;
        treeOrder = executionOrder(idxPrimary);
    end
    
    if all(~isnan(treeOrder))
        for c = 1:numel(calculationTree)
            calculationTree(c).ExecutionIndex = treeOrder(c);
        end
    else
        %Circular dependency
        primaryCalculation.ExecutionIndex = 0;
        primaryCalculation.BackfillState = cce.CalculationBackfillState.Error;
        primaryCalculation.BackfillLastError = cce.CalculationErrorState.CircularDependencyChain;
        
        %Add Message to local logs
        circCalcPaths = join([primaryCalculation.RecordPath, calculationTree.RecordPath], ', ');
        logger.logError(join(["Calculation(s): %s form part of a circular dependency chain.", ...
            "\nExecution Order set to 0." ,...
            "\nCalculations in this list must be inspected and the circular dependency resolved"]), ...
            circCalcPaths);
        
        for c = 1:numel(calculationTree)
            calculations(k).ExecutionIndex = 0;
        end
    end
    isRetired = ismember([calculationTree.CalculationState], cce.CalculationState.Retired);
    if any(isRetired)
        %Retired calculation error
        
        primaryCalculation.BackfillState = cce.CalculationBackfillState.Error;
        primaryCalculation.BackfillLastError = cce.CalculationErrorState.RetiredCalculationDependency;
        
        %Add Message to local logs with the retired dependencies
        retCalcPaths = join([calculationTree(isRetired).RecordPath], ', ');
        %Log a warning to the local logs
        logger.logError(join(["Calculation: %s is dependent on Calculation(s)", ...
            "in the Retired CalculationState.\nCalculation(s): %s are retired."]), ...
            primaryCalculation.RecordPath, retCalcPaths);
    end
end

function clearOutputs(calculation, startTime, endTime, logger)
    %CLEAROUTPUTS permanently removes data of CALCULATION between (including) the times
    %STARTTIME and ENDTIME
    
    calculation.clearOutputsTimeRange(startTime, endTime);
    logger.logInfo("Overwriting outputs for Calculation %s in range (%s) - (%s)", ...
        calculation.RecordPath, string(startTime), string(endTime));
end

function executeBackfilling(coordinator, outputTime, primaryCalc, calculations, logger)
    
    % Get greatest execution index
    maxExecOrder = max([calculations.ExecutionIndex]);
    % Create the clientID using the CoordinatorID
    clientID = char(strcat('coordinator', num2str(coordinator.CoordinatorID)));
    % Assume that all calculations are using one CalcServer
    % Create CalcServer object - Use default host and port from config file.
    calcServerObj = CalcServer(clientID);
    
    for executionOrder = 1:maxExecOrder
        % Find the Calculations
        % Check if the Calculation matches the current execution order
        idxExecutionOrder = [calculations.ExecutionIndex] == executionOrder;
        % For dependent Calculations - check that the Calculation's inputs are
        % available for the current outputTime: the Calculation is ready to run.
        if executionOrder > 1
            outputTimeStr = string(outputTime, 'yyyy-MM-dd HH:mm:ss');
            logger.logDebug("Checking dependent inputs for Calculations running at output time: %s", ...
                outputTimeStr);
            locExecutionOrder = find(idxExecutionOrder);
            isReady = false(size(locExecutionOrder));
            dependencyTryCount = 1;
            while any(~isReady) && dependencyTryCount < 5
                for c = 1:numel(locExecutionOrder)
                    isReady(c) = calculations(locExecutionOrder(c)).checkInputsReadyToRun(outputTime);
                end
                dependencyTryCount = dependencyTryCount + 1;
            end
            if any(~isReady)
                logger.logError("Dependent inputs not ready during manual execution of Calculation, %s", ...
                    primaryCalc.RecordPath)
                %Error here to stop backfilling
                primaryCalc.BackfillState = cce.CalculationBackfillState.Error;
                primaryCalc.BackfillLastError = cce.CalculationErrorState.DependentInputsNotReady;
                primaryCalc.commit();
                error("CCE:ManualExecution:CalculationUnhandledError", "Calculation Dependent Inputs Not Ready")
            end
        end
        
        if any(idxExecutionOrder)
            runBackfilling(coordinator, primaryCalc, calculations(idxExecutionOrder), outputTime, calcServerObj, logger);
        end
    end
end

function runBackfilling(coordinator, primaryCalc, calculations, outputTime, calcServerObj, logger)
    %runBackFilling  Run backfilling operations on a set of dependent calculations
    %   This function does not update the calculation state, as it's a backfilling operation.

    % Get Calculation Inputs & Parameters
    logger.logDebug("Backfill: Get calculation inputs", []);
    

    [inputs, parameters, successIdx] = cce.Calculation.getCalculationInputs(outputTime, calculations);
    %Change state of calcs that failed to correctly pull input data, before
    %removing them
    failedInputCalcs = calculations(~successIdx);
    for cI = 1:numel(failedInputCalcs)
        primaryCalc.BackfillState = cce.CalculationBackfillState.Error;
        primaryCalc.BackfillLastError = cce.CalculationErrorState.InputConfigInvalid;
        logger.logError("Calculation %s failed to get calulation inputs, setting CalcState to SystemDisabled and LastError to ConfigurationError.", failedInputCalcs(cI).RecordPath);
        error("CCE:ManualExecution:GetCalculationInputError", "Calculation %s failed to get calulation inputs.", failedInputCalcs(cI).RecordPath);
    end
    
    % Queue Calculations on the Calculation Server
    logger.logDebug("Backfill: Queue calculations for output time %s", string(outputTime));
    queueResult = coordinator.queueCalculations(calcServerObj, inputs, parameters, calculations);
    for cI = 1:numel(calculations)
        logger.logTrace("Backfill: Calculation %s queued with id %s", calculations(cI).RecordPath, queueResult(cI).id);
    end
    
    % Set a timeout for the Calculation run. Make it the largest execution frequency
    maxExecutionFrequency = max([calculations.ExecutionFrequency]);
    if isnan(maxExecutionFrequency)
        maxExecutionFrequency = seconds(100*cce.System.CalcServerTimeout); % Arbitrary decision.
    end
    timeout = datetime('now') + maxExecutionFrequency;
    
    noOfExpectedResults = numel(calculations);
    noOfResults = 0;
    resultsReceived = false(1, noOfExpectedResults);
    
    %Check for results
    outstandingResults = queueResult; % This will shrink over time
    queueRequestIDs = {queueResult.id};
    logger.logTrace("Manual Calcs Queued %d calculations with MLProdServer", numel(outstandingResults));

    up = queueResult(1).up;
    createdSeq = queueResult(1).lastModifiedSeq;
    firstPass = true;
    while (noOfResults < noOfExpectedResults) && (timeout > datetime('now'))
        % Request the status of the calculations from the Calculation Server
        statusRequestResult = calcServerObj.requestCalculationState(createdSeq,up); % TODO: CalcServer class must return structs
        statusRequestResult = calcServerObj.jsonDeserialisation(statusRequestResult);

        if firstPass
            createdSeq = statusRequestResult.createdSeq;
            firstPass = false;
        end

        if ~isempty(statusRequestResult)
            changedResults = statusRequestResult.data;
            % Process them in result order
            mustDelete = false(1,numel(changedResults));
            for ii = 1:numel(changedResults)
                % Find which calc this refers to. We may not match completely, so guard against that.
                [~,calcIdx] = ismember(changedResults(ii).id, queueRequestIDs);
                if (calcIdx>0)
                    % Check the state of the result
                    switch upper(string(changedResults(ii).state))
                        case 'PROCESSING'
                            logger.logTrace("Backfilling: %s; Calculation Running: %s", ...
                                primaryCalc.RecordPath, calculations(calcIdx).RecordPath);
                        case 'READY'
                            % Process the outputs and delete the request.
                            readyCalc = calculations(calcIdx);
                            logger.logTrace("Backfilling Calculation: %s; Calculation Ready: %s", ...
                                primaryCalc.RecordPath, readyCalc.RecordPath);
                        
                            % Get and format the Calculation outputs
                            result = calcServerObj.getCalculationResults(changedResults(ii));
                            output = calcServerObj.formatCalcOutput(result);
                        
                            % Check if an output + a handled error (or good state)
                            % are returned or if an unhandled error has been
                            % returned
                            if isfield(output, 'error')
                                % UNHANDLED ERROR: Returns the MException.
                                output = output.error;
                                % Write the returned error message to the logs
                                logger.logError("Backfilling Calculation: %s; Calculation Errored: %s, Error message: %s", ...
                                    primaryCalc.RecordPath, readyCalc.RecordPath, output.message);
                            
                                %We need to error here
                                primaryCalc.BackfillState = cce.CalculationBackfillState.Error;
                                primaryCalc.BackfillLastError = cce.CalculationErrorState.UnhandledException;
                                primaryCalc.commit();
                                % Delete all outstanding calculations
                                for dI = 1:numel(outstandingResults)
                                    calcServerObj.deleteRequest(outstandingResults(dI).self);
                                end
                                error("CCE:ManualExecution:CalculationUnhandledError", output.message);
                            else
                                % OUTPUT + HANDLED ERROR (or Good): Returns an error code with the data even when it is good

                                % Get the outputs and the returned cce.CalculationErrorState
                                calcOutputs = output.lhs{1};
                                errorCode = cce.CalculationErrorState(output.lhs{2}.mwdata);

                                % Check if outputs returned are empty
                                if ~any(structfun(@isempty, calcOutputs))
                                    timestamp = calcOutputs.Timestamp.mwdata.TimeStamp;
                                    timestamp = timestamp/1000;
                                    calcOutputs.Timestamp = datetime(timestamp, 'convertFrom', 'posixtime');
                                    logger.logTrace("Backfilling Calculation: %s; Calculation Writing Outputs: %s", ...
                                        primaryCalc.RecordPath, readyCalc.RecordPath);
                                    readyCalc.writeOutputs(calcOutputs);
                                end

                                %Error here if there was and error
                                if isFatal(errorCode)
                                    logger.logError("Backfilling Calculation: %s; Calculation Errored: %s", ...
                                        primaryCalc.RecordPath, readyCalc.RecordPath);

                                    primaryCalc.BackfillState = cce.CalculationBackfillState.Error;
                                    primaryCalc.BackfillLastError = errorCode;
                                    primaryCalc.commit();
                                    % Delete all outstanding calculations
                                    for dI = 1:numel(outstandingResults)
                                        calcServerObj.deleteRequest(outstandingResults(dI).self);
                                    end
                                    error("CCE:ManualExecution:CalculationHandledError", "Calculation returned the handled error: %s", ...
                                        string(errorCode))
                                end

                                noOfResults = noOfResults+1;
                                resultsReceived(calcIdx) = true;
                                mustDelete(ii) = true; % Defer deleting until the end.
                            end
                        case 'ERROR'
                            % The calculation returned an error.
                            erroredCalc = calculations(calcIdx);
                            errorResult = calcServerObj.getCalculationResults(changedResults(ii));
                            errorResult = calcServerObj.jsonDeserialisation(errorResult);
                            errorResult = errorResult.error;
                            logger.logError("Backfilling Calculation: %s; Calculation Errored: %s, Error Type: %s, Error Id: %s, Error Message: %s", ...
                                primaryCalc.RecordPath, erroredCalc.RecordPath, ...
                                errorResult.type, errorResult.messageId, errorResult.message);

                            %We need to stop running & error here
                            primaryCalc.BackfillState = cce.CalculationBackfillState.Error;
                            primaryCalc.BackfillLastError = cce.CalculationErrorState.UnhandledException;
                            primaryCalc.commit();
                            % Delete all outstanding calculations
                            for dI = 1:numel(outstandingResults)
                                calcServerObj.deleteRequest(outstandingResults(dI).self);
                            end
                            error("CCE:ManualExecution:CalculationResultError", "Calculation resulted in an unhandled error: Error Id: %s, Error Message: %s", ...
                                errorResult.messageId, errorResult.message)
                    end
                else
                    logger.logTrace("Request result %s not found in calculations. Ignoring", outstandingResults(ii).id);
                end
            end
            % Now delete the requests we've handled
            requestsToDelete = changedResults(mustDelete);
            % ensure that the correct calc in outstandingResults is removed
            mustDeleteIdx = ismember({outstandingResults.id}, {requestsToDelete.id});
            for dI = 1:numel(requestsToDelete)
                logger.logTrace("Deleting handled request id %s", requestsToDelete(dI).self);
                calcServerObj.deleteRequest(requestsToDelete(dI).self); %TODO: Check the result
            end

            outstandingResults(mustDeleteIdx) = [];
        end
    end
    
    % If the number of Calculation results returned was fewer than the number of
    % Calculations queued to run
    if noOfResults ~= noOfExpectedResults
        for ii = 1:numel(calculations)
            if resultsReceived(ii) == 0
                logger.logError("Timeout Error: %s", calculations(ii).RecordPath);
            end
        end
        % Delete the outstanding results because we're not interested in the outputs any more
        for dI = 1:numel(outstandingResults)
            % Delete this request. 
            try
                calcServerObj.deleteRequest(outstandingResults(dI).self);
            catch MExc
                logger.logError("Could not delete a queued calculation. Error was %s", MExc.identifier);
            end
        end
        if any(resultsReceived == 0)
            %We need to error here
            primaryCalc.BackfillState = cce.CalculationBackfillState.Error;
            primaryCalc.BackfillLastError = cce.CalculationErrorState.QueueTimeout;
            primaryCalc.commit();
            error("CCE:ManualExecution:CalculationTimeout", "Calculation timed out before completion")
        end
    end
    setCoordinatorStateIfNotDisabled(coordinator, cce.CoordinatorState.ShuttingDown, logger)
end