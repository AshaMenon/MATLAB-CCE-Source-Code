classdef Element < handle
    %Element  PI AF Element class
    %   Use PI AF Element objects to interact with PI AF Elements
    %
    %   Properties:
    %   - Name: [R] Name of the element
    %   - Description: [RW] Description of the element
    %   - TemplateName: [R] Name of element template
    %   - UniqueID: [R] Unique ID of the element
    %   - Path: [R] Path to element
    %   - Attributes: [R] List of PI AF Attributes (a table)
    %   - Categories: [R] List of PI AF Categories associated with this element
    %   - Database: [R] Name of database housing this element
    %   - PISystem: [R] MachineName/Name of PI System housing this element
    %
    %   Constructors:
    %   - af.Element.addElementToRoot: Construct a new element at root level
    %   - af.Element.findByName: Find elements in a database by name
    %   - af.Element.findByTemplate: Find elements in a database by template
    %
    %   Methods:
    %   - addAttribute: Create a value attribute
    %   - addPIPointReference: Create a PI Point Data Reference attribute
    %   - addFormulaReference: Create a Formula Data Reference attribute
    %   - addStringBuilderReference: Create a String Builder Data Reference attribute

    % The actual storage properties - .NET objects
    properties (Access = public) % TODO: Make this private
        NetElement (1,1)
        %NOTNEEDED: Connector (1,1) af.AFDataConnector
    end

    properties (Dependent, SetAccess=private)
        %   [R] Name of the element
        Name (1,1) string
    end
    properties (Dependent)
        %   [RW] Description of the element
        Description (1,1) string
    end
    properties (Dependent, SetAccess = private)
        % [R] Name of element template
        TemplateName (1,1) string
        % [R] Unique ID of the element
        UniqueID (1,1) string
        % [R] Path to element
        Path (1,1) string
        % [R] List of top level PI AF Attributes (a table)
        Attributes (:,5) table
        % [R] List of PI AF Attributes, including child attributes (a table)
        FullAttributes (:,5) table
        % [R] List of PI AF Categories associated with this element
        Categories (:,1) string
        % [R] Name of database housing this element
        DatabaseName (1,1) string
        % [R] MachineName/Name of PI System housing this element
        PISystemName (1,1) string
        % [R] Parent element object, or empty if none
        Parent (1,1) af.Element
        % [R] Children of the element (sub-elements)
        Children (:,1) af.Element
    end

    % Accessor methods
    methods % Getters
        function val = get.Name(obj)
            refreshIfDirty(obj);
            val = string(obj.NetElement.Name);
        end
        function val = get.Description(obj)
            refreshIfDirty(obj);
            val = string(obj.NetElement.Description);
        end
        function val = get.TemplateName(obj)
            refreshIfDirty(obj);
            if isempty(obj.NetElement.Template)
                val = "";
            else
                val = string(obj.NetElement.Template.Name);
            end
        end
        function val = get.UniqueID(obj)
            refreshIfDirty(obj);
            val = string(obj.NetElement.UniqueID);
        end
        function val = get.Path(obj)
            val = makePath(obj.NetElement);
        end
        function val = get.Attributes(obj)
            %get.Attributes  return attribute table for element (name, description, type, NetElement)
            refreshIfDirty(obj);
            attrList = obj.NetElement.Attributes;
            attrCount = attrList.Count;
            if attrCount == 0
                val = table.empty;
            else
                colNames = ["Description", "Type", "Value", "Categories", "NetElement"];
                colTypes = ["string", "string", "cell", "string", "cell"];
                rowNames = strings(attrCount,1);
                for aI = 1:attrCount
                    rowNames(aI) = string(attrList.Item(aI-1).Name);
                end
                val = table('Size', [attrCount, 5], ...
                    'VariableTypes', colTypes, ...
                    'VariableNames', colNames, ...
                    'RowNames', rowNames);
                for aI = 1:attrCount
                    val{aI, 1} = string(attrList.Item(aI-1).Description);
                    val{aI, 2} = getAttributeType(attrList.Item(aI-1));
                    val{aI, 3} = {getValue(attrList.Item(aI-1))};
                    val{aI, 4} = getCategoriesString(attrList.Item(aI-1));
                    val{aI, 5} = {attrList.Item(aI-1)};
                end
            end
        end
        function val = get.FullAttributes(obj)
            %get.Attributes  return attribute table for element and child attributes(name, description, type, NetElement)
            refreshIfDirty(obj);
            attrList = obj.NetElement.Attributes;
            val = table.empty;
            parentAttrName = ""; %Empty since top level

            val = recursivelyGetAttributes(attrList, val, parentAttrName);
            

            function val = recursivelyGetAttributes(attrList, val, parentAttrName)
                %Create table of attributes, then check each for children,
                %appending them to the same table

                attrCount = attrList.Count;
                if attrCount == 0
                    %Dont append to table
                else
                    colNames = ["Name", "Description", "Type", "Value", "Categories", "NetElement"];
                    colTypes = ["cell", "string", "string", "cell", "string", "cell"];
                    % rowNames = strings(attrCount,1);
                    % for aI = 1:attrCount
                    %     rowNames(aI) = string(attrList.Item(aI-1).Name);
                    % end
                    tempVal = table('Size', [attrCount, 6], ...
                        'VariableTypes', colTypes, ...
                        'VariableNames', colNames);

                    for aI = 1:attrCount
                        if numel(parentAttrName{:}) < 1
                            tempVal{aI, 1} = {string(attrList.Item(aI-1).Name)};
                        else
                            tempVal{aI, 1} = {[parentAttrName, string(attrList.Item(aI-1).Name)]};
                        end

                        tempVal{aI, 2} = string(attrList.Item(aI-1).Description);
                        tempVal{aI, 3} = getAttributeType(attrList.Item(aI-1));
                        tempVal{aI, 4} = {getValue(attrList.Item(aI-1))};
                        tempVal{aI, 5} = getCategoriesString(attrList.Item(aI-1));
                        tempVal{aI, 6} = {attrList.Item(aI-1)};
                    end

                    %Append to attribute table
                    val = [val; tempVal];

                    %Loop through found attributes, finding children
                    %attributes
                    for aI = 1:attrCount
                        val = recursivelyGetAttributes(attrList.Item(aI-1).Attributes, val, tempVal{aI, 1}{:});
                    end
                end

            end

        end
        function val = get.Categories(obj)
            refreshIfDirty(obj);
            catStr = string(obj.NetElement.CategoriesString);
            if strlength(catStr)>0
                val = split(extractBefore(catStr, strlength(catStr)), ";");
            else
                val = "";
            end
        end
        function val = get.DatabaseName(obj)
            refreshIfDirty(obj);
            val = string(obj.NetElement.Database.Name);
        end
        function val = get.PISystemName(obj)
            refreshIfDirty(obj);
            piName = string(obj.NetElement.PISystem.Name);
            machineName = string(obj.NetElement.PISystem.MachineName);
            if isequal(piName, machineName)
                val = piName;
            else
                val = piName + " (on " + machineName + ")";
            end
        end
        function val = get.Parent(obj)
            %getParent  Return the parent as an element
            refreshIfDirty(obj);
            if obj.NetElement.IsRoot
                val = af.Element.empty;
            else
                pNet = obj.NetElement.Parent;
                val = af.Element(pNet);
            end
        end
        function val = get.Children(obj)
            % getChildren  Retrieve the children of an element
            %   ChildObj = getChildren(ElementObj) returns the children (Elements) of the element
            %       ElementObj.
            refreshIfDirty(obj);
            if obj.NetElement.HasChildren
                children = obj.NetElement.Elements;
                val=af.Element.empty;
                for k = children.Count:-1:1
                    val(k) = af.Element(children.Item(k-1));
                end
            else
                val = af.Element.empty;
            end
        end
    end
    methods % Setters
        function set.Description(obj, descStr)
            arguments
                obj (1,1) af.Element
                descStr (1,1) string
            end
            try
                obj.NetElement.Description = descStr;
                obj.NetElement.ApplyChanges;
            catch MExc
                disp(MExc.message);
            end
        end
    end

    methods % Constructor, object manipulation
        function obj = Element(netObj)
            %af.Element  Create a MATLAB representation of an AF Element
            %   You cannot construct AF Element objects directly. Use create, findByName,
            %   findByTemplate static methods to create AF Element objects.
            %
            %   See also: af.Element.addElementToRoot, af.Element.findByName, af.Element.findByTemplate.
            if nargin
                mustBeA(netObj, 'OSIsoft.AF.Asset.AFElement');
                obj.NetElement = netObj;
                % NOTNEEDED: obj.Connector = connector;
            end
        end
        function refresh(obj)
            %refresh  Refresh database cache for element
            for k=1:numel(obj)
                obj(k).NetElement.Refresh;
            end
        end
        function applyAndCheckIn(obj)
            %applyAndCheckIn  Apply changes to object and check in if checked out
            %   applyAndCheckIn(obj) applies any changes made to AF Element obj, and if the element
            %       is checked out in this session, checks in those changes. This is a brute force
            %       method of committing changes to the PI AF database.
            obj.NetElement.ApplyChanges;
            if ~isempty(obj.NetElement.CheckOutInfo) && obj.NetElement.CheckOutInfo.IsCheckedOutThisThread
                obj.NetElement.CheckIn;
            end
        end
        function deleteElement(obj)
            %deleteElement deletes inputted array of AF Elements
            %permanently. 
            % 
            % This brute forces deletes, it will attempt to delete
            %elements regardless of being children of other elements in
            %array.

            arguments
                obj (1, :) af.Element {mustBeNonempty}
            end

            %Loop through inputted elements
            for iElement = 1:numel(obj)
                obj(iElement).NetElement.Delete;
                obj(iElement).applyAndCheckIn;
            end
        end
    end
    methods (Access = private)
        function refreshIfDirty(obj)
            if obj.NetElement.IsDirty
                obj.NetElement.Refresh;
            end
        end
        function dcObj = getDataConnector(obj)
            %getDataConnector  COnstruct a DataConnector object for this Element
            %   dcObj = getDataConnector(elObj) returns a DataConnector attached to the database
            %       storing element elObj.
            dcObj = af.AFDataConnector(string(obj.NetElement.Database.PISystem.MachineName), ...
                string(obj.NetElement.Database.Name));
        end
    end
    methods % Attribute methods
        function attr = addAttribute(obj, aName, aValue, opts)
            % addAttribute  Add a value based attribute to an element
            %   AttribNetObj = addAttribute(ElemObj, AName, AValue) adds an attribute named AName
            %       with value AValue to element ElemObj. If Name already exists as an attribute in
            %       ElemObj, an error is generated. AttribNetObj is returned as a PI AF Attribute
            %       .NET object.
            %
            %   AName is either a string for a top level attribute e.g.
            %   "SensorReference", or an array for child attribute creation
            %   e.g. ["SensorReference", "RelativeTimeRange"]
            % 
            %   AValue is converted to a corresponding PI AF Value as follows:
            %       - Numeric values are converted to their .NET counterpart (e.g., uint32 to
            %         VT_UINT32, logical to VT_BOOL). - String or character array scalars are
            %         converted to a .NET String.
            %       - DateTime values are converted to AFTime values.
            %       - Enumerations are converted to their string value.
            %
            %   attribNetObj = addAttribute(..., UOM=UomStr) sets the unit of
            %       measure to UomStr. addPIPointReference  Create a PI Point Data Reference attribute
            arguments
                obj (1,1) af.Element
                aName (1,:) string {mustBeNonzeroLengthText} %(1, :) string array, list of attribute heirarchy e.g. ["SensorReference", "RelativeTimeRange"]
                aValue
                opts.Description (1,1) string = ""
                opts.Categories string = string.empty
                opts.CheckIn (1,1) logical = true;
            end
            % Check if name already exists
            if ~isempty(obj.FullAttributes) && any(cellfun(@(x) isequal(x, aName), obj.FullAttributes.Name))
                error("Element:Attribute:NameExists", "Name '%s' already exists", aName);
            end

            %Check that the parent exists
            if numel(aName) > 1
                aNameParent = aName(1:end - 1);
                parentExits = any(cellfun(@(x) isequal(x, aNameParent), obj.FullAttributes.Name));
                if ~parentExits
                    error("Element:Attribute:ParentDoesntExits", "Parent attribute '%s' doesnt exists", aNameParent);
                end
            end

            % Add the attribute
            parentAttr = obj.NetElement;
            for aI = 1:numel(aName) - 1
                parentAttr = parentAttr.Attributes.Item(aName(aI));
            end
            attr = parentAttr.Attributes.Add(aName(end));
            

            % Set the value - use current time
            afValue = af.makeAfValue(aValue);
            attr.SetValue(afValue);
            % Add the categories
            if ~isempty(opts.Categories)
                % Must add them one at a time.
                allCats = obj.NetElement.Database.AttributeCategories;
                failed = false(size(opts.Categories));
                for k=1:numel(opts.Categories)
                    % We use a try..catch here
                    try
                        attr.Categories.Add(allCats.Item(opts.Categories(k)));
                    catch MExc %#ok<NASGU>
                        % TODO: Should check MExc here but not yet!
                        failed(k) = true;
                    end
                end
                % And report on failures
                if any(failed)
                    catStr = join(opts.Categories(failed),";");
                    warning("Could not find categories in database: %s", catStr);
                end
            end
            if strlength(opts.Description)>0
                attr.Description = opts.Description;
            end
            if opts.CheckIn % Only checkin if the value isn't going to be changed.
                obj.applyAndCheckIn;
            end
        end
        function removeAttribute(obj, name)
            %removeAttribute  Remove an attribute from an element
            %   removeAttribute(elObj, aName) removes the attribute (and any children) named aName
            %       from Element elObj.
            if any(matches(obj.Attributes.Properties.RowNames, name))
                obj.NetElement.Attributes.Remove(name);
                obj.NetElement.ApplyChanges;
            else
                error("Element:Attributes:NameNotFound", "Name '%s' not found", aName);
            end
        end
        function attr = addPIPointReference(obj, aName, piStr, opts)
            %addPIPointReference  Create a PI Point Data Reference attribute
            %   AttribNetObj = addPIPointReference(ElemObj, AName, PIPointStr) adds an attribute
            %       named AName with PI Point referenced by string PIPointStr to element ElemObj. If
            %       Name already exists as an attribute in ElemObj, an error is generated.
            %       AttribNetObj is returned as a PI AF Attribute .NET object.
            %
            %   Optional arguments:
            %       Description=descStr - A string description of the attribute
            %       Categories=catList - A string array defining the Categories to assign to the attribute
            %       CreateIfMissing=true - Automatically create the PI Point if it does not exist.
            arguments
                obj (1,1) af.Element
                aName (1,1) string {mustBeNonzeroLengthText}
                piStr (1,1) string {mustBeNonzeroLengthText}
                opts.Categories string = string.empty
                opts.CreateIfMissing logical = false
                opts.Description (1,1) string = ""
            end
            % Construct the attribute with a dummy value
            attr = addAttribute(obj, aName, 0, ...
                Categories=opts.Categories, CheckIn=false, Description=opts.Description);
            % Now set the datareference
            drPiPoint = attr.PISystem.DataReferencePlugIns.Item("PI Point");
            attr.DataReferencePlugIn = drPiPoint;
            attr.DataReference.ConfigString = piStr;
            % now create if missing
            if opts.CreateIfMissing
                attr.CreateConfig();
            end
            obj.applyAndCheckIn();
        end
        function attr = addFormulaReference(obj, aName, formulaStr, opts)
            %addFormulaReference  Create a Formula Data Reference attribute
            %   AttribNetObj = addFormulaReference(ElemObj, AName, PIPointStr) adds an attribute
            %       named AName with Formula referenced by string PIPointStr to element ElemObj. If
            %       Name already exists as an attribute in ElemObj, an error is generated.
            %       AttribNetObj is returned as a PI AF Attribute .NET object.
            arguments
                obj (1,1) af.Element
                aName (1,1) string {mustBeNonzeroLengthText}
                formulaStr (1,1) string {mustBeNonzeroLengthText}
                opts.Description (1,1) string = ""
                opts.Categories string = string.empty
            end
            % Construct the attribute with a dummy value
            attr = addAttribute(obj, aName, 0, ...
                Description=opts.Description, Categories=opts.Categories, CheckIn=false);
            % Now set the datareference
            drPlugInFormula = attr.PISystem.DataReferencePlugIns.Item("Formula");
            attr.DataReferencePlugIn = drPlugInFormula;
            attr.DataReference.ConfigString = formulaStr;
            obj.applyAndCheckIn;
        end
        function attr = addStringBuilderReference(obj, aName, configStr, opts)
            %addStringBuilderReference  Create a String Builder Data Reference attribute
            %   AttribNetObj = addStringBuilderReference(ElemObj, AName, ConfigStr) adds an attribute
            %       named AName with StringBuilder configuration ConfigStr to element ElemObj. If
            %       Name already exists as an attribute in ElemObj, an error is generated.
            %       AttribNetObj is returned as a PI AF Attribute .NET object.
            arguments
                obj (1,1) af.Element
                aName (1,1) string {mustBeNonzeroLengthText}
                configStr (1,1) string
                opts.Description (1,1) string = ""
                opts.Categories string = string.empty
            end
            % Construct the attribute with a dummy value
            attr = addAttribute(obj, aName, 0, ...
                Description=opts.Description, Categories=opts.Categories, CheckIn=false);
            % Now set the datareference
            sbPlugInFormula = attr.PISystem.DataReferencePlugIns.Item("String Builder");
            attr.DataReferencePlugIn = sbPlugInFormula;
            attr.DataReference.ConfigString = configStr;
            obj.applyAndCheckIn;
        end
        function attList = findAttributes(obj, pv)
            %findAttributes  Search for attributes matching specific criteria
            %   attList = findAttributes(elObj, <Prop1>, <Val1>, ...) returns attributes meeting the
            %       criteria specified by <Prop1>, <Val1>. Valid criteria are:
            %           Type: "numeric", "logical", "String", "PIPoint", "Formula" or "StringBuilder".
            %           Category: a string or strings.
            %           Name: a string
            arguments
                obj (1,1) af.Element
                pv.Category (1,:) string  = ""
                pv.Type (1,1) string {mustBeMember(pv.Type, ["", "numeric","logical","string","PIPoint","Formula","StringBuilder"])} = ""
                pv.Name (1,1) string = ""
            end
            allAttr = obj.Attributes;
            mustReturn = true(height(allAttr),1);
            if any(strlength(pv.Category) > 0)
                mustReturn = mustReturn & contains(allAttr.Categories, pv.Category);
            end
            if strlength(pv.Type) > 0
                % Special case for numerics
                if any(matches(pv.Type, "numeric"))
                    pv.Type = ["double", "single", "int8","uint8","int16","uint16","int32","uint32", pv.Type];
                end
                mustReturn = mustReturn & matches(allAttr.Type, pv.Type);
            end
            if strlength(pv.Name) > 0
                mustReturn = mustReturn & matches(allAttr.Properties.RowNames, pv.Name);
            end
            attList = allAttr(mustReturn,:);
        end
         function attList = findFullAttributes(obj, pv)
            %findAttributes  Search for attributes matching specific criteria
            %   attList = findAttributes(elObj, <Prop1>, <Val1>, ...) returns attributes meeting the
            %       criteria specified by <Prop1>, <Val1>. Valid criteria are:
            %           Type: "numeric", "logical", "String", "PIPoint", "Formula" or "StringBuilder".
            %           Category: a string or strings.
            %           Name: a string
            arguments
                obj (1,1) af.Element
                pv.Category (1,:) string  = ""
                pv.Type (1,1) string {mustBeMember(pv.Type, ["", "numeric","logical","string","PIPoint","Formula","StringBuilder"])} = ""
                pv.Name (1,:) string = "" %String array of attribute hierarchy ["LogParameters", "LogLevel"]
            end
            allAttr = obj.FullAttributes;
            mustReturn = true(height(allAttr),1);
            if any(strlength(pv.Category) > 0)
                mustReturn = mustReturn & contains(allAttr.Categories, pv.Category);
            end
            if strlength(pv.Type) > 0
                % Special case for numerics
                if any(matches(pv.Type, "numeric"))
                    pv.Type = ["double", "single", "int8","uint8","int16","uint16","int32","uint32", pv.Type];
                end
                mustReturn = mustReturn & matches(allAttr.Type, pv.Type);
            end
            if all(strlength(pv.Name) > 0)
                mustReturn = mustReturn & isequal(allAttr.Name, pv.Name);
            end
            attList = allAttr(mustReturn, :);
        end
        function setAttributeValue(obj, aName, aValue)
            %setAttributeValue  Set Attribute Value
            % setAttributeValue(eObj, aName, aValue) sets the attribute Value for attribute named aName in element eObj
            %   to aValue. aValue is converted as follows:
            %       - Enumerations are converted to their int32 equivalents.
            %       - DateTime values are converted to AFTime values.
            %       - All other data types are converted as normal.
            %
            %   If aName is an array of strings, the list of strings defines sub-attributes of the
            %   prior attribute name. For example, ["ExecutionParameters","ExecutionFrequency"]
            %   refers to the "ExecutionFrequency" subAttribute of attribute "ExecutionParameters"]
            opObj = obj.NetElement;
            for aI = 1:numel(aName)
                opObj = opObj.Attributes.Item(aName(aI));
                if isempty(opObj)
                    error("AFElement:setAttributeValue:AttributeNotFound","Could not find attribute in element");
                end
            end
            % It's a normal value. Rely on makeAfvalue to do the conversions.
            afVal = af.makeAfValue(aValue);
            opObj.SetValue(afVal);
        end

        function setHistoricalAttributeValue(obj, aName, aValue, timestamp, args)
            % setHistoricalAttributeValue(obj, aName, aValue, timestamp, args) sets the attribute Value for attribute named aName in element eObj
            %   to aValue, at timestamp. The attribute must have an associated data reference -eg a pi point.  aValue is converted as follows:
            %       - Enumerations are converted to their int32 equivalents.
            %       - DateTime values are converted to AFTime values.
            %       - All other data types are converted as normal.
            %
            %   If aName is an array of strings, the list of strings defines sub-attributes of the
            %   prior attribute name. For example, ["ExecutionParameters","ExecutionFrequency"]
            %   refers to the "ExecutionFrequency" subAttribute of attribute "ExecutionParameters"]
            % 
            % Additionally ValueStatus, UOM and UpdateOption can optionally
            % be specified - see writeFieldHistory in AFDataConnector.m for
            % further info. 

            %TODO add functionality to set multiple times at once.

            arguments
                obj (1, 1) af.Element
                aName (1, :) string
                aValue
                timestamp (1, 1) datetime
                args.ValueStatus string {mustBeMember(args.ValueStatus, ...
                    {'Bad', 'Questionable', 'Good', 'QualityMask', 'SubstatusMask', 'BadSubstituteValue', ...
                    'UncertainSubstituteValue', 'Substituted', 'Constant', 'Annotated'})} = "Good";
                args.UOM = [];
                args.UpdateOption string {mustBeMember(args.UpdateOption, ...
                    {'Replace', 'Insert', 'NoReplace', 'ReplaceOnly', 'InsertNoCompression', 'Remove'})}  ...
                    = "Replace";
            end

            opObj = obj.NetElement;
            for aI = 1:numel(aName)
                opObj = opObj.Attributes.Item(aName(aI));
                if isempty(opObj)
                    error("AFElement:setAttributeValue:AttributeNotFound","Could not find attribute in element");
                end
            end

            connector = obj.getDataConnector;

            % It's a normal value.
            writeFieldHistory(connector, opObj, aValue, timestamp, args.ValueStatus, args.UOM, args.UpdateOption)
        end
        
        % function setAttributeHistoryValue(obj, aName, aValue, )
        function val = getAttributeValue(obj, aName)
            %getAttributeValue  Retrieve value of Element Attribute
            % val = getAttributeValue(eObj, aName) retrieves the attribute value of attribute aName
            %   from element eObj. val is returned as a MATLAB datatype as follows:
            %       - Enumerations are returned as the string value
            %       - AFTime values are converted to datetime.
            %       - All other data types are converted as normal .Net types
            
            arguments 
                obj af.Element
                aName (1, :) string %Array of attribute path eg ["ExecutionParameters", "ExecutionFrequency"]
            end


            opObj = obj.NetElement;
            for aI = 1:numel(aName)
                opObj = opObj.Attributes.Item(aName(aI));
                if isempty(opObj)
                    error("AFElement:getAttributeValue:AttributeNotFound","Could not find attribute in element");
                end
            end
            attr = opObj;
            if isempty(attr)
                val = [];
                warning("AFElement:getAttributeValue:AttributeNotFound", ...
                    "Attribute '%s' not found.", aName);
            else
                afVal = attr.GetValue.Value;
                switch class(afVal)
                    case "System.String"
                        val = string(afVal);
                    case "System.DateTime"
                        val = parseNetDateTime(afVal);
                    case "OSIsoft.AF.Asset.AFEnumerationValue"
                        val = string(afVal.ToString);
                    otherwise
                        val = afVal;
                end
            end
        end
        function [value, timestamp, quality] = getHistoricalAttributeValues(obj, aName, timeRange, args)
            %getHistoricalAttributeValues(obj, aName, timeRange, args) gets
            %attribute values and corresponding times for a given
            %timeRange. Attribute must have an associated data reference eg
            %pi point. 
            % 
            % More info on optional inputs can be found in
            %readFieldRecordedHistory in AFDataConnector.m.
            % 
            % val is returned as a MATLAB datatype as follows:
            %       - Enumerations are returned as the string value
            %       - AFTime values are converted to datetime.
            %       - All other data types are converted as normal .Net types

            arguments
                obj (1, 1) af.Element;
                aName (1, :) string;
                timeRange (2,:) string;

                args.BoundaryType string {mustBeMember(args.BoundaryType, ...
                    {'Inside', 'Outside', 'Interpolated'})} = 'Inside';
                args.UOM = [];
                args.FilterExpression string = "";
                args.IncludeFilterValues logical = true;
                args.MaxCount = 0;
                args.ExcludeBadValues logical = false;
            end

            opObj = obj.NetElement;
            for aI = 1:numel(aName)
                opObj = opObj.Attributes.Item(aName(aI));
                if isempty(opObj)
                    error("AFElement:getAttributeValue:AttributeNotFound","Could not find attribute in element");
                end
            end
            attr = opObj;
            if isempty(attr)
                value = [];
                timestamp = [];
                quality = [];
                warning("AFElement:getAttributeValue:AttributeNotFound", ...
                    "Attribute '%s' not found.", aName);
            else
                connector = obj.getDataConnector;
                [value, timestamp, quality] = readFieldRecordedHistory(connector, attr, timeRange,...
                    "BoundaryType", args.BoundaryType, "UOM", args.UOM, "FilterExpression", args.FilterExpression,...
                    "IncludeFilterValues", args.IncludeFilterValues, "MaxCount", args.MaxCount);
            end
        end
    end
    methods % Element methods
        function newElem = addElement(obj, eName, args)
            %addElement  Add a sub-element to a PI AF Element
            %   newElem = addElement(srcObj, eName) adds an element named eName to srcObj. If an
            %       element named eName already exists, a warning is shown and that element is returned.
            %       The new element has no Categories, or Attributes.
            %
            %   newElem = addElement(srcObj, eName, Template=tmplName) uses the template element
            %       tmplName as the source element.
            %
            %   newElem - addElement(srcObj, eName, Description=descStr) sets the Description of the
            %       new element to descStr.
            arguments
                obj (1,1) af.Element
                eName (1,1) string {mustBeNonzeroLengthText}
                args.Template (1,1) string {mustBeTextScalar} = ""
                args.Description (1,1) string {mustBeTextScalar} = ""
            end
            % Look for an existing element
            mustCreate = true;
            if ~isempty(obj.Children)
                newElem = obj.Children(matches([obj.Children.Name], eName));
                mustCreate = isempty(newElem);
            end
            if mustCreate
                % Create the element
                if (strlength(args.Template) == 0)
                    netObj = obj.NetElement.Elements.Add(eName);
                else
                    % Find the template. We need a DataConnector for this
                    dcObj = obj.getDataConnector;
                    templateNetObj = findTemplateByName(dcObj, args.Template);
                    netObj = obj.NetElement.Elements.Add(eName, templateNetObj);
                end
                % Apply the description if required
                if strlength(args.Description) > 0
                    netObj.Description = args.Description;
                end
                obj.applyAndCheckIn;
                newElem = af.Element(netObj);
            else
                warning("Element:addElement:ElementExists", "Element '%s' already exists.", eName);
            end
        end
        function createPiPoints(obj, args)
            %createPiPoints  Create missing PI Points in an AF Element
            %   This function searches for any attribute that is a PI Point, and if found calls the
            %   CreateConfig method on the attribute's DataReference.

            arguments
                obj (1,1) af.Element
                args.ChildInclusion logical = false;
            end

            if args.ChildInclusion
                attrList = obj.findFullAttributes(Type="PIPoint");
            else
                attrList = obj.findAttributes(Type="PIPoint");
            end

            for aI = 1:height(attrList)
                dr = attrList{aI,"NetElement"}{1}.DataReference;
                CreateConfig(dr);
            end
        end
    end
    methods (Static)
        function obj = addElementToRoot(eName, args)
            %addElemToRoot adds AF Element eName to the highest root level
            %(Elements) on the desired database specified as an
            %AFDataConnector in args.

            %Optional element template specification, args.Template, and
            %description, args.Description, can also be specified.

            %newElem = addElementToRoot("TestElement", "Connector",...
            %af.AFDataConnector("ons-opcdev.optinum.local", "LetheConversion"))
            %adds the new element to the LetheConversion data base.

            arguments
                eName (1,1) string {mustBeNonzeroLengthText}
                args.Template (1,1) string {mustBeTextScalar} = ""
                args.Description (1,1) string {mustBeTextScalar} = ""
                args.Connector (1,1) af.AFDataConnector = af.AFDataConnector("ons-opcdev.optinum.local", "LetheConversion")
            end

            %Look for existing elements
            matchingElements = af.Element.findByName(eName, "Connector", args.Connector,...
                "Template", args.Template); %TODO change to make use of the AllDescendants:False search parameter, then no parent loop required.

            %Check if any are at the root level (ie no parent)
            mustCreate = true;
            for iResult = 1:numel(matchingElements)
                if numel(matchingElements(iResult).Parent) < 1
                    obj = matchingElements(iResult);
                    mustCreate = false;
                    break
                end
            end

            %Create element if needed
            if mustCreate
                obj = args.Connector.createRecord(args.Template, eName);
                obj = af.Element(obj);
                obj.applyAndCheckIn;
            else
                warning("Element:addElementToRoot:ElementExists", "Element '%s' already exists at root level.", eName);
            end
        end
        function obj = find(searchStr, options)
            %find  Find AF Elements based on search string
            %   obj = af.Element.find(SearchStr) searches through the LetheConversion database on
            %       ons-opcdev to find elements matching the search string specified. Use the same
            %       syntax for the search string as you would for the PI System Explorer element
            %       search.
            %
            %   obj = af.Element.find(SearchStr, DataConnector) searches through the database
            %       referenced by DataConnector.
            %   obj = af.Element.find(SearchStr, DataConnector, PageSize=X) sets the Page Size for
            %       the search to X records.
            %
            %   Example: Find elements named "MyElement"
            %       myElements = af.Element.find("Name:MyElement")

            arguments
                searchStr (1,1) string
                options.Connector (1,1) af.AFDataConnector = af.AFDataConnector("ons-opcdev.optinum.local", "LetheConversion")
                options.PageSize (1,1) uint32 = 10000
            end
            try
                netObjects = options.Connector.findRecords("MATLAB", searchStr, 0, options.PageSize);
                if isempty(netObjects)
                    obj = af.Element.empty;
                else
                    for k=numel(netObjects):-1:1
                        obj(k) = af.Element(netObjects{k});
                    end
                end
            catch MExc
                % Show the message as a warning and continue
                warnState = warning("off","backtrace");
                warning("af:Element:FindFailed", "%s", extractBefore(string(MExc.message), "Source:"));
                warning(warnState);
                obj = af.Element.empty;
            end
        end
        function obj = findByName(nameStr, options)
            arguments
                nameStr (1,1) string
                options.Connector (1,1) af.AFDataConnector = af.AFDataConnector("ons-opcdev.optinum.local", "LetheConversion")
                options.PageSize (1,1) uint32 = 10000
                options.Template = "";
            end
            if strlength(options.Template)==0
                searchStr = sprintf("Name:%s", nameStr);
            else
                searchStr = sprintf("Name:%s Template:%s", nameStr, options.Template);
            end
            obj = af.Element.find(searchStr, Connector = options.Connector, PageSize=options.PageSize);
        end
        function obj = findByPath(pathStr, options)
            arguments
                pathStr (1,1) string 
                options.Connector (1,1) af.AFDataConnector = af.AFDataConnector("ons-opcdev.optinum.local", "LetheConversion")
                options.PageSize (1,1) uint32 = 10000
            end
            % Split the path at the last "\" character
            pattern = asManyOfPattern(wildcardPattern + "\");
            namePart = extractAfter(pathStr, pattern);
            pathPart = extractBetween(pathStr, 3, strlength(pathStr)-strlength(namePart)-1);
            searchStr = sprintf("Name:""%s"" Root:""%s""", namePart, pathPart);
            obj = af.Element.find(searchStr, Connector = options.Connector, PageSize=options.PageSize);
        end
        function obj = findByTemplate(nameStr, options)
            %findByTemplate  Find AF Elements by template name
            %   elem = af.Element.findbyTemplate(templateName) finds all elements derived from
            %       templateName (a string) in the default database.
            %
            %   Optional arguments:
            %       Connector=connObj: Use the specified connector instead of the default.
            %       Root=rootStr: Start the search at the path rootStr. rootStr can start with "\\"
            %           or not.
            %       PageSize=nnn: Use a page size of nnn. The default is 10000; reducing the page
            %           size reduces the size of returned data in each call. This function will
            %           return only once all elements are retrieved.
            arguments
                nameStr (1,1) string
                options.Connector (1,1) af.AFDataConnector = af.AFDataConnector("ons-opcdev.optinum.local", "LetheConversion")
                options.PageSize (1,1) uint32 = 10000
                options.Root (1,1) string = ""
            end
            if strlength(options.Root)>0
                if startsWith(options.Root,"\\")
                    options.Root=extractAfter(options.Root,2);
                end
                searchStr = compose("Root:'%s' Template:'%s'", options.Root, nameStr);
            else
                searchStr = compose("Template:'%s'", nameStr);
            end
            obj = af.Element.find(searchStr, Connector=options.Connector, PageSize=options.PageSize);
        end

        function obj = findByUniqueID(uniqueID, options)
            %findByTemplate  Find AF Elements by template name
            %   elem = af.Element.findbyTUniqueID(uniqueID) finds element 
            %       using it's unique id (elemeny id).
            %
            %   Optional arguments:
            %       Connector=connObj: Use the specified connector instead of the default.
            %       Root=rootStr: Start the search at the path rootStr. rootStr can start with "\\"
            %           or not.
            %       PageSize=nnn: Use a page size of nnn. The default is 10000; reducing the page
            %           size reduces the size of returned data in each call. This function will
            %           return only once all elements are retrieved.
            arguments
                uniqueID (1,1) string
                options.Connector (1,1) af.AFDataConnector = af.AFDataConnector("ons-opcdev.optinum.local", "LetheConversion")
                options.PageSize (1,1) uint32 = 10000
                options.Root (1,1) string = ""
            end

            if strlength(options.Root)>0
                if startsWith(options.Root,"\\")
                    options.Root=extractAfter(options.Root,2);
                end
                searchStr = compose("Root:'%s' |LogParameters|CalculationID:=%s", options.Root, uniqueID);
            else
                searchStr = compose("|LogParameters|CalculationID:=%s", uniqueID);
            end
            obj = af.Element.find(searchStr, Connector=options.Connector, PageSize=options.PageSize);
        end
    end
end

