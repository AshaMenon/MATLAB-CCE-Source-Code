classdef AnalysisTechnique < OPMCalculationEngine.IAnalysisTechnique
    %ANALYSISTECHNIQUE Concrete base class to OPM analysis techniques
    %   This class implements the methods common to all Amplats OPM
    %   analysis technique classes.
    %   The class form the middle tier of the analysis and reporting
    %   architecture. 
    %
    %   The class provides the following services:
    %     a) resolve the analysis technique function
    %     b) marshall analysis input objects to basic data type objects
    %     c) call the analysis tecnique function 
    %     d) write results to export fiile
    %     
    %   When the run method is invoked, the following work flow occurs:
    %     i) marshall analysis input objects to basic data type objects
    %     ii) call analysis technique function and pass input arguments
    %     iii) return result object 
    %
    %   See also: ap.analysisFcn, OPMConfigurationManager.OPMAnalysis
    %
    % AnalysisTechnique Properties:
    %    Dependency    = {}      - these techniques must run before this
    %    Arguments     = {}      - list of analysis input objects 
    %    AnalysisFcn   = []      - analysis technique function
    %    IsResolvedArg           - state of plant-level argument resolution
    %    IsResolvedFcn           - state of technique function resolution
    %
    % AnalysisTechnique Methods:
    %    AnalysisTechnique        - constructor
    %    getAnalysisDependencies  - get analysis sensor/analysis dependencies
    %    run                      - run analysis function 
    %    setArguments             - set plant-level arguments
    %
    % Copyright 2013 Anglo American Platinum
    
    properties (Constant, Hidden)
        SensorDataClassName = 'ap.SensorData'
        SensorClassName     = ap.constants.OPMSensor.ClassName
        UnitClassName       = ap.constants.OPMUnit.ClassName
    end
    
    properties (Hidden)
        TotalNumberOfSensors = 0   % Total number of applicable sensors 
        TotalNumberOfUnits   = 0   % Total number of applicable units 
        
        RecurseCounter = 0                 % Counter for recursive analyses (used in derived classes)
        ArgumentParser = inputParser.empty % Argument parser (used in derived classes)
        ArgumentResolutionRule = [];       % Argument resolution verification rule
        RequiredInputCount = 0;            % Required minimum resolved input objects
    end
    
    properties (SetAccess = protected)
        
        UseTreemap = false;
        DependencyFilter = '*'  % can be '*' or 'this'; 
                                % '*' submits dependencies across tree in focus; 
                                % 'this' restricts dependencies to those at associated OPM unit or sensor
        
    end
    
    properties (Dependent)
        ArgumentsToString
        ArgumentIterator
    end
    
    methods (Static)
        
        function obj = marshallUnitArgument(aUnit,sensorData)
            % Marshall OPMUnit object and SensorData object to struct tree 
            obj = struct(OPMDataCollections.ElementStruct(aUnit,sensorData));
        end
        
        function obj = marshallSensorArgument(aSensor,sensorData)
            % Adapt sensor input argument to structure input argument
            
            % cast sensor data to struct
            % we must handle elements of sensor vector individually to
            % ensure that sensor data are grouped per sensor
            if isempty(aSensor) 
                obj = struct(OPMDataCollections.AnalysisInputCollection.empty);
                
            elseif isscalar(aSensor)
                sdata = struct(sensorData.getSensorData(aSensor));
                % create input object as struct
                obj = struct(OPMDataCollections.AnalysisInputCollection(struct(aSensor),sdata));
                
            else
                obj(numel(aSensor)) = struct(OPMDataCollections.AnalysisInputCollection());
                for k = 1:numel(obj)
                    sdata  = struct(sensorData.getSensorData(aSensor(k)));
                    obj(k) = struct(OPMDataCollections.AnalysisInputCollection(struct(aSensor(k)),sdata));
                end
            end
            
        end
        
        function obj = marshallConstantArgument(arg)
            % Adapt constant input argument to structure input argument
            
            % create input object as struct 
            obj = struct(OPMDataCollections.AnalysisInputCollection([],arg));
            
        end        

    end
    
    methods
        
        function this = AnalysisTechnique(varargin)
            %Constructor
            % this = AnalysisTechnique(DEFINITION) creates THIS analysis
            % technique from struct, DEFINITION.
            
            
            this = this@OPMCalculationEngine.IAnalysisTechnique(varargin{:});
            
            % set default argument resolution verification rule
            this.ArgumentResolutionRule = 'verifyArgumentsFullyResolved';
                        
        end
        
        function result = run(this,description,sdata,varargin)
            % Run analysis technique
            % RESULT = run(this,DESCRIPTION,SDATAMAP,...)
            
            % verify that analysis technique function is valid
            validateattributes(this.AnalysisFcn,...
                {'function_handle'},{'nonempty'},methodname([],dbstack),'this.AnalysisFcn')
            
            % Input the unit's name in tree into the function for exporting purposes. Where
            % required the unit name in tree will be used to create a tag name
            indxUnit = cellfun(@(x)isa(x,'ap.OPMUnit'),varargin);
            if any(indxUnit)
                unitNameInTree = varargin{indxUnit}.NameInTree;
                % retrieve analysis function input data
                fcnArg = this.marshallAnalysisInput(sdata);
                fcnArg = [fcnArg,'unitNameInTree',unitNameInTree];
            else
                % retrieve analysis function input data
                fcnArg = this.marshallAnalysisInput(sdata);
            end
            
