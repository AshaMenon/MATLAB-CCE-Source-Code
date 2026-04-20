classdef tConfigurator < matlab.unittest.TestCase
    %TCONFIGURATOR Test configurator execution
    %
    % WARNING! Before running - For creating scheduled tasks, MATLAB must be run as
    % administrator.
    %
    %TCONFIGURATOR tests that the Configurator properly assigns and removes Calculations
    %to and from Coordinators as necessary. To completely test the Configurator execution
    %the following Coordinator and Calculation configurations must be found on the test Database:
    %
    % Parameter Set 1 - ExecutionMode: Cyclic, ExecutionFrequency: 20s, ExecutionOffset: 0s
    % Parameter Set 2 - ExecutionMode: Cyclic, ExecutionFrequency: 600s, ExecutionOffset: 3600s
    % Parameter Set 3 - ExecutionMode: Event, ExecutionFrequency: NaNs, ExecutionOffset: 0s
    % Parameter Set 4 - ExecutionMode: Cyclic, ExecutionFrequency: 600s, ExecutionOffset: 0s
    %
    % Coordinator1 - Execution parameter set 1, Load: 1
    % Coordinator2 - Execution parameter set 2, Load: 2
    %
    % Calculation1  -   Execution parameter set 1, assigned to Coordinator1 (Assigned
    %                   correctly)
    % Calculation2  -   Execution parameter set 1, assigned to Coordinator2 (Modified -
    %                   previously set 2)
    % Calculation3  -   Execution parameter set 1, not assigned to a Coordinator
    %                   (NotAssigned)
    % Calculation4  -   Execution parameter set 2, not assigned to a Coordinator
    %                   (NotAssigned)
    % Calculation5  -   Execution parameter set 3, not assigned to a Coordinator
    %                   (NotAssigned - New Parameters)
    % Calculation6  -   Execution parameter set 3, not assigned to a Coordinator
    %                   (NotAssigned - New Parameters)
    % Calculation7  -   Execution parameter set 2, assigned to Coordinator2, Retired
    %                   Calculation State (Retired Calculation State - CoordinatorID = 2)
    % Calculation8  -   Execution parameter set 2, not assigned to a Coordinator, Retired
    %                   Calculation State (Retired Calculation State - CoordinatorID = 0)
    % Calculation9  -   Execution parameter set 4, assigned to Deleted Coordinator 4 but
    %                   left in a running state (Idle - CoordinatorID = 4)
    % Calculation10	-   Execution parameter set 4, not assigned to a Coordinator but left
    %                   in a running state (Idle - CoordinatorID = 0)
    % Calculation11	-   Dependent Calculation, dependent on Calculation12 & Calculation13,
    %                   Execution parameter set 1 (NotAssigned) - aka sensor E
    % Calculation12 -   Execution parameter set 1 (NotAssigned) - aka sensor H
    % Calculation13 -   Execution parameter set 1 (NotAssigned)- aka sensor I
    % Calculation14 -   Dependent Calculation, dependent on Calculation15 & Calculation13,
    %                   Execution parameter set 1 (NotAssigned)
    % Calculation15 -   Disabled, Execution parameter set 1 (NotAssigned)
    % Calculation16 -   Dependent Calculation, dependent on Calculation18 & Calculation13,
    %                   Execution parameter set 1 (NotAssigned)
    % Calculation17 -   Retired, Execution parameter set 1 (NotAssigned)
    % Calculation18 -   Circular Dependent Calculation, dependent on Calculation21 &
    %                   Calculation13
    % Calculation19 -	Circular Dependent Calculation, dependent on Calculation20
    % Calculation20 to n(enough calculations to overload a coordinator)	- Execution
    %                    parameter set 1, not assigned to a Coordinator (NotAssigned)
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    
    properties (Constant)
        CCERootPathForTest = fullfile(fileparts(fileparts(mfilename("fullpath"))),"resources","configRoot");
    end
    properties
        %Store original states for teardown - restore states
        OriginalCalculations = cce.Calculation.fetchFromDb([]);
        OriginalSchedules = SchedulerTask.fetchFromScheduler(SchedulerTaskService, folderName=cce.getTaskPath([]));
        OriginalCCERootEnv
        
        CoordIDs
        CoordLoad
        CoordMode
        CoordFrequency
        CoordOffset
        
        CalcCoordIDs
        CalcState
        CalcMode
        CalcFrequency
        CalcOffset
        CalcExecutionIndex
        
        OriginalTaskNames
        OriginalTaskArguments
        
        %Refresh calculation & coordinator records after configurator run
        Coordinators
        Calculations
    end
    
    methods (TestClassSetup)
        function setCCEConfig(tc)
            tc.OriginalCCERootEnv = getenv("CCE_Root");
            setenv("CCE_Root", tc.CCERootPathForTest);
        end
        function storeAFOriginalState(testcase)
            %STOREAFORIGINALSTATE
            
            coordinators = cce.Coordinator.fetchFromDb([]);
            testcase.CoordIDs = [coordinators.CoordinatorID];
            testcase.CoordLoad = [coordinators.CalculationLoad];
            testcase.CoordMode = [coordinators.ExecutionMode];
            testcase.CoordFrequency = [coordinators.ExecutionFrequency];
            testcase.CoordOffset = [coordinators.ExecutionOffset];
            
            calculations = testcase.OriginalCalculations;
            testcase.CalcCoordIDs = [calculations.CoordinatorID];
            testcase.CalcState = [calculations.CalculationState];
            testcase.CalcMode = [calculations.ExecutionMode];
            testcase.CalcFrequency = [calculations.ExecutionFrequency];
            testcase.CalcOffset = [calculations.ExecutionOffset];
            testcase.CalcExecutionIndex = [calculations.ExecutionIndex];
            
            testcase.OriginalTaskNames = [testcase.OriginalSchedules.Name];
            
            %Run Configurator!
            sprintf('Running the configurator');
            cceConfigurator();
            sprintf('Done');
            
            %Store calculations and coordinators after configurator run
            testcase.Coordinators = cce.Coordinator.fetchFromDb([]);
            testcase.Calculations = cce.Calculation.fetchFromDb([]);
        end
    end
    
    methods (TestClassTeardown)
        function restoreCCERoot(tc)
            %restoreCCERoot  Restore CCE_Root environment variable
            setenv("CCE_Root",tc.OriginalCCERootEnv);
        end
        function restoreAFState(testcase)
            
            coordinators = cce.Coordinator.fetchFromDb([]);
            coordIDs = [coordinators.CoordinatorID];
            
            %Restore coordinator loads
            for c = 1:numel(testcase.CoordIDs)
                thisID = coordIDs == testcase.CoordIDs(c);
                idxOrigCalc = testcase.CoordIDs == testcase.CoordIDs(c);
                originalLoad = testcase.CoordLoad(idxOrigCalc);
                coordinators(thisID).CalculationLoad = originalLoad;
                coordinators(thisID).commit();
            end
            
            %Remove any created coordinators
            isNewCoord = ~ismember(coordIDs, testcase.CoordIDs);
            coordIDToRemove = coordIDs(isNewCoord);
            for c = 1:sum(isNewCoord)
                %Remove elements from DB
                cce.Coordinator.removeFromDb(coordIDToRemove(c));
            end
            
            %Restore calculation record to original values
            for c = 1:numel(testcase.OriginalCalculations)
                testcase.OriginalCalculations(c).CoordinatorID = testcase.CalcCoordIDs(c);
                testcase.OriginalCalculations(c).CalculationState = testcase.CalcState(c);
                testcase.OriginalCalculations(c).ExecutionIndex = testcase.CalcExecutionIndex(c);
                testcase.OriginalCalculations(c).commit();
            end
            
            %Remove any added schedule tasks
            allCoordTasks = SchedulerTask.fetchFromScheduler(SchedulerTaskService, folderName=cce.getTaskPath([]));
            allCoordTaskNames = [allCoordTasks.Name];
            if ~isempty(testcase.OriginalTaskNames)
                [idxNewTask] = ~ismember(allCoordTaskNames, testcase.OriginalTaskNames);
            else
                idxNewTask = true(size(allCoordTaskNames));
            end
            locNewTask = find(idxNewTask);
            taskSchedulerService = SchedulerTaskService;
            for c = 1:sum(idxNewTask)
                SchedulerTask.removeFromScheduler(taskSchedulerService, allCoordTaskNames(locNewTask(c)), folderName=cce.getTaskPath([]))
            end
        end
    end
    
    methods (Test)
        function tDeletedCoordinators(testcase)
            %TDELETEDCOORDINATORS Check that Active Calculations assigned to deleted
            %Coordinators, or Active Calculations that have been improperly removed from a
            %deleted Coordinator are properly reassigned (running state and non-zero CoordinatorID).
            % To properly test manually delete a coordinator in WACP that has a calc assigned to it,
            % and set CCE root to custom config with your pc's username and encrypted password
            
            idxActiveState = ~ismember(testcase.CalcState, ...
                [cce.CalculationState.NotAssigned, cce.CalculationState.Retired,...
                cce.CalculationState.Disabled, cce.CalculationState.SystemDisabled, cce.CalculationState.ConfigurationError]);
            idxActiveAssignedToDeleted = idxActiveState & (testcase.CalcCoordIDs ~= 0 & ~ismember(testcase.CalcCoordIDs, testcase.CoordIDs));
            idxActiveZero = idxActiveState & testcase.CalcCoordIDs == 0;
            
            calculations = testcase.Calculations(idxActiveAssignedToDeleted | idxActiveZero);
            state = [calculations.CalculationState];
            idxActive = ~ismember(state, [cce.CalculationState.NotAssigned, cce.CalculationState.Retired,...
                cce.CalculationState.Disabled, cce.CalculationState.SystemDisabled, cce.CalculationState.ConfigurationError]);
            idxAssigned = [calculations.CoordinatorID] ~= 0;
            
            testcase.verifyTrue(all(idxActive & idxAssigned));
            
            coordinatorIDs = [testcase.Coordinators.CoordinatorID];
            testcase.verifyTrue(all(ismember([calculations.CoordinatorID], coordinatorIDs)));
        end
        
        function tDependentCalculations(testcase)
            %TDEPENDENTCALCULATIONS
            
            %T1 - if any execution index is zero check that all are set to
            %ConfigurationError state
            isZeroIndex = [testcase.Calculations.ExecutionIndex] == 0;
            calculations = testcase.Calculations(isZeroIndex);
            idxErrorState = ismember([calculations.CalculationState], cce.CalculationState.ConfigurationError);
            testcase.verifyTrue(all(idxErrorState));
            
            %T2 - if there are any calculations with a non-zero execution index but are in
            %a ConfigurationError state, that there are retired calculations
            calculations = testcase.Calculations(~isZeroIndex);
            idxErrorState = ismember([calculations.CalculationState], cce.CalculationState.ConfigurationError);
            if any(idxErrorState)
                isRetiredCalc = ismember([testcase.Calculations.CalculationState], cce.CalculationState.Retired);
                testcase.verifyTrue(any(isRetiredCalc));
            else
                warning("tConfigurator:RetiredDependency", "No dependency on retired calculations has been tested")
            end
        end
        
        function tLoads(testcase)
            %TLOADS ensure that the calculation loads of each coordinator align with the
            %number of calculations that are assigned to that CoordinatorID

            %RM TODO: Does this still hold for inactive calcs with
            %incorrect coordinators - I dont think so.
            
            coordinators = testcase.Coordinators;
            coordIDs = [coordinators.CoordinatorID];
            calcLoads = [coordinators.CalculationLoad];
            
            calculations = testcase.Calculations;
            assignedCoordIDs = [calculations.CoordinatorID];
            
            for c = 1:numel(coordIDs)
                %T1 - Check that the correct number of calculations are assigned to each
                %coordinator
                thisID = coordIDs(c);
                idxAssignedToCoord = assignedCoordIDs == thisID;
                testcase.verifyEqual(sum(idxAssignedToCoord), double(calcLoads(c)));
            end
        end
        
        function tExecutionParameters(testcase)
            %TEXECUTIONPARAMETERS check that all active calculations are assigned to
            %coordinators with the correct execution parameters
            
            %RM - TODO - this should fail if there are any disabled/system
            %disabled/configuration errors present??
            %RM - this fails due to a "Single" calc issue.

            coordinators = testcase.Coordinators;
            coordIDs = [coordinators.CoordinatorID];
            execMode = [coordinators.ExecutionMode];
            execFreq = [coordinators.ExecutionFrequency];
            execOffset = [coordinators.ExecutionOffset];

            allCalculations = testcase.Calculations;
            calculationsActiveIdx = cce.isCalculationActive([allCalculations.CalculationState]);
            calculations = allCalculations(calculationsActiveIdx);

            assignedCoordIDs = [calculations.CoordinatorID];
            calcMode = [calculations.ExecutionMode];
            calcFreq = [calculations.ExecutionFrequency];
            calcOffset = [calculations.ExecutionOffset];
            
            for c = 1:numel(coordIDs)
                %T1 - Check that the correct number of calculations are assigned to each
                %coordinator
                thisID = coordIDs(c);
                idxAssignedToCoord = assignedCoordIDs == thisID;
                
                testcase.verifyTrue(all(calcMode(idxAssignedToCoord) == execMode(c)));
                testcase.verifyTrue(all(calcFreq(idxAssignedToCoord) == execFreq(c) | ...
                    (all(isnan(calcFreq(idxAssignedToCoord))) & isnan(execFreq(c)))));
                testcase.verifyTrue(all(calcOffset(idxAssignedToCoord) == execOffset(c)));
            end
        end
        
        function tCalcStates(testcase)
            %TCALCSTATES ensure that all calculations assigned to a coordinator have an
            %active calculation state - i.e. not Retired or NotAssigned
            
            coordinators = testcase.Coordinators;
            coordIDs = [coordinators.CoordinatorID];
            
            calculations = testcase.Calculations;
            assignedCoordIDs = [calculations.CoordinatorID];
            calcStates = [calculations.CalculationState];
            
            for c = 1:numel(coordIDs)
                thisID = coordIDs(c);
                idxAssignedToCoord = assignedCoordIDs == thisID;
                %T1 - Check that all assigned calculations are not in the NotAssigned or
                %Retired states
                isActiveCalc = calcStates(idxAssignedToCoord) ~= cce.CalculationState.Retired & ...
                    calcStates(idxAssignedToCoord) ~= cce.CalculationState.NotAssigned;
                testcase.verifyTrue(all(isActiveCalc));
            end
            
            %T2 - Check that all previously NotAssigned calculations are now in an active
            %calculation state
            wasNotAssigned = testcase.CalcState == cce.CalculationState.NotAssigned;
            newStates = calcStates(wasNotAssigned);
            isNowActiveCalc = newStates ~= cce.CalculationState.Retired & ...
                newStates ~= cce.CalculationState.NotAssigned;
            testcase.verifyTrue(all(isNowActiveCalc));
        end
        
        function tRetiredCalcs(testcase)
            %TRETIREDCALCS tests that retired calcs are removed from their corresponding Coordinator
            
            %Find calculations that were originally in the retired state but not yet
            %properly retired (removed from their (previously) assigned coordinator
            isRetired = testcase.CalcState == cce.CalculationState.Retired;
            isNewRetired = isRetired & (testcase.CalcCoordIDs ~= 0);
            
            if any(isNewRetired)
                retCoordID = [testcase.Calculations(isNewRetired).CoordinatorID];
                hasNoCoord = retCoordID == 0;
                %T1 - all newly retired coordinators have been assigned the default
                %coordinatorID
                testcase.verifyTrue(all(hasNoCoord));
            else
                error("TRETIREDCALCS:NoNewRetiredCalcsFound", "No newly retired calculations were found on the DB, retiring of calculations is not tested!")
            end
        end

        function tModifiedCalcs(testcase)
            %TMODIFIEDCALCS tests that calculations that have been modified, resulting in
            %execution parameters that no longer match their assigned coordinator's
            %parameters, are removed from their coordinator and assigned to an appropriate
            %one
            
            %Find previously assigned calculations that had been modified (changed execution parameters)
            isActive = testcase.CalcState ~= cce.CalculationState.Retired & ...
                testcase.CalcState ~= cce.CalculationState.NotAssigned & ...
                testcase.CalcState ~= cce.CalculationState.ConfigurationError; %RM - assume if configuration error that it doesnt matter

            origAssignedIDs = testcase.CalcCoordIDs(isActive);
            mode = testcase.CalcMode(isActive);
            freq = testcase.CalcFrequency(isActive);
            offset = testcase.CalcOffset(isActive);
            
            coordIDs = testcase.CoordIDs;
            [isActiveCoord, whichCoord] = ismember(origAssignedIDs, coordIDs);
            mode = mode(isActiveCoord);
            assignedCoordModes = testcase.CoordMode(whichCoord(isActiveCoord));
            freq = freq(isActiveCoord);
            assignedCoordFreq = testcase.CoordFrequency(whichCoord(isActiveCoord));
            offset = offset(isActiveCoord);
            assignedCoordOffset = testcase.CoordOffset(whichCoord(isActiveCoord));
            
            isDiffMode = mode ~= assignedCoordModes;
            isDiffFreq = freq ~= assignedCoordFreq & ~(isnan(freq) & isnan(assignedCoordFreq));
            isDiffOffset = offset ~= assignedCoordOffset;
            isModified = isDiffMode | isDiffFreq | isDiffOffset | origAssignedIDs(isActiveCoord) == 0;
            
            %T1 - Check that they are no longer assigned to the wrong coordinator
            if any(isModified)
                [row, col] = find(isActive);
                calculations = cce.Calculation.empty;
                row = row(isModified);
                col = col(isModified);
                for k = 1:sum(isModified)
                    calculations(k) = testcase.Calculations(row(k), col(k));
                end
                
                calcCoordIDs = [calculations.CoordinatorID];
                testcase.verifyTrue(all(calcCoordIDs ~= origAssignedIDs(isModified)));
            else
                error("TMODIFIEDCALCS:NoModifiedCalcsFound", "No modified calculations were found on the DB, reassigning of modified calculations is not tested!")
            end
        end
        
        function tNewExecutionParameters(testcase)
            %TNEWEXECUTIONPARAMETERS tests that calculations with new execution parameters
            %(execution parameters that are not currently found in any of the existing
            %coordinators) result in the creation of a new coordinator and all
            %corresponding calculations are assigned to it
            
            isActive = testcase.CalcState ~= cce.CalculationState.Retired;
            mode = testcase.CalcMode(isActive);
            freq = testcase.CalcFrequency(isActive);
            offset = testcase.CalcOffset(isActive);
            
            isNewMode = ~ismember(mode, testcase.CoordMode);
            isNewFreq = ~ismember(freq, testcase.CoordFrequency) & ~(isnan(freq) & any(isnan(testcase.CoordFrequency)));
            isNewOffset = ~ismember(offset, testcase.CoordOffset);
            isNewExecutionParam = isNewMode | isNewFreq | isNewOffset;
            
            if any(isNewExecutionParam)
                newParameterCalcs = testcase.Calculations(isNewExecutionParam);
                newCoordIDs = [newParameterCalcs.CoordinatorID];
                newCoordIDs = unique(newCoordIDs);
                isNew = ~ismember(newCoordIDs, testcase.CoordIDs);
                testcase.verifyTrue(all(isNew));
            else
                error("TNEWEXECUTIONPARAMETERS:NoNewExecutionParametersFound", "No Calculations with new execution parameters were found on the DB, creation of new Coordinators for new execution parameters has not been tested!")
            end
        end
        
        function tLoadBalance(testcase)
            %TLOADBALANCE
            
            %Find coordinators with matching execution parameters and check that they are
            %load-balanced
            matches = zeros(1, numel(testcase.Coordinators));
            k = 1;
            
            mode = [testcase.Coordinators.ExecutionMode];
            freq = [testcase.Coordinators.ExecutionFrequency];
            offset = [testcase.Coordinators.ExecutionOffset];
            while k <= numel(testcase.Coordinators)
                
                if matches(k) == 0
                    isSameMode = ismember(mode, mode(k));
                    isSameFreq = ismember(freq, freq(k)) | (isnan(freq) & isnan(freq(k)));
                    isSameOffset = ismember(offset, offset(k));
                    isSameParam = isSameMode & isSameFreq & isSameOffset;
                    
                    matches(isSameParam) = testcase.Coordinators(k).CoordinatorID;
                end
                
                k = k+1;
            end
            
            uniqueIds = unique(matches);
            instancesOfIds = sum(matches == uniqueIds(:), 2);
            if any(instancesOfIds > 1)
                uniqueIds = uniqueIds(instancesOfIds > 1);
                for c = 1:numel(uniqueIds)
                    idxCoords = matches == uniqueIds(c);
                    coordLoads = [testcase.Coordinators(idxCoords).CalculationLoad];
                    diffLoads = abs(coordLoads - min(coordLoads));
                    testcase.verifyLessThanOrEqual(diffLoads, 1);
                end
            else
                error("TOVERLOADCOORDINATOR:NoCoordinatorOverloadingFound", "Creation of Coordinators due to overloading and Coordinator load-balancing has not been tested!")
            end
        end
        function tScheduledTasks(testcase)
            %TSCHEDULEDTASKS check that a scheduled task exists for each Coordinator that
            %has a non-zero Calculation Load
            
            [taskPath] = cce.getTaskPath([]);
            allCoordTasks = SchedulerTask.fetchFromScheduler(SchedulerTaskService, folderName=taskPath);
            allCoordTaskNames = [allCoordTasks.Name];
            
            coordinators = testcase.Coordinators;
            loads = [coordinators.CalculationLoad];
            hasCalcs = loads ~= 0;
            ids = [coordinators(hasCalcs).CoordinatorID];
            
            for c = 1:numel(ids)
                [~, taskName] = cce.getTaskPath(ids(c));
                taskExists = ismember(allCoordTaskNames, taskName);
                testcase.verifyTrue(any(taskExists));
            end
            
        end

        function tSkipBackfill(testcase)
            %TSKIPBACKFILL check that all active calculations are assigned to
            %coordinators with the correct skip backfill attribute

            coordinators = testcase.Coordinators;
            coordIDs = [coordinators.CoordinatorID];
            coordSkipBackfill = [coordinators.SkipBackfill];

            allCalculations = testcase.Calculations;
            calculationsActiveIdx = cce.isCalculationActive([allCalculations.CalculationState]);
            calculations = allCalculations(calculationsActiveIdx);

            assignedCoordIDs = [calculations.CoordinatorID];
            calcSkipBackfill = [calculations.SkipBackfill];
            
            for c = 1:numel(coordIDs)
                %T1 - Check that the correct number of calculations are assigned to each
                %coordinator
                thisID = coordIDs(c);
                idxAssignedToCoord = assignedCoordIDs == thisID;
                
                testcase.verifyTrue(all(calcSkipBackfill(idxAssignedToCoord) == coordSkipBackfill(c)));
            end
        end
    end
end

