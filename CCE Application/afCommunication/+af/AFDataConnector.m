classdef AFDataConnector < handle
    %AFDATACONNECTOR
    
    properties
        ServerName string
        DatabaseName string
    end
    
    properties (Access = 'protected')
        Server
        Database
    end
    
    methods
        function obj = AFDataConnector(serverName, databaseName)
            %AFDATACONNECTOR constructs an instance of this class.
            % AFDATACONNECTOR imports the necessary .NET and OSIsoft AF SDK namespaces
            % required by the class and connects to the AF Database on the PI
            % System/Server.
            
            arguments
                serverName string;
                databaseName string;
            end
            
            import System.*;
            
            NET.addAssembly('OSIsoft.AFSDK');
            import OSIsoft.AF.*;
            import OSIsoft.AF.Asset.*;
            import OSIsoft.AF.Data.*;
            import OSIsoft.AF.Search.*;
            import OSIsoft.AF.Time.*;
            
            connect(obj, serverName, databaseName)
        end
        
        function refreshAFDbCache(obj)
            %REFRESHAFDBCACHE refreshes the client with any changes that have been made to
            %the database since loaded without discarding unapplied changes.
            
            obj.Database.Refresh();
        end
        
        function [record] = createRecord(obj, templateName, recordName)
            %CREATERECORD create and add a new record (element) to the root of the Database based on
            %the record template, found by TEMPLATENAME with the given name, RECORDNAME.
            
            arguments
                obj (1,1) af.AFDataConnector;
                templateName string;
                recordName string;
            end
            
            [record] = createRecordWithHierarchy(obj, templateName, recordName, {});
        end
        
        function [record] = createRecordWithHierarchy(obj, templateName, recordName, recordHierarchy)
            %CREATERECORDWITHHIERARCHY create and add a new record to the RECORDHIERARCHY
            %of the Database based on the record template, found by TEMPLATENAME with the
            %given name, RECORDNAME.
            % Inputs:
            %   templateName    -   (char) name of CCE Template used to create records.
            %   recordName      -   (char) name of new record.
            %   recordHierarchy -   (cell array of chars) each element represents the next
            %                       depth in the hierarchy, where the first cell is the
            %                       highest level (after the database) and the last is the
            %                       last level in the hierarchy to which the record will
            %                       be created as a child
            
            arguments
                obj (1,1) af.AFDataConnector
                templateName string
                recordName string {mustBeTextScalar}
                recordHierarchy cell {mustBeText}
            end
            
            % Is the templateName is empty, don't find a base template
            if strlength(templateName) > 0
                [template] = findTemplateByName(obj, templateName);
                if isempty(template)
                    error("cce:AFDataConnector:TemplateNotFound", "Template named '%s' not found in database.", templateName);
                end
            end

            % Find the baseElement to add this element to
            baseElement = obj.Database;
            for c = 1:numel(recordHierarchy)
                nextElement = baseElement.Elements.Item(recordHierarchy{c});
                if isempty(nextElement)
                    nextElement= baseElement.Elements.Add(recordHierarchy{c});
                end
                baseElement = nextElement;
            end
            
            % If the template name is empty, just create the new element
            if strlength(templateName)==0
                record = baseElement.Elements.Add(recordName);
            else
                record = baseElement.Elements.Add(recordName, template);
            end
            
            obj.commitToDatabase;
        end
        
        function [records] = findRecords(obj, searchName, searchCriteria, startIdx, pagingSize)
            %FINDRECORDS find records in the connected AF Database that meet the search
            %criteria. The element search starts at the 0 indexed, STARTIDX
            %FINDRECORDS returns a cell array of records that meet the conditions of the
            %search.
            
            arguments
                obj (1,1) af.AFDataConnector;
                searchName string
                searchCriteria string
                startIdx double = 0;
                pagingSize double = 1000; %number of elements returned by each search
            end
            
            records = obj.elementSearch(searchName, searchCriteria, startIdx, pagingSize);
        end
        
        function [records] = findRecordsByTemplate(obj, searchName, templateName)
            %FINDRECORDS find records in the connected AF Database that have been created
            %based on the template with TEMPLATENAME.
            %FINDRECORDS returns a cell array of records that have been created based on
            %the template with TEMPLATENAME.
            
            arguments
                obj (1,1) af.AFDataConnector;
                searchName string
                templateName string
            end
            
            [records] = findRecords(obj, searchName, sprintf('Template:''%s''', templateName));
        end
        
        function [fields, names] = getRecordFieldsByCategory(obj, record, categoryName, startIdx, pagingSize)
            %GETRECORDFIELDSBYCATEGORY returns the fields and the names of the fields in the
            %record that are categorised by CATEGORYNAME.
            
            arguments
                obj (1,1) af.AFDataConnector;
                record
                categoryName string
                startIdx double = 0;
                pagingSize double = 1000; %number of elements returned by each search
            end
            
            recordID = record.UniqueID;
            searchName = sprintf('%sAttributeSearch', categoryName);
            query = sprintf('Element:{ID:="%s"} Category:="%s"', recordID, categoryName);
            
            fields = obj.attributeSearch(searchName, query, startIdx, pagingSize);
            
            names = cell(size(fields));
            if ~isempty(fields)
                for c = 1:numel(fields)
                    names{c} = string(fields{c}.Name);
                end
            end
        end
        
        function [value] = readField(obj, field)
            %READFIELD read the (current) value of the field
            
            afvalue = field.GetValue();
            value = obj.parseAFValue(afvalue);
        end
        
        function [value, timestamp, quality] = readFieldRecordedHistory(obj, field, timeRange, nv)
            %READFIELDRECORDEDHISTORY read the recorded historical data of the
            %FIELD for the TIMERANGE and name-value optional arguments.
            % See: getRecordedHistory
            
            arguments
                obj (1,1) af.AFDataConnector;
                field (1,1) OSIsoft.AF.Asset.AFAttribute;
                timeRange (2,:) string;
                nv.BoundaryType string {mustBeMember(nv.BoundaryType, ...
                    {'Inside', 'Outside', 'Interpolated'})} = 'Inside';
                nv.UOM = [];
                nv.FilterExpression string = "";
                nv.IncludeFilterValues logical = true;
                nv.MaxCount = 0;
            end
            
            dataReference = field.Data;
            [value, timestamp, quality] = getRecordedHistory(obj, dataReference, timeRange, nv.BoundaryType, nv.UOM,...
                nv.FilterExpression, nv.IncludeFilterValues, nv.MaxCount);
        end
        
        function [value, timestamp, quality] = getRecordedHistory(obj, dataReference, timeRange,...
                boundaryType, uom, filterExpression, includeFilterValues, maxCount)
            %GETRECORDEDHISTORY returns the recorded history of an AFData object
            %for a given TIMERANGE.
            % Inputs:
            %   dataReference   -   AFData object
            %   timeRange       -   (2, :) string array. Date format: 'dd-MMM-yyyy
            %                       hh:mm:ss +/- offset(s)'. Starting time of the time
            %                       range specified by the first entry timeRange(1, :) and
            %                       ending time specified by the second entry.
            %                       e.g. ["01-01-2020 00:00:00 - 2h"; "01-01-2020 00:00:00"]
            %   boundaryType    -   string. Contains the string name value of the
            %                       AFBoundaryType to be used for the data retrieval.
            %   uom             -   OSIsoft.AF.UnitsOfMeasure.UOM: units of measure format of the data to be returned.
            %                       Or empty [] to return the data in the default UOM.
            %   filterExpression -  string containing a filter expression.
            %   includeFilterValues -   Specify true to indicate that values which fail
            %                           the filter criteria are present in the returned
            %                           data at the times where they occurred with a value
            %                           set to a "Filtered" enumeration value with bad
            %                           status. Repeated consecutive failures are omitted.
            %   maxCount        -   The maximum number of values to be returned. If zero,
            %                       then all of the events within the requested time range
            %                       will be returned.
            
            arguments
                obj (1,1) af.AFDataConnector;
                dataReference (1,1) OSIsoft.AF.Data.AFData;
                timeRange (2,:) string;
                boundaryType string {mustBeMember(boundaryType, ...
                    {'Inside', 'Outside', 'Interpolated'})};
                uom = [];
                filterExpression string = "";
                includeFilterValues logical = true;
                maxCount = 0;
            end
            
            timeRange = OSIsoft.AF.Time.AFTimeRange(timeRange(1, :), timeRange(2, :));
            boundaryType = OSIsoft.AF.Data.AFBoundaryType.(boundaryType);
            afvals = dataReference.RecordedValues(timeRange, boundaryType, uom, ...
                filterExpression, includeFilterValues, maxCount);
            
            if isempty(afvals) || (afvals.Count == 0)
                value = NaN;
                timestamp = NaT;
                quality = "";
            end

            for c = afvals.Count:-1:1
                    [value(c), timestamp(c), quality(c)] = obj.parseAFValue(afvals.Item(c-1));
            end
        end

        function [value, timestamp, quality] = readFieldInterpolatedHistory(obj, field, timeRange, sampleRate)
            %READFIELDINTERPOLATEDHISTORY read the interpolated historical data of the
            %FIELD for the TIMERANGE and a given SAMPLERATE
            
            arguments
                obj (1,1) af.AFDataConnector;
                field (1,1) OSIsoft.AF.Asset.AFAttribute;
                timeRange (2,:) string;
                sampleRate string;
            end
            
            data = field.Data;
            [value, timestamp, quality] = obj.getInterpolatedHistory(data, timeRange, sampleRate);
        end
        
        function [value, timestamp, quality] = getInterpolatedHistory(obj, dataReference, timeRange, sampleRate)
            %GETINTERPOLATEDHISTORY returns the interpolated history of an AFData object
            %for a given TIMERANGE and SAMPLERATE.
            % Inputs:
            %   dataReference   -   AFData object
            %   timeRange       -   (2, :) string array. Date format: 'dd-MMM-yyyy
            %                       hh:mm:ss +/- offset(s)'. Starting time of the time
            %                       range specified by the first entry timeRange(1, :) and
            %                       ending time specified by the second entry.
            %                       e.g. ["01-01-2020 00:00:00 - 2h"; "01-01-2020 00:00:00"]
            %   sampleRate      -   string format that specified the sample rate as any
            %                       combination of years (y), months (mo), days (d), hours
            %                       (h), minutes (m), seconds (s), and milliseconds (ms).
            %                       e.g. "3m 10s"
            
            arguments
                obj (1,1) af.AFDataConnector;
                dataReference (1,1) OSIsoft.AF.Data.AFData;
                timeRange (2,:) string;
                sampleRate string;
            end
            
            timeRange = OSIsoft.AF.Time.AFTimeRange(timeRange(1, :), timeRange(2, :));
            [timespan] = obj.parseTimeSpan(sampleRate);
            uom = [];
            afvals = dataReference.InterpolatedValues(timeRange, timespan, uom, [], true);
            
            for c = afvals.Count:-1:1
                [value(c), timestamp(c), quality(c)] = obj.parseAFValue(afvals.Item(c-1));
            end
        end
        
        function [value, timestamp, quality] = readFieldLastHistoryValue(obj, field, timeAtOrBefore, retrievalMode, uom)
            %READFIELDLASTHISTORYVALUE get the last historical data value from a FIELD at
            %or before the input time TIMEATORBEFORE
            
            arguments
                obj (1,1) af.AFDataConnector;
                field (1,1) OSIsoft.AF.Asset.AFAttribute;
                timeAtOrBefore string;
                retrievalMode string {mustBeMember(retrievalMode, ...
                    {'Auto', 'AtOrBefore', 'Before', 'AtOrAfter', 'After', 'Exact'})} = ...
                    'AtOrBefore';
                uom = [];
            end
            
            dataReference = field.Data;
            [value, timestamp, quality] = getLastHistoryValue(obj, dataReference, timeAtOrBefore, retrievalMode, uom);
        end
        
        function [value, timestamp, quality] = getLastHistoryValue(obj, dataReference, timeAtOrBefore, retrievalMode, uom)
            %GETHISTORY get historical data from attribute data references.
            %Cache enabled attributes should use this method
            % Inputs:
            %   dataReference   -   AFData object
            %   timeAtOrBefore  -  	string/ char. Date format: 'dd-MMM-yyyy hh:mm:ss +
            %                       offset(s)'. https://docs.osisoft.com/bundle/af-sdk/page/html/M_OSIsoft_AF_Time_AFTime__ctor_7.htm
            
            arguments
                obj (1,1) af.AFDataConnector;
                dataReference (1,1) OSIsoft.AF.Data.AFData;
                timeAtOrBefore string;
                retrievalMode string {mustBeMember(retrievalMode, ...
                    {'Auto', 'AtOrBefore', 'Before', 'AtOrAfter', 'After', 'Exact'})} = ...
                    'AtOrBefore';
                uom = [];
            end
            
            timeAtOrBefore = OSIsoft.AF.Time.AFTime(timeAtOrBefore);
            retrievalMode = OSIsoft.AF.Data.AFRetrievalMode.(retrievalMode);
            afVal = dataReference.RecordedValue(timeAtOrBefore, retrievalMode, uom);
            [value, timestamp, quality] = obj.parseAFValue(afVal);
        end
        
        function outputTbl = getTable(obj, tblName)
            % GETTABLE get AF Table named tblName. Note that if table is
            % empty, variable types are not captured. 
            
            arguments
                obj (1,1) af.AFDataConnector;
                tblName (1,1) string;
            end

            afTables = obj.Database.Tables;

            queriedTbl = [];
            outputTbl = table;

            for idx = 0:afTables.Count - 1
                if afTables.Item(idx).Name == tblName
                    queriedTbl = afTables.Item(idx).Table;
                    break
                end
            end

            if ~isempty(queriedTbl)
                numCols = queriedTbl.Columns.Count;
                numRows = queriedTbl.Rows.Count;

                for nCol = 0:numCols - 1

                    colData = cell(numRows, 1);
                   
                    for nRow = 0:numRows-1
                        val = queriedTbl.Rows.Item(nRow).Item(nCol);
                        if isa(val,'System.String')
                            val = string(val);
                        elseif isa(val,'System.DateTime')
                            val = datetime(val.Year, val.Month, val.Day, val.Hour, val.Minute, val.Second, val.Millisecond);
                        end
                        colData{nRow+1} = val;
                    end
                    columnName = queriedTbl.Columns.Item(nCol).ColumnName.string;
                    outputTbl.(columnName) = [colData{:}]';
                end

            end

        end

        function writeFieldHistory(obj, field, value, timestamp, valueStatus, UOM, updateOption,opts)
            %WRITEFIELDHISTORY write historical data to the FIELD Data object. Write DATA
            %values and TIMESTAMP, data quality VALUESTATUS, optionally specify the units
            %of measure, UOM and the UPDATEOPTION that defines the data write
            %insert/replace behaviour.
            %   Inputs:
            %       field           -	(1, 1) OSIsoft.AF.Asset.AFAttribute Attribute
            %       value           -	(datetime, numeric, string, and cell array types
            %                           supported). Data values
            %       timestamp       -   datetime. Data timestamps
            %       valueStatus     -   string. AFValue Status Values
            %                           https://docs.osisoft.com/bundle/af-sdk/page/html/T_OSIsoft_AF_Asset_AFValueStatus.htm
            %       UOM             -   OSIsoft.AF.UnitsOfMeasure.UOM. Units of measure of
            %                           data values.
            %       updateOption	-   string. AF Update Option Enumeration Values
            %                           https://docs.osisoft.com/bundle/af-sdk/page/html/T_OSIsoft_AF_Data_AFUpdateOption.htm
            
            arguments
                obj (1,1) af.AFDataConnector;
                field (1, 1) OSIsoft.AF.Asset.AFAttribute;
                value
                timestamp datetime;
                valueStatus string {mustBeMember(valueStatus, ...
                    {'Bad', 'Questionable', 'Good', 'QualityMask', 'SubstatusMask', 'BadSubstituteValue', ...
                    'UncertainSubstituteValue', 'Substituted', 'Constant', 'Annotated'})};
                UOM = [];
                updateOption string {mustBeMember(updateOption, ...
                    {'Replace', 'Insert', 'NoReplace', 'ReplaceOnly', 'InsertNoCompression', 'Remove'})}  ...
                    = "Replace";
                opts.WriteNanAs cce.WriteNanAsValue = cce.WriteNanAsValue("NaN");
            end
            
            dataReference = field.Data;
            writeHistory(obj, dataReference, value, timestamp, valueStatus, UOM, updateOption, opts.WriteNanAs)
        end
        
        function writeHistory(obj, dataReference, value, timestamp, valueStatus, UOM, updateOption, writeNanAs)
            %WRITEHISTORY write historical data to the DATAREFERENCE. Write DATA values and
            %TIMESTAMP, data quality VALUESTATUS, optionally specify the units of measure,
            %UOM and the UPDATEOPTION that defines the data write insert/replace
            %behaviour.
            %   Inputs:
            %       field           -	(1, 1) OSIsoft.AF.Asset.AFAttribute Attribute
            %       value           -	(datetime, numeric, string, and cell array types
            %                           supported). Data values
            %       timestamp       -   datetime. Data timestamps
            %       valueStatus     -   string. AFValue Status Values
            %                           https://docs.osisoft.com/bundle/af-sdk/page/html/T_OSIsoft_AF_Asset_AFValueStatus.htm
            %       UOM             -   OSIsoft.AF.UnitsOfMeasure.UOM. Units of measure of
            %                           data values.
            %       updateOption	-   string. AF Update Option Enumeration Values
            %                           https://docs.osisoft.com/bundle/af-sdk/page/html/T_OSIsoft_AF_Data_AFUpdateOption.htm
            
            arguments
                obj (1,1) af.AFDataConnector;
                dataReference (1, 1) OSIsoft.AF.Data.AFData;
                value
                timestamp datetime;
                valueStatus string {mustBeMember(valueStatus, ...
                    {'Bad', 'Questionable', 'Good', 'QualityMask', 'SubstatusMask', 'BadSubstituteValue', ...
                    'UncertainSubstituteValue', 'Substituted', 'Constant', 'Annotated'})};
                UOM = [];
                updateOption string {mustBeMember(updateOption, ...
                    {'Replace', 'Insert', 'NoReplace', 'ReplaceOnly', 'InsertNoCompression', 'Remove'})}  ...
                    = "Replace";
                writeNanAs cce.WriteNanAsValue = cce.WriteNanAsValue("NaN");
            end
            
            if writeNanAs == cce.WriteNanAsValue.NaN
                [afVals] = cce.createAFValues(value, timestamp, valueStatus, UOM);
            elseif writeNanAs == cce.WriteNanAsValue.NoOutput
                % Remove all NaN values and timestamps
                nanIdx = isnan(value);

                value(nanIdx) = [];
                timestamp(nanIdx) = [];

                [afVals] = cce.createAFValues(value, timestamp, valueStatus, UOM);
            else % Return output as system state
                % Replace NaN values with enum

                nanIdx = isnan(value);

                value = num2cell(value);
                value(nanIdx) = {string(writeNanAs)};

                [afVals] = cce.createAFValues(value, timestamp, valueStatus, UOM, true);
            end

            % If af values is empty and writeNanAs is set to NoOutput skip
            % data write out
            if afVals.Count > 0 || writeNanAs ~= cce.WriteNanAsValue.NoOutput
                afUpdateOption = OSIsoft.AF.Data.AFUpdateOption.(updateOption);
                bufferOption = OSIsoft.AF.Data.AFBufferOption.DoNotBuffer;
                [err] = dataReference.UpdateValues(afVals, afUpdateOption, bufferOption);
                if ~isempty(err)
                    [~, messages] = obj.readAFErrors(err);
                    messages = string(messages);
                    messages = strjoin(messages, '\n');
                    error("cce:AFDataConnector:FailedWrite", ...
                        "Data write to attribute ""%s"" of element ""%s"" (Element ID: %s) has failed. The following errors were thrown:\n%s", ...
                        string(dataReference.Attribute.Name), ...
                        string(dataReference.Attribute.Element.Name), ...
                        string(dataReference.Attribute.Element.ID.ToString), ...
                        messages);
                end
            end
        end
        
        function removeFieldRecordedHistory(obj, field, timeRange)
            %REMOVEFIELDRECORDEDHISTORY removes the recorded history of an AFAttribute object
            %within a given TIMERANGE.
            % Inputs:
            %   field   -   (1, 1) OSIsoft.AF.Asset.AFAttribute Attribute
            %   timeRange       -   (2, :) string array. Date format: 'dd-MMM-yyyy
            %                       hh:mm:ss +/- offset(s)'. Starting time of the time
            %                       range specified by the first entry timeRange(1, :) and
            %                       ending time specified by the second entry.
            %                       e.g. ["01-01-2020 00:00:00 - 2h"; "01-01-2020 00:00:00"]
            
            
            arguments
                obj (1,1) af.AFDataConnector;
                field (1, 1) OSIsoft.AF.Asset.AFAttribute;
                timeRange (2,:) string;
            end
            
            dataReference = field.Data;
            obj.removeRecordedHistory(dataReference, timeRange);
        end
        
        function removeRecordedHistory(obj, dataReference, timeRange)
            %REMOVERECORDEDHISTORY removes the recorded history of an AFData object
            %within a given TIMERANGE.
            % Inputs:
            %   dataReference   -   AFData object
            %   timeRange       -   (2, :) string array. Date format: 'dd-MMM-yyyy
            %                       hh:mm:ss +/- offset(s)'. Starting time of the time
            %                       range specified by the first entry timeRange(1, :) and
            %                       ending time specified by the second entry.
            %                       e.g. ["01-01-2020 00:00:00 - 2h"; "01-01-2020 00:00:00"]
            
            
            arguments
                obj (1,1) af.AFDataConnector;
                dataReference (1,1) OSIsoft.AF.Data.AFData;
                timeRange (2,:) string;
            end
            
            timeRange = OSIsoft.AF.Time.AFTimeRange(timeRange(1, :), timeRange(2, :));
            emptyAFValues = OSIsoft.AF.Asset.AFValues();
            err = dataReference.ReplaceValues (timeRange, emptyAFValues);
            if ~isempty(err)
                [~, messages] = obj.readAFErrors(err);
                messages = string(messages);
                messages = strjoin(messages, '\n');
                error("cce:AFDataConnector:FailedRemoveValues", ...
                    "Data write to attribute ""%s"" of element ""%s"" (Element ID: %s) has failed. The following errors were thrown:\n%s", ...
                    dataReference.Attribute.Name, ...
                    dataReference.Attribute.Element.Name,...
                    dataReference.Attribute.Element.ID.ToString, ...
                    messages);
            end
        end
        
        function commitToDatabase(obj)
            %COMMITTODATABASE checkin all changes from current session to the database
            
            obj.Database.CheckIn(OSIsoft.AF.AFCheckedOutMode.ObjectsCheckedOutThisSession);
        end
        
        function [template] = findTemplateByName(obj, templateName)
            %FINDTEMPLATEBYNAME searches for templates on the AF Database with the name
            %TEMPLATENAME
            
            tempCollection =  OSIsoft.AF.Asset.AFElementTemplate.FindElementTemplates(obj.Database, templateName, ...
                OSIsoft.AF.AFSearchField.Name, OSIsoft.AF.AFSortField.Name, OSIsoft.AF.AFSortOrder.Ascending, ...
                1);
            template = tempCollection.Item(0);
        end

    end
    
    methods (Static)
        function deleteRecord(record)
            %DELETERECORD delete an OSIsoft.AF.Asset.AFElement record from the AF Database
            
            arguments
                record (1,1) OSIsoft.AF.Asset.AFElement
            end
            
            Delete(record)
        end
        
        function [fields] = getFields(parentItem)
            %GETFIELDS returns an OSIsoft.AF.Asset.AFAttributeList of all of the fields in the PARENTITEM. The
            %PARENTITEM can be an AFElement or AFAttribute that contains children
            %attributes
            
            fields = OSIsoft.AF.Asset.AFAttributeList(parentItem.Attributes);
        end
        
        function [field] = getFieldByName(parentItem, fieldName)
            %GETFIELDBYNAME returns an array of the fields in the PARENTITEM that have
            %the name FIELDNAME.
            % Inputs:
            %   PARENTITEM  -   AFElement or AFAttribute item
            %   FIELDNAME   -   string. Name of the searched attribute
            
            field = parentItem.Attributes.Item(fieldName);
            if isequal(field, [])
                error("cce:AFDataConnector:FieldNotFound", "No attribute ""%s"" found for parent item %s of type %s", fieldName, parentItem.Name, class(parentItem))
            end
        end
        
        function setField(field, value)
            %SETFIELD update the value of the field
            
            if isenum(value)
                value = string(value);
            elseif isa(value, 'datetime')
                [value] = cce.parseDateTime(value);
            end
            field.SetValue(value, []);
        end

        function [derivedTemplates] = findDerivedTemplates(template)
            %FINDDERIVEDTEMPLATES searches gets the derived templates of inputted template on the AF Database
            derivedTemplates = template.FindDerivedTemplates(true, OSIsoft.AF.AFSortField.Name, OSIsoft.AF.AFSortOrder.Ascending, 1000);
        end
    end
    
    methods (Access = 'private')
        function connect(obj, serverName, databaseName)
            %CONNECT connects to a PI Server and finds the AF Database.
            
            arguments
                obj (1, 1) af.AFDataConnector;
                serverName string;
                databaseName string;
            end
            
            systems = OSIsoft.AF.PISystems;
            obj.Server = systems.Item(serverName);
            if isempty(obj.Server)
                error("cce:AFDataConnector:UnknownServer", join(["Error connecting to PI Server.\n", ...
                    "Could not find the ""%s"" PI AF Server."]),  serverName)
            end
            obj.ServerName = serverName;
            
            obj.Database = obj.Server.Databases.Item(databaseName);
            if isempty(obj.Database)
                error("cce:AFDataConnector:FailedDbConnect", join(["Error connecting to PI AF Database.\n", ...
                    "Could not find the ""%s"" AF Database on the ""%s"" PI AF Server."]),  databaseName, serverName)
            end
            obj.DatabaseName = databaseName;
        end
        
        function [elements] = elementSearch(obj, searchName, queryString, startIdx, pagingSize)
            %ELEMENTSEARCH performs an AFElement search for the given searchCriteria,
            %QUERYSTRING, returning the number of elements defined by PAGINGSIZE starting at
            %the elements found from the STARTIDX.
            %ELEMENTSEARCH returns a cell array of AF Element objects for each object found
            %in the search
            
            search = OSIsoft.AF.Search.AFElementSearch(obj.Database, searchName, queryString);
            results = search.FindObjects(startIdx, true, pagingSize);
            elements = obj.accessEnumeratorItems(results);
        end
        
        function [attributes] = attributeSearch(obj, searchName, queryString, startIdx, maxFields)
            
            search = OSIsoft.AF.Search.AFAttributeSearch(obj.Database, searchName, queryString);
            results = search.FindObjects(startIdx, true, maxFields);
            attributes = obj.accessEnumeratorItems(results);
        end
    end
    
    methods (Static, Access = 'private')
        function [itemsArray] = accessEnumeratorItems(enumeration)
            %ACCESSENUMERATORITEMS iterate through the enumeration object and return all
            %elements of the enumeration as a cell array of those elements for easier
            %access
            
            iEnumerable = NET.explicitCast(enumeration, 'System.Collections.IEnumerable');
            iEnumerable.GetEnumerator;
            iEnumerator = NET.explicitCast(enumeration,'System.Collections.IEnumerator');
            
            c = 1;
            itemsArray = {};
            while (iEnumerator.MoveNext)
                itemsArray{c} = iEnumerator.Current; %#ok<AGROW>
                c = c+1;
            end
        end
        
        function [value, timestamp, quality] = parseAFValue(afValue)
            %PARSEAFVALUE translate an AFValue to MATLAB datatypes
            
            quality = string(afValue.Status);
            timestamp = afValue.Timestamp.LocalTime;
            timestamp = cce.parseNetDateTime(timestamp);
            
            value = afValue.Value;
            %If data retrieval returns an Exception (.NET System.Exception) return an
            %error
            if isa(value, 'System.Exception')
                if ~contains(string(value.Message), "Data was not available for attribute")
                    error("cce:AFDataConnector:AFValueException", ...
                        "AFData retrieval has resulted in an exception - error messages:\n\n%s\n\n%s\n", ...
                        value.Message, value.StackTrace)
                end
            end
            
            if quality ~= "Bad"
                switch class(value)
                    case 'System.String'
                        value = string(value);
                    case 'System.String[]'
                        value = cell(value, 'ConvertTypes', {'System.String'});
                        value = string(value);
                    case 'OSIsoft.AF.Asset.AFEnumerationValue'
                        value = value.Value;
                    case 'System.DateTime'
                        value = cce.parseNetDateTime(value);
                    case 'numeric'
                end
            elseif quality == "Bad"
                switch afValue.Attribute.Type.FullName
                    case 'System.String'
                        value = string(missing);
                    case 'System.String[]'
                        value = string(missing);
                    case 'OSIsoft.AF.Asset.AFEnumerationValue'
                        value = int32(0);
                    case 'System.DateTime'
                        value = NaT;
                    case 'System.Boolean'
                        value = false;
                    case {'System.Byte', 'System.Double', 'System.Single'}
                        value = NaN;
                    case 'System.Int16'
                        value = int16(0);
                    case 'System.Int32'
                        value = int32(0);
                    case 'System.Int64'
                        value = int64(0);
                    otherwise
                        value = NaN;
                        varType = afValue.Attribute.Type.FullName;
                        warning(['The following AF Attribute variable type is not' ...
                            ' accounted for: %s, value set to NaN'], varType);
                end
            end
        end
    end
    methods (Static)
        function [timespan] = parseTimeSpan(timespan)
            %PARSETIMESPAN parse a timespan string to an AFTimeSpan
            
            spanQualifiers = {'y', 'mo', 'd', 'h', 'm', 's', 'ms'};
            
            lPat = lettersPattern;
            timeQualifiers = extract(timespan, lPat);
            numPat = digitsPattern;
            times = double(extract(timespan, numPat));
            [idx, locb] = ismember(spanQualifiers, timeQualifiers);
            
            spans = zeros(numel(spanQualifiers), 1);
            spans(idx) = times(locb(idx));
            spans = num2cell(spans);
            
            timespan = OSIsoft.AF.Time.AFTimeSpan(spans{:});
        end
        
        function [errs, messages] = readAFErrors(err)
            
            cntServerErrors = err.PIServerErrors.Count;
            cntSystemErrors = err.PISystemErrors.Count;
            cntErrors = err.Errors.Count;
            countAllErrors = cntServerErrors + cntSystemErrors + cntErrors;
            errs = cell(countAllErrors, 1);
            messages = cell(countAllErrors, 1);
            
            idxStart = 1;
            idxEnd = cntServerErrors;
            if cntServerErrors ~= 0
                [errs{idxStart:idxEnd}, messages{idxStart:idxEnd}] = readErrors(err.PIServerErrors);
            end
            
            if err.PISystemErrors.Count ~= 0
                idxStart = idxEnd+1;
                idxEnd = idxEnd+cntSystemErrors;
                [errs{idxStart:idxEnd}, messages{idxStart:idxEnd}] = readErrors(err.PISystemErrors);
            end
            
            if err.Errors.Count ~= 0
                idxStart = idxEnd+1;
                idxEnd = idxEnd+cntErrors;
                [errs(idxStart:idxEnd), messages(idxStart:idxEnd)] = readErrors(err.Errors);
            end
            
            function [errs, messages] = readErrors(dic)
                
                errs = cell(1, dic.Count);
                messages = cell(1, dic.Count);
                c = 1;
                dic_enum = dic.GetEnumerator();
                while (dic_enum.MoveNext())
                    key = dic_enum.Current.Key();
                    errs{c} = dic_enum.Current.Value();
                    messages{c} = errs{c}.Message;
                    c = c+1;
                end
                
            end
        end
    end
end