%             % We check for the export tag value input argument here to pass in the unit name in
%             % tree if required
%             if any(strcmp(this.Arguments,'unitNameInTree'))
%                 indx = strcmp(this.Arguments,'unitNameInTree');
%                 exportTagValue = this.Arguments{find(indx) + 1};
%                 if isempty(exportTagValue)
%                     this.Arguments{find(indx) + 1} = varargin{indxUnit}.NameInTree;
%                 end
%             end

            
            % retrieve analysis function input data
%             fcnArg = this.marshallAnalysisInput(sdata,exportDB);
%             fcnArg = [fcnArg,'unitNameInTree',unitNameInTree];
            
            % call analysis function
            try
                if isempty(description)
                    description = 'NO DESCRIPTION DEFINED';
                end
                result = this.AnalysisFcn(description,fcnArg{:});
            catch exception 
                rethrow(exception)
            end
            
        end
        
        function [sensorObjs, analysisObjs] = getAnalysisDependencies(this,~,~)
            %% getAnalysisDependencies fetch dependent sensors and analyses
            %   [SensorObjs,AnalysisObs] = getAnalysisDependencies(This,
            %   Opmconfig,AllApps) returns an array of all of the sensor
            %   objects which the analysis requires to run and all of the
            %   analysis objects.  If there are no sensor or analysis
            %   dependencies, then empty arrays will be returned.
            %
            %   INPUTS:
            %     Opmconfig: The ap.OPMConfiguration object.
            %     AllApps: An array of all of the ap.OPMAnalysis objects
            %              configured in the analysis to look up analysis
            %              dependencies.
            %
            %   OUTPUTS:
            %     SensorObjs: An array of the sensor objects which the
            %                 analysis depends on.
            %     AnalysisObjs: An array of the analysis objects which the
            %                   analysis depends on.
            %
            %   If the analysis has a more
            %   complicated relationship with the sensor objects, then this
            %   method needs to be overwritten in an analysis technique
            %   object specific to the analysis.
            %
            % Added by SJM, OPTI-NUM solutions (17/12/2013)
            
            isSensorArg = cellfun(@(arg)isa(arg, 'ap.OPMSensor'), this.Arguments);
            sensorObjs = [this.Arguments{isSensorArg}];
            analysisObjs = [];
        end
        
        function rptString = report(this,description,result,unit,rptDir)
            % Report the results of an analysis technique function.
            % RPTSTRING = report(this,DESCRIPTION,RESULT,UNIT,RPTDIR)
            % The results can be image files and tables.
            
            % Heading: H3
            htmlFmt = '<H3>%s</H3>\n';
            if isempty(result) || isempty(result.Description)
                s = sprintf(htmlFmt, description);
            else
                s = sprintf(htmlFmt, result.Description); % override DESCRIPTION, received from caller
            end
            
            if ~isempty(result)
                % iterate through array of result table objects
                for tsResult = result.TimeSpan(:)'
                    % iterate through array of result table objects
                    if ~isempty(tsResult)
                        for kk = 1:numel(tsResult.Result)
                            tableObj = tsResult.Result(kk);
                            if ~isempty(tableObj.ReportTitle)
                                % add table title
                                tblTitle = tableObj.ReportTitle;
                            elseif kk == 1
                                tblTitle = '';
                            elseif kk > 1
                                tblTitle = ' ';
                            end
                            
                            % JPB 2015/10/14: if tableObj is a cell array, render table
                            if ~isempty(tableObj.Table) && iscell(tableObj.Table) %% JPB modified this condition
                                % Parse table and add hyperlinks.
                                analysisTable = tableObj.Table;
                                analysisTable = opm.addhyperlink(analysisTable, unit);
                                s = sprintf('%s%s\n', s, opm.htmltable(analysisTable, tblTitle, true, '%g', tableObj.IsStaticTable));
                            end
                            
                            % convert any figure objects to image files
                            if ~isempty(tableObj.ImageH)
                                if ~isempty(tableObj.FigureTitle)
                                    s = sprintf('%s<P><B>%s</B></p>\n', s, tableObj.FigureTitle);
                                end
                                if isempty(tableObj.ImgName)
                                    [tableObj.ImgName{1:numel(tableObj.ImageH)}] = '';
                                end
                                for k = 1:numel(tableObj.ImageH)
                                    fig = tableObj.ImageH(k);
                                    if ishandle(fig)
                                        % Create unique ID
                                        figTitle = get(fig,'Children');
                                        figTitle = get(figTitle(end),'Title');
                                        figTitle = figTitle.String;
                                        if iscell(figTitle), figTitle = figTitle{1}; end
                                        strID = dec2bin([figTitle this.ArgumentsToString]); % Use description as unique identifier
                                        for i = 1:size(strID,1)
                                            numID(i) = str2double(strID(i,:));
                                        end
                                        tableObj.ImgName{k} = this.pOPMgrabfigure(fig,sum(numID)+k,rptDir,tableObj.ImgName{k});
                                        drawnow
                                    end
                                    s = sprintf('%s%s\n', s, opm.htmlimage(sprintf('./%s', tableObj.ImgName{k})));
                                end
                            end
                        end
                    end
                end
            end
            
            % Always end with a blank line
            rptString = sprintf('%s\n', s);
        end
        
        function string = get.ArgumentsToString(this)
            
            if isempty(this)
                string = {};
                return
            else
                fcnArguments = this(1).Arguments; % support scalar THIS
            end
            
            list = cell(2,numel(fcnArguments)/2); % parameter-value pairs
            for k = this(1).ArgumentIterator
                argK = fcnArguments{k};
                switch class(argK)
                    case {'double','logical'}
                        value = sprintf('%d',argK);
                    case {'ap.OPMSensor','ap.OPMUnit'}
                        value = argK.NameInTree;
                    case 'char'
                        value = argK;
                    otherwise
                        value = class(value);
                end
                list(:,k/2) = {sprintf('%s',fcnArguments{k-1});value};
            end
            fmt = sprintf('\\t%%%ds: %%s\\n',max(cellfun(@(c)numel(c),list(1,:))));
            string = sprintf(fmt,list{:});
        end
        
        function setArguments(this,fcnArguments)
            % Verify and set plant-level arguments
            % setArguments(this,fcnArguments) set list of arguments, which are
            % specified as parameter-value pairs
            % INPUT:
            %      fcnArguments: 1xn cell, where n is even
            
            fname = methodname(meta.class.fromName(mfilename('class')),dbstack);
            
            validateattributes(fcnArguments,{'cell'},{},fname,'arguments')
            validateattributes(numel(fcnArguments),{'numeric'},{'even'},...
                fname,'number of arguments')
            
            isUnresolved = false(1,numel(fcnArguments));
            
            % technique is unresolved if any sensor or unit input
            % arguments is unresolved
            for k = 2:2:numel(fcnArguments)
                argK = fcnArguments{k};
                isUnresolved(k) = strcmpi(argK,ap.constants.OPMAnalysis.Unresolved);
            end
            
            % apply default rule: All arguments must be fully resolved
            feval(this.ArgumentResolutionRule,this,fcnArguments,isUnresolved,this.RequiredInputCount);
                        
        end
        
        function iter = get.ArgumentIterator(this)
            % Arguments form parameter-value pairs
            
            iter = 2:2:numel(this.Arguments);
            
        end
        
    end
    
    methods (Access = protected, Hidden, Sealed)
        
        function fcnInput = marshallAnalysisInput(this,sdata)
            % Marshall analysis input objects to function arguments
            % Method is sealed.
            
            if isempty(this.Arguments) || ~this.IsResolvedArg
                return
            end
            
            % verify sensor data map
            validateattributes(sdata,{this.SensorDataClassName}, {'vector'},...
                methodname([],dbstack),...
                'sensor data')
            
            fcnInput = this.Arguments;

            % iterate through plant-level arguments
            % resolve each argument to primitive type value
            
            for k = this.ArgumentIterator
                
                argK = this.Arguments{k};
                
                if isa(argK,this.UnitClassName)
                    % mashall unit argument
                    fcnInput{k} = this.marshallUnitArgument(argK,sdata);
                    
                elseif isa(argK,this.SensorClassName)
                    % marshall sensor argument
                    fcnInput{k} = this.marshallSensorArgument(argK,sdata);
                    
                elseif islogical(argK) || isnumeric(argK) || ischar(argK) 
                    % mashall constant argument
                    fcnInput{k} = argK;
                    
                else
                    % unknown; let technique function handle argument
                    continue
                end
            end
        end
        
    end
    
    methods (Access = protected, Hidden)
        
        function verifyArgumentsFullyResolved(this,fcnArguments,isUnresolved,~)
            % Implement input rule: Requires all inputs resolved
           
            % technique is unresolved if any sensor or unit input
            % arguments is unresolved
            if ~any(isUnresolved)
                this.Arguments = fcnArguments;
                this.UnResolvedArguments = {}; % reset accumulator of unresolved arguments
                
            else
                this.Arguments  = {};
                this.UnResolvedArguments = fcnArguments(find(isUnresolved)-1); 
            end
            
        end
        
        function verifyArgumentsPartiallyResolved(this,fcnArguments,isUnresolved,minSensorCount)
            % Implement input rule: Requires some inputs resolved
           
            % scan for unresolved input sensor arguments
            % replace unresolved by the empty sensor object
            fcnArguments(isUnresolved) = {ap.constants.OPMSensor.Empty};
            
            % technique is unresolved if less than two of input sensor
            % arguments are unresolved 
            if nnz(~isUnresolved)-numel(this.ArgumentIterator) >= minSensorCount
                this.Arguments = fcnArguments;
                this.UnResolvedArguments = {}; % reset accumulator of unresolved arguments
                
            else
                this.Arguments  = {};
                this.UnResolvedArguments = fcnArguments(find(isUnresolved)-1); 
            end
            
        end
        
    end
    
    methods (Static, Access = protected)
       
        function imgName = pOPMgrabfigure(f,uIndex,rptDir,currentImgName)
            checkdirexists(rptDir);
            drawnow;
            if ishandle(f) % grab figure as image and delete figure object
%                 rng('default');
%                 imgName = sprintf('opmFigure%04d_%d.png',uIndex,ceil(1000000*rand(1)));
                imgName = sprintf('opmFigure%04d.png',uIndex);
                graphSize    = get(f,'PaperPosition');
                graphSize(4) = 20;
                set(f, 'PaperPosition', graphSize);
                opmgrabfigure(f, fullfile(rptDir, imgName));
                drawnow
                delete(f)
                
            elseif ~isempty(currentImgName) % keep existing image
                imgName = currentImgName;
                drawnow;
                try delete(f); catch, end
            else
                imgName = '';
                drawnow;
                try delete(f); catch, end
            end
        end
        
    end
    
end