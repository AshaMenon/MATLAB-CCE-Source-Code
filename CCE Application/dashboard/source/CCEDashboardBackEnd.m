classdef CCEDashboardBackEnd < handle
    %CCEDASHBOARDBACKEND back end of CCEDashboard - contains data intensive
    %methods, not responsible for any direct visualisation
    
    properties (Access = public)
        CollectedCalcsOfRootAndTemplate (1, :) af.Element %Table of elements (calculations)
        CalcsOfState (1, :) af.Element %CollectedCalcsOfRootAndTemplate but filtered by state
        FilteredCalcs (1, :) af.Element %Finally filtered calcs
        SelectedCalcs (1, :) af.Element %Table selected calcs

        FilteredCalcInfoTab table %FilteredCalcs attrib value table
        SelectedCalcInfoTab table %SelectedCalcs attrib value table

        CollectedCoords af.Element %Table of Elements (coordinators)
        CoordAttributeTable table %Table of coord attributes
        DataConnector af.AFDataConnector
    end

    properties (Access = private)
        FrontEnd CCEDashboardFrontEnd
    end


    methods (Access = public)
        %Constructor
        function obj = CCEDashboardBackEnd(app)
            obj.FrontEnd = app;
        end

        function [success, message] = connectToDB(obj, serverName, dbName)
            arguments
                obj CCEDashboardBackEnd
                serverName (1, 1) string
                dbName (1, 1) string
            end

            %Connect
            message = "";
            try
                obj.DataConnector = af.AFDataConnector(serverName, dbName);
                obj.DataConnector.refreshAFDbCache;
                success = true;
            catch err
                success = false;
                message = err.message;
                return;
            end 
        end

        function [rootElemNames, rootElemChildrenNames] = getRootElementsWithChildren(obj)

            %Populate root elements
            searchPattern = "AllDescendants:False";
            rootElemList = af.Element.find(searchPattern, "Connector",  obj.DataConnector);
            rootElemNames = [rootElemList.Name];

            %Loop through root elements, get available children for each
            rootElemChildrenNames = cell(numel(rootElemList), 1);
            for iRootElem = 1:numel(rootElemList)
                rootElemChildrenNames{iRootElem} = [rootElemList(iRootElem).Children.Name];
            end

        end

        function childElementNames = getChildElements(obj, elementRootStringArray)
            %GETCHILDELEMENTS uses elementRootString to find all children
            %for a given element path. 

            rootStr = "'" + join(elementRootStringArray, "\") + "'";

            searchPattern = "AllDescendants:False Root:" + rootStr;
            childElements = af.Element.find(searchPattern, "Connector",  obj.DataConnector);
            childElementNames = [childElements.Name];
        end
        
        function calcTemplateList = getCalcTemplates(obj, filterString)
            %Populate calculation template types
            [template] = obj.DataConnector.findTemplateByName("CCECalculation");
            derivedTemplates = af.AFDataConnector.findDerivedTemplates(template);

            derivedNames= strings(derivedTemplates.Count, 1);
            for iDerivedTemp = 1:derivedTemplates.Count
                derivedNames(iDerivedTemp) = derivedTemplates.Item(iDerivedTemp - 1).Name;
            end
            calcTemplateList = derivedNames;
            calcTemplateList = calcTemplateList(contains(calcTemplateList, filterString));
        end

        function collectCalcsOfRootAndTemplate(obj, elemParentTextArray, calcTemplateString)
            %FIRST LEVEL FILTERING

            %Fetches all calcs using the root and template
            rootStr = strings(numel(elemParentTextArray), 1);
            for iParent = 1:numel(elemParentTextArray)
                rootStr(iParent) = "'" + string(join(elemParentTextArray{iParent}, "\")) + "'";
            end
            templateString = strings(numel(calcTemplateString), 1);
            for iTemplate = 1:numel(calcTemplateString)
                templateString(iTemplate) = "'" + calcTemplateString(iTemplate) + "'";
            end

            childElements = af.Element.empty;
            for iParent = 1:numel(rootStr)
                for iTemplate = 1:numel(templateString)
                    searchPattern = "Root:" + rootStr(iParent) + " Template:" + templateString(iTemplate);
                    childElement = af.Element.find(searchPattern, "Connector",  obj.DataConnector);
                    childElements = [childElements, childElement]; %#ok<AGROW>
                end
            end


            obj.CollectedCalcsOfRootAndTemplate = childElements;
        end

        function filterByCalcState(obj, calcStateList)
            %SECOND LEVEL FILTERING

            %GETUSEDCOORDINATORS uses CollectedCalcsOfRootAndTemplate, along
            %with the selected Calc states populate calcs of state array

            if isempty(calcStateList)
                %NO filtering needed
                obj.CalcsOfState = obj.CollectedCalcsOfRootAndTemplate;
            else
                %Filter by states
                numCalcs = numel(obj.CollectedCalcsOfRootAndTemplate);
                stateIdx = false(numCalcs, 1);
                for iCalc = 1:numCalcs
                    calcState = obj.CollectedCalcsOfRootAndTemplate(iCalc).getAttributeValue("CalculationState");
                    if ~isstring(calcState)
                        calcState = "PIPointMissing";
                    end
                    if ismember(calcState, calcStateList)
                        stateIdx(iCalc) = true;
                    end
                end
                obj.CalcsOfState = obj.CollectedCalcsOfRootAndTemplate(stateIdx);
            end
        end

        function uniqueCoordIDS = getUsedCoordinators(obj)
            %Loops through first level filtered calcs, gets coordinator
            %ID's
            coordIds = zeros(numel(obj.CalcsOfState), 1);
            for iFiltCalc = 1:numel(obj.CalcsOfState)
                coordIds(iFiltCalc) = obj.CalcsOfState(iFiltCalc).getAttributeValue("CoordinatorID");
            end
            uniqueCoordIDS = sort(unique(coordIds));
        end

        function filterCalcsByCoord(obj, coordFilterList)
            %filterCalcsByCoord filters CalcsOfState down to calcs of a
            %given coordinator/coordinators

            arguments
                obj CCEDashboardBackEnd
                coordFilterList double
            end
            
            if isempty(coordFilterList)
                %If no coordinators specd, use all
                obj.FilteredCalcs = obj.CalcsOfState;
            else
                %Loop through calcs, checking coordinators, keeping ones
                %that match
                coordIds = zeros(numel(obj.CalcsOfState), 1);
                for iCalc = 1:numel(obj.CalcsOfState)
                    coordIds(iCalc) = obj.CalcsOfState(iCalc).getAttributeValue("CoordinatorID");
                end
                filterIdx = ismember(coordIds, coordFilterList);
                obj.FilteredCalcs = obj.CalcsOfState(filterIdx);
            end
        end

        function getSelectedCalcs(obj, selectionIDX, numVars)
            %GetSelectedCalcs uses the selection index to reduce the calc
            %list
            if isempty(selectionIDX)
                if numVars > 0
                    obj.SelectedCalcs = obj.FilteredCalcs;
                    obj.SelectedCalcInfoTab = obj.FilteredCalcInfoTab;
                else
                    obj.SelectedCalcs = [];
                    obj.SelectedCalcInfoTab = [];
                    warning("No calcs to plot.");
                end

            else
                obj.SelectedCalcs = obj.FilteredCalcs(selectionIDX);
                obj.SelectedCalcInfoTab = obj.FilteredCalcInfoTab(selectionIDX, :);
            end

        end

        function [calcStateCell, keepIdx] = getCalcStateHist(obj, st, et)
            %Loop through calculations, getting state history. Puts each
            %calc history time table into a cell array.
            calcs = obj.SelectedCalcs;
            
            %Remove PIPointMissing calcs
            noPiPtIdx = ismember(obj.SelectedCalcInfoTab.("Current State"), "PIPointMissing");
            calcs = calcs(~noPiPtIdx);
            keepIdx = ~noPiPtIdx;

            calcStateCell = cell(numel(calcs), 1);
            for iCalc = 1:numel(calcs)
                [values, timestamps, ~] = calcs(iCalc).getHistoricalAttributeValues(...
                    "CalculationState", [string(st); string(et)]);
                calcStateCell{iCalc} = array2timetable(values', "RowTimes", timestamps', "VariableNames", "calcState");
            end

            %Remove NaNs etc
            if ~isempty(calcStateCell)
                removeCalc = false(numel(calcStateCell), 1);

                %Remove nans
                for iCalc = 1:numel(calcStateCell)
                    calcTab = calcStateCell{iCalc};

                    %Remove nans
                    calcTab(isnan(calcTab.calcState) | isnat(calcTab.Time), :) = [];
                    calcStateCell{iCalc} = calcTab;

                    %Remove coordinator if its empty
                    if isempty(calcTab)
                        removeCalc(iCalc) = true;
                    end
                end
                calcStateCell(removeCalc) = [];

                %Update keep idx
                keepIdx(~noPiPtIdx) = ~removeCalc;
            end

        end

        function [calcExeTimeCell, keepIdx] = getCalcTimesHist(obj, st, et)
            %Remove calcs with no pipoint
            noPiPtIdx = isnat(obj.SelectedCalcInfoTab.("Last Calc Time"));
            calcs = obj.SelectedCalcs(~noPiPtIdx);
            keepIdx = ~noPiPtIdx;

            %Loop through and retrieve values
            calcExeTimeCell = cell(numel(calcs), 1);
            for iCalc = 1:numel(calcs)
                [values, timestamps, ~] = calcs(iCalc).getHistoricalAttributeValues(...
                    "LastCalculationTime", [string(st); string(et)]);
                calcExeTimeCell{iCalc} = array2timetable(values', "RowTimes", timestamps', "VariableNames", "lastCalcTime");
            end
            
            %Remove NaNs etc
            if ~isempty(calcExeTimeCell)
                removeCalc = false(numel(calcExeTimeCell), 1);

                %Remove nans
                for iCalc = 1:numel(calcExeTimeCell)
                    calcTab = calcExeTimeCell{iCalc};

                    %Remove nans
                    if ~strcmpi(class(calcTab.lastCalcTime), "datetime")
                        calcTab(isnan(calcTab.lastCalcTime) | isnat(calcTab.Time), :) = [];
                    else
                        calcTab(isnat(calcTab.lastCalcTime) | isnat(calcTab.Time), :) = [];
                    end
                    
                    calcExeTimeCell{iCalc} = calcTab;

                    %Remove coordinator if its empty
                    if isempty(calcTab)
                        removeCalc(iCalc) = true;
                    end
                end
                calcExeTimeCell(removeCalc) = [];

                %Update keep idx
                keepIdx(~noPiPtIdx) = ~removeCalc;
            end

        end

        function [calcErrTimeCell, keepIdx] = getCalcErrorHist(obj, st, et)

            %Remove calcs with no pipoint
            calcs = obj.SelectedCalcs;
            noPiPtIdx = ismember(obj.SelectedCalcInfoTab.("Last Error"), "PIPointMissing");
            calcs = calcs(~noPiPtIdx);
            keepIdx = ~noPiPtIdx;

            %Loop through and retrieve values
            calcErrTimeCell = cell(numel(calcs), 1);
            for iCalc = 1:numel(calcs)
                [values, timestamps, ~] = calcs(iCalc).getHistoricalAttributeValues(...
                    "LastError", [string(st); string(et)]);
                calcErrTimeCell{iCalc} = array2timetable(values', "RowTimes", timestamps', "VariableNames", "lastError");
            end

            %Remove NaNs etc
            if ~isempty(calcErrTimeCell)
                removeCalc = false(numel(calcErrTimeCell), 1);

                %Remove nans
                for iCalc = 1:numel(calcErrTimeCell)
                    calcTab = calcErrTimeCell{iCalc};

                    %Remove nans
                    calcTab(isnan(calcTab.lastError) | isnat(calcTab.Time), :) = [];
                    calcErrTimeCell{iCalc} = calcTab;

                    %Remove coordinator if its empty
                    if isempty(calcTab)
                        removeCalc(iCalc) = true;
                    end
                end
                calcErrTimeCell(removeCalc) = [];

                %Update keep idx
                keepIdx(~noPiPtIdx) = ~removeCalc; 
            end

        end

        function calcInfoTab = getCalcInfo(obj)
            %Loops through collected calcs, getting specific attributes,
            %and creating a table

            calcs = obj.FilteredCalcs;

            if numel(calcs) > 0
                variableNames = ["Name", "Template", "Coord #", "Current State", "Backfilling", "Exe Mode", "Last Calc Time", "Last Error", "Path"];
                variableTypes = ["string", "string", "double", "string", "string", "string", "datetime", "string", "string"];

                calcInfoTab = table('Size', [numel(calcs), numel(variableNames)],...
                    'VariableTypes', variableTypes, 'VariableNames', variableNames);

                for iCalc = 1:numel(calcs)
                    %Name
                    calcInfoTab{iCalc, "Name"} = calcs(iCalc).Name;
                    %Template
                    calcInfoTab{iCalc, "Template"} = calcs(iCalc).TemplateName;
                    %Coord #
                    calcInfoTab{iCalc, "Coord #"} = calcs(iCalc).getAttributeValue("CoordinatorID");
                    %CalcState
                    calcState = calcs(iCalc).getAttributeValue("CalculationState");
                    if ~strcmpi(class(calcState), "string")
                        calcState = "PIPointMissing";
                    end
                    calcInfoTab{iCalc, "Current State"} = calcState;
                    %Backfilling
                    calcInfoTab{iCalc, "Backfilling"} = calcs(iCalc).getAttributeValue(["BackfillingParameters", "BackfillState"]);
                    %Exe mode
                    calcInfoTab{iCalc, "Exe Mode"} = calcs(iCalc).getAttributeValue(["ExecutionParameters", "ExecutionMode"]);
                    %Last calc time
                    lastCalcTime = calcs(iCalc).getAttributeValue("LastCalculationTime");
                    if ~strcmpi(class(lastCalcTime), "datetime")
                        lastCalcTime = NaT;
                    end
                    calcInfoTab{iCalc, "Last Calc Time"} = lastCalcTime;
                    %Last error
                    lastError = calcs(iCalc).getAttributeValue("LastError");
                    if ~strcmpi(class(lastError), "string")
                        lastError = "PIPointMissing";
                    end
                    calcInfoTab{iCalc, "Last Error"} = lastError;
                    %Path
                    calcInfoTab{iCalc, "Path"} = calcs(iCalc).Path;
                end
            else
                calcInfoTab = table.empty;
            end
            obj.FilteredCalcInfoTab = calcInfoTab;
        end

        function coordInfoTab = getCoordinators(obj)
            %Gets all coordinators as AF elements, passes them out in a table, and
            %saves AFElements into property.

            %Get all coord elements
            coordinators = af.Element.findByTemplate("CCECoordinator", "Connector",  obj.DataConnector);

            %Populate table of attributes
            if numel(coordinators) > 0
                variableNames = ["ID", "Load", "Exe Mode", "Exe Freq", "Current State"];
                variableTypes = ["int32", "int32", "string", "int32", "string"];

                coordInfoTab = table('Size', [numel(coordinators), numel(variableNames)],...
                    'VariableTypes', variableTypes, 'VariableNames', variableNames);
                
                %Loop through each coordinator
                for iCoord = 1:numel(coordinators)
                    coordInfoTab{iCoord, "ID"} = coordinators(iCoord).getAttributeValue("CoordinatorID");
                    coordInfoTab{iCoord, "Load"} = coordinators(iCoord).getAttributeValue("CalculationLoad");
                    coordInfoTab{iCoord, "Exe Mode"} = coordinators(iCoord).getAttributeValue("ExecutionMode");
                    coordInfoTab{iCoord, "Exe Freq"} = coordinators(iCoord).getAttributeValue("ExecutionFrequency");
                    coordState = coordinators(iCoord).getAttributeValue("CoordinatorState");
                    if ~strcmpi(class(coordState), "string")
                        coordState = "PIPointMissing";
                    end
                    coordInfoTab{iCoord, "Current State"} = coordState;
                end

                %Sort by coordinator
                [coordInfoTab, idx] = sortrows(coordInfoTab, "ID", "ascend");
                obj.CoordAttributeTable = coordInfoTab;
                obj.CollectedCoords = coordinators(idx);

            else
                coordInfoTab = table.empty;
                obj.CollectedCoords = coordinators;
            end
        end

        function coordStateCell = getCoordinatorStateHistory(obj, rowIdx, numVars, st, et)
            %Loop through coordinators, getting state history. Puts each
            %coord history time table into a cell array.
            if isempty(rowIdx)
                if numVars > 0
                    coords = obj.CollectedCoords;
                else
                    coords = [];
                    warning("No coords to plot.");
                end

            else
                coords = obj.CollectedCoords(rowIdx);
            end

            coordStateCell = cell(numel(coords), 1);
            for iCoord = 1:numel(coords)

                [values, timestamps, ~] = coords(iCoord).getHistoricalAttributeValues(...
                    "CoordinatorState", [string(st); string(et)]);
                coordStateCell{iCoord} = array2timetable(values', "RowTimes", timestamps', "VariableNames", "coordState");
            end

        end

        function reenableDisabledCalcs(obj, type)
            %Loop through selected calcs, checking which ones are disabled
            %or system disabled
            % reenableIdx = false(numel(obj.SelectedCalcs), 1);
            for iCalc = 1:numel(obj.SelectedCalcs)
                %Check if disabled
                if ismember(obj.SelectedCalcInfoTab{iCalc, "Current State"}, ["Disabled", "SystemDisabled"])
                    reenableCalc = true;
                else
                    reenableCalc = false;
                end
                
                %Reenable if true
                if reenableCalc
                    obj.SelectedCalcs(iCalc).setAttributeValue("CalculationState", type);
                end
            end
        end

        function requestDisableOnCalcs(obj)
            %Loop through selected calcs, checking which ones are disabled
            %or system disabled
            % reenableIdx = false(numel(obj.SelectedCalcs), 1);
            for iCalc = 1:numel(obj.SelectedCalcs)
                %Check if disabled
                if ismember(obj.SelectedCalcInfoTab{iCalc, "Current State"}, ["Idle", "FetchingData", "Queued", "Running", "WritingOutputs"])
                    disableCalc = true;
                else
                    disableCalc = false;
                end

                %Reenable if true
                if disableCalc
                    obj.SelectedCalcs(iCalc).setAttributeValue("RequestToDisable", true);
                end
            end

        end
    end

    methods (Static)

        function enumRefTable = makePlottableEnum(enum, enumNames)
            %MakePlottableEnum creates an enum reference table where values
            %are mapped to plotting values.
            variableNames = ["Name", "OrigVal", "PlotVal"];
            variableTypes = ["string", "int32", "int32"];

            enumRefTable = table('Size', [numel(enum), numel(variableNames)],...
                'VariableTypes', variableTypes, 'VariableNames', variableNames);

            enumRefTable.("PlotVal") = (1:numel(enum))';
            enumRefTable.("OrigVal") = enum.real;
            enumRefTable.("Name") = enumNames;
        end


    end


end

