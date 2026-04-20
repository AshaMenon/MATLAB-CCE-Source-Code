classdef AFCalculationDbService < cce.ICalculationDbService
    %AFCALCULATIONDBSERVICE
    
    properties (Access = 'private')
        Logger (1,1) Logger = Logger();
    end

    properties (SetAccess = 'private')
        DataConnector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
    end

    properties (Constant)
        TemplateName = "CCECalculation";%TODO: Add to cce.System?
    end
    
    methods (Static)
        function obj = getInstance(args)
            arguments
                args.DataConnector af.AFDataConnector = af.AFDataConnector.empty;
            end
            persistent singleton
            if isempty(singleton)
                singleton = cce.AFCalculationDbService();
            end
            obj = singleton;

            if ~isempty(args.DataConnector)
                obj.DataConnector = args.DataConnector;
            end
        end
    end
    
    methods % Interfaces of ICalculationDbService
        function [calcRecords, calcInput, calcParameter, calcOutput, calcTrigger] = findCalculations(obj, id, nvArgs) % Find Coordinators with specific id
            % FINDCALCULATIONS find Calculation(s) with the CoordinatorID, ID in the
            % Calculation Database.
            %   FINDCALCULATIONS(OBJ, ID) finds all Calculations in the Calculation
            %   Database with the CoordinatorID equal to ID.
            %
            % Inputs:
            %   ID  -   (uint32) CoordinatorID to search for.
            % Outputs:
            %   CALCRECORDS     -   (cce.AFCalculationRecord) array of
            %                       cce.AFCalculationRecords with CoordinatorID of ID
            %   CALCINPUT       -   (cell array of cce.AFCalculationInput objects)
            %                       Calculation Inputs. Each cell contains the Calculation
            %                       Inputs, cce.AFCalculationInput array for the Record
            %                       (Element) in the corresponding position in the
            %                       CALCRECORDS array.
            %   CALCPARAMETER   -   (cell array of cce.AFCalculationParameter objects)
            %                       Calculation Parameters. Each cell contains the
            %                       Calculation Parameters, cce.AFCalculationParameter
            %                       array for the Record (Element) in the corresponding
            %                       position in the CALCRECORDS array.
            %   CALCOUTPUT      -   (cell array of cce.AFCalculationOutput objects)
            %                       Calculation Outputs. Each cell contains the
            %                       Calculation Outputs, cce.AFCalculationOutput array for
            %                       the Record (Element) in the corresponding position in
            %                       the CALCRECORDS array.
            
            arguments
                obj (1,1) cce.AFCalculationDbService;
                id (1,1) uint32;
                nvArgs.Logger = Logger(cce.System.CoordinatorLogFile, "Coordinator", mfilename, cce.System.CoordinatorLogLevel); %FIXME: Which Log File?
            end
            
            obj.Logger = nvArgs.Logger;
            
            searchName = "CalcSearch:ID" + id;
            searchCriteria = sprintf("Template:'%s' ""|CoordinatorID"":='%d'""", obj.TemplateName, id);
            [records] = obj.DataConnector.findRecords(searchName, searchCriteria);
            
            if ~isempty(records)
                [calcRecords, calcInput, calcParameter, calcOutput, calcTrigger] = convertRecordsToParts(obj, records);
            else
                calcRecords = cce.AFCalculationRecord.empty();
                calcInput = cce.AFCalculationInput.empty();
                calcParameter = cce.AFCalculationParameter.empty();
                calcOutput = cce.AFCalculationOutput.empty();
                calcTrigger = cce.AFCalculationTrigger.empty();
            end
        end
        
        function [calcRecords, calcInput, calcParameter, calcOutput, calcTrigger] = findAllCalculations(obj, nvArgs) % Find all Calculations in the database
            % FINDALLCALCULATIONS find all Calculations in the Calculation Database.
            %   FINDALLCALCULATIONS(OBJ) finds the all the CCE Calculations Elements in
            %   the Calculation AF Database.
            
            arguments
                obj (1,1) cce.AFCalculationDbService;
                nvArgs.Logger  = Logger(cce.System.CoordinatorLogFile, "Coordinator", mfilename, cce.System.CoordinatorLogLevel); %FIXME: Which Log File?
            end
            
            obj.Logger = nvArgs.Logger;
            
            [records] = obj.DataConnector.findRecordsByTemplate('CalculationSearch', obj.TemplateName);
            
            if ~isempty(records)
                [calcRecords, calcInput, calcParameter, calcOutput, calcTrigger] = convertRecordsToParts(obj, records);
            else
                calcRecords = cce.AFCalculationRecord.empty();
                calcInput = cce.AFCalculationInput.empty();
                calcParameter = cce.AFCalculationParameter.empty();
                calcOutput = cce.AFCalculationOutput.empty();
                calcTrigger = cce.AFCalculationTrigger.empty();
                
                warning("cce:CalculationDbService:RecordNotFound", ...
                    "Could not find any CCE Calculation records in the AF database. Server: %s, Database: %s.", ...
                    obj.DataConnector.ServerName, obj.DataConnector.DatabaseName);
            end
        end

        function [calcRecords, calcInput, calcParameter, calcOutput, calcTrigger] = collectCalcItemsFromElement(obj, afElement)
            % COLLECTCALCITEMSFROMELEMENT Collects the calculation items
            % for a single specified af.Element, afElement. This is used
            % for calculation testing

            arguments
                obj (1,1) cce.AFCalculationDbService;
                afElement (1, 1) af.Element;
            end
            
            %Add calcRecord to cell array
            records = {afElement.NetElement};
            
            if ~isempty(records)
                [calcRecords, calcInput, calcParameter, calcOutput, calcTrigger] = convertRecordsToParts(obj, records);
            else
                calcRecords = cce.AFCalculationRecord.empty();
                calcInput = cce.AFCalculationInput.empty();
                calcParameter = cce.AFCalculationParameter.empty();
                calcOutput = cce.AFCalculationOutput.empty();
                calcTrigger = cce.AFCalculationTrigger.empty();
            end

        end

        function [calcRecords, calcInput, calcParameter, calcOutput, calcTrigger] = findBackfillingCalculations(obj, nvArgs) % Find Coordinators with specific id
            % FINDBACKFILLINGCALCULATIONS find Backfilling Calculation(s) that were
            % previously Running or are currently in the Requested state
            %   FINDBACKFILLINGCALCULATIONS(OBJ) finds all Running/ Requested Backfilling
            %   Calculations in the Calculation Database.
            %
            % Inputs:
            %   NVARGS.LOGGER  -   (Logger) Logger class to write log messages.
            % Outputs:
            %   CALCRECORDS     -   (cce.AFCalculationRecord) array of
            %                       cce.AFCalculationRecords with CoordinatorID of ID
            %   CALCINPUT       -   (cell array of cce.AFCalculationInput objects)
            %                       Calculation Inputs. Each cell contains the Calculation
            %                       Inputs, cce.AFCalculationInput array for the Record
            %                       (Element) in the corresponding position in the
            %                       CALCRECORDS array.
            %   CALCPARAMETER   -   (cell array of cce.AFCalculationParameter objects)
            %                       Calculation Parameters. Each cell contains the
            %                       Calculation Parameters, cce.AFCalculationParameter
            %                       array for the Record (Element) in the corresponding
            %                       position in the CALCRECORDS array.
            %   CALCOUTPUT      -   (cell array of cce.AFCalculationOutput objects)
            %                       Calculation Outputs. Each cell contains the
            %                       Calculation Outputs, cce.AFCalculationOutput array for
            %                       the Record (Element) in the corresponding position in
            %                       the CALCRECORDS array.
            
            arguments
                obj (1,1) cce.AFCalculationDbService;
                nvArgs.Logger = Logger(cce.System.CoordinatorLogFile, "Coordinator", mfilename, cce.System.CoordinatorLogLevel); %FIXME: Which Log File?
            end
            
            obj.Logger = nvArgs.Logger;
            
            runningState = string(cce.CalculationBackfillState.Running);
            searchCriteria = sprintf("Template:'%s' ""|BackfillingParameters|BackfillState"":='%s'""", obj.TemplateName, runningState);
            [runningRecords] = obj.DataConnector.findRecords("BackfillRunning", searchCriteria);
            requestedState = string(cce.CalculationBackfillState.Requested);
            searchCriteria = sprintf("Template:'%s' ""|BackfillingParameters|BackfillState"":='%s'""", obj.TemplateName, requestedState);
            [requestedRecords] = obj.DataConnector.findRecords("BackfillRequested", searchCriteria);
            
            records = [runningRecords, requestedRecords];
            if ~isempty(records)
                [calcRecords, calcInput, calcParameter, calcOutput, calcTrigger] = convertRecordsToParts(obj, records);
            else
                calcRecords = cce.AFCalculationRecord.empty();
                calcInput = cce.AFCalculationInput.empty();
                calcParameter = cce.AFCalculationParameter.empty();
                calcOutput = cce.AFCalculationOutput.empty();
                calcTrigger = cce.AFCalculationTrigger.empty();
            end
        end
    end
    
    methods (Access = 'private')
        function [calcRecords, calcInput, calcParameter, calcOutput, calcTrigger] = convertRecordsToParts(obj, records)
            %CONVERTRECORDSTOPARTS read the records and extract the record attributes into
            %cce.AFCalculationRecord, cce.AFCalculationInput, cce.AFCalculationParameter,
            %and cce.AFCalculationOutput objects. If the Calculation record cannot be
            %properly read in - due to configuration error(s), the Calculation will return
            %empty/ not be returned with object array (for multiple records).
            
            calcRecords = cce.AFCalculationRecord.empty();
            calcInput = cell(1, numel(records));
            calcParameter = cell(1, numel(records));
            calcOutput = cell(1, numel(records));
            calcTrigger = cell(1, numel(records));
            for k = numel(records):-1:1
                [calcConfigRecord, inputs, paremeters, outputs, triggers] = obj.readRecord(records{k});
                if ~isempty(calcConfigRecord)
                    calcRecords(k) = calcConfigRecord;
                    calcInput{k} = inputs;
                    calcParameter{k} = paremeters;
                    calcOutput{k} = outputs;
                    calcTrigger{k} = triggers;
                elseif ~isempty(calcRecords)
                    calcRecords(k) = [];
                    calcInput(k) = [];
                    calcParameter(k) = [];
                    calcOutput(k) = [];
                    calcTrigger{k} = [];
                end
            end
        end
        
        function [configurationItems, inputItems, parameterItems, outputItems, triggerItems] = readRecord(obj, record)
            %READRECORD try to read the Calculation record from the AF Database. This is
            %done in a try, catch block to handle misconfigured Calculation Configuration
            %items.
            
            % Try to read in the Calculation Configuration items, if there is an error
            % returned - write this to the local logs and try to set the Calculation to a
            % ConfigurationError state.
            try
                configurationItems = cce.AFCalculationRecord(record, obj.DataConnector, obj.Logger);
            catch err
                logError(obj.Logger, join(["Error encountered while reading Calculation Configuration Attributes", ...
                    "for:\n\tElement: %s\n\tElementID: %s.", ...
                    "\n Message: %s (function %s, line %d)"]), ...
                    string(record.Name), string(record.UniqueID), ...
                    err.message, err.stack(1).name, err.stack(1).line);

                if isConfigurationError(err.message)
                    setCalculationToErrorState(obj, record); %TODO Move out of this class - its not this classes responsibility to change this
                else
                    % set to network error
                    setCalcStateToNetworkError(obj, record)
                    writeNetworkErrorFailedTime(string(record.UniqueID), string(datetime),obj.Logger)
                end

                configurationItems = cce.AFCalculationRecord.empty;
                inputItems = cce.AFCalculationInput.empty;
                parameterItems  = cce.AFCalculationParameter.empty;
                outputItems  = cce.AFCalculationOutput.empty;
                triggerItems = cce.AFCalculationTrigger.empty;
                return
            end
            %If successful, return the configurationItems, inputs, parameters, and outputs
            inputItems  = cce.AFCalculationInput(record, obj.DataConnector);
            isValid = inputItems.verifyTimeRangeConfiguration();
            if ~isValid
                obj.Logger.logError("Calculation: %s input(s) RelativeTimeRange is not an accepted configuration.", configurationItems.RecordPath);
                configurationItems.setField("CalculationState", cce.CalculationState.ConfigurationError);
                configurationItems.setField("LastError", cce.CalculationErrorState.InputTimeRangeInvalid);
            end
            parameterItems  = cce.AFCalculationParameter(record, obj.DataConnector);
            outputItems  = cce.AFCalculationOutput(record, obj.DataConnector);
            triggerItems = cce.AFCalculationTrigger(record, obj.DataConnector);

            function setCalcStateToNetworkError(obj, record)
                try
                    [lastErrorAttribute] = obj.DataConnector.getFieldByName(record, "LastError");
                    obj.DataConnector.setField(lastErrorAttribute, cce.CalculationErrorState.NetworkError);
                catch errorSetLastError
                    obj.Logger.logError(join(["Error encountered when trying to write", ...
                        "LastError for:\n\tElement: %s\n\tElementID: %s.", ...
                        "\n Message: %s (function %s, line %d)"]), ...
                        string(record.Name), string(record.UniqueID), ...
                        errorSetLastError.message, errorSetLastError.stack(1).name, errorSetLastError.stack(1).line);
                end
            end
            
            function setCalculationToErrorState(obj, record)
                %SETCALCULATIONTOERRORSTATE set the Calculation's CalculationState
                %Attribute to a ConfigurationError state and write a ConfigurationError
                %message to the Calculation's LastError Attribute.
                % Both attempts to write are encapsulated in a try catch in case either of
                % these attributes are misconfigured and cannot be written to. An error
                % here is added to the local logs.
                
                try
                    [lastErrorAttribute] = obj.DataConnector.getFieldByName(record, "LastError");
                    obj.DataConnector.setField(lastErrorAttribute, cce.CalculationErrorState.ConfigurationError);
                catch errorSetLastError
                    obj.Logger.logError(join(["Error encountered when trying to write", ...
                        "LastError for:\n\tElement: %s\n\tElementID: %s.", ...
                        "\n Message: %s (function %s, line %d)"]), ...
                        string(record.Name), string(record.UniqueID), ...
                        errorSetLastError.message, errorSetLastError.stack(1).name, errorSetLastError.stack(1).line);
                end
                
                try
                    [calculationStateAttribute] = obj.DataConnector.getFieldByName(record, "CalculationState");
                    obj.DataConnector.setField(calculationStateAttribute, cce.CalculationState.ConfigurationError);
                catch errorSetState
                    obj.Logger.logError(join(["Error encountered when trying to write", ...
                        "ConfigurationError State for:\n\tElement: %s\n\tElementID: %s.", ...
                        "\n Message: %s (function %s, line %d)"]), ...
                        string(record.Name), string(record.UniqueID), ...
                        errorSetState.message, errorSetState.stack(1).name, errorSetState.stack(1).line);
                    try
                        [lastErrorAttribute] = obj.DataConnector.getFieldByName(record, "LastError");
                        obj.DataConnector.setField(lastErrorAttribute, cce.CalculationErrorState.CalculationStateInvalid);
                    catch errorSetLastError
                        obj.Logger.logError(join(["Error encountered when trying to write 'CalculationStateInvalid' to", ...
                            "LastError for:\n\tElement: %s\n\tElementID: %s.", ...
                            "\n Message: %s (function %s, line %d)"]), ...
                            string(record.Name), string(record.UniqueID), ...
                            errorSetLastError.message, errorSetLastError.stack(1).name, errorSetLastError.stack(1).line);
                    end
                end
            end
        end
    end
end

