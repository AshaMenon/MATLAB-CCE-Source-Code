classdef ap.AnalysisResult < matlab.mixin.Copyable
    %AnalysisResult Define result of an ap.OPMAnalysis run
    % This class defines the result object, returned by ap.OPMAnalysis.run.
    % An analysis result is layered in three tiers, viz.:
    %     1) AnalysisResult
    %     2) AnalysisTSpanResult
    %     3) AnalysisResultTable
    %
    % The design accommodates analysis of multiple data episodes, with
    % multiple result tables and figures per data episode. This class
    % provides the top-level API to the above architecture. 
    %
    % AnalysisResult Properties:
    %     AvailableTimespans  - list of available data episode labels 
    %     Description         - short description of this analysis
    %     ExportTables        - tables to be exported to SQL
    %     ErrorMsg            - run error message or MException
    %     IsRunSuccess        - status of result after run
    %     TimeSpan            - ap.AnalysisTSpanResult vector
    %     Parameters          - a structure containing analysis parameters
    %     PowerPoint          - a structure with PowerPoint export parameters
    %
    % AnalysisResult Methods:
    %     (Static)
    %     addTimeSpanResult   - add ap.AnalysisTSpanResult object
    %     newResultTable      - create ap.AnalysisResultTable object
    %     newTimeSpanResult   - create ap.TimeSpanResult object
    %
    %     (Non-static)
    %     AnalysisResult      - constructor
    %     struct              - cast this object to struct
    %
    % Copyright 2013 Anglo American Platinum
    
    properties
        Description  = ''
        TimeSpan     = AnalysisTSpanResult.empty
        ErrorMsg     = ''
        ExportTables = []
        Parameters
        PowerPoint
        Signature    = {}
    end
    
    properties (Dependent)
        AvailableTimespans
        IsRunSuccess
        FailedTimeSpans
    end
    
    methods (Static)
       
        function tsResult = newTimeSpanResult(label)
           % Create a default timespan result object
           
           if nargin == 0
               tsResult = AnalysisTSpanResult();
           else
               tsResult = AnalysisTSpanResult(label);
           end
           
        end
        
        function OPMtable = newResultTable(name)
           % Create a default result table object
           
           if nargin == 0
               OPMtable = AnalysisResultTable();
           else
               OPMtable = AnalysisResultTable(name);
           end
           
        end        
    end
    
    methods
        
        function this = AnalysisResult(inputObj)
            % Constructor
            % RESULT = AnalysisResult(INPUT)
            % INPUT can be another AnalysisResult object; a description
            % string, or a struct with a subset of properties of RESULT.
            
            if nargin == 0
                return
            else
               if isstruct(inputObj)
                   field = fieldnames(inputObj);
                   prop  = properties(this);
                   for k = 1:numel(field)
                       fieldK = validatestring(field{k},prop,mfilename('class'),'fieldname');
                       this.(fieldK) = inputObj.(field{k});
                   end
                   
               elseif ischar(inputObj)
                   this.Description = inputObj;
                   this.TimeSpan = AnalysisTSpanResult();
                   
               elseif isa(inputObj,class(this))
                   this = copy(inputObj);
               end
            end
        end
        
        function obj = struct(this)
            % Cast this object to a struct
            obj = struct('Description',{this.Description},...
                         'TimeSpan',{struct(this.TimeSpan)},...
                         'ErrorMsg',{this.ErrorMsg});
            
        end
        
        function addTimeSpanResult(this,tsResult)
            % Add either default or specific timespan result
            %  addTimeSpanResult(this) adds default timespan result
            %  addTimeSpanResult(this,TSRESULT) adds TSRESULT
            
            if nargin < 2
                this.TimeSpan(end+1) = AnalysisTSpanResult();
            else
                validateattributes(tsResult,{class(this.TimeSpan)},{},methodname([],dbstack),'ts result')
                % replace first element, if default object 
                if isscalar(this.TimeSpan) && this.TimeSpan(1).IsDefault
                    this.TimeSpan(1) = tsResult;
                else
                    this.TimeSpan(end+1) = tsResult;
                end
            end
            
        end
        
        function removeTimeSpanResult(this,tsResult)
            % Remove specified TimeSpanResult object from this container
            %  removeTimeSpanResult(this,TSRESULT)
            
            if isempty(tsResult)
                return
            else
                validateattributes(tsResult,{class(this.TimeSpan)},{'scalar'},'','ts result')
            end
            
            this.TimeSpan(this.TimeSpan == tsResult) = [];
            
        end
        
        function tsResult = getTSpanResult(this,tsLabel)
            %Lookup timespan result object by timespan label
            %  tsResult = getTSpanResult(this,tsLabel)
            
            if isempty(tsLabel)
                tsResult = this.TimeSpan([]);
                return
            end
            
            tsResult = this.TimeSpan.getTSpanResult(tsLabel);
            
        end
        
        function resultTable = getResultTable(this,tsLabel,resultTableName)
            %Lookup AnalysisResultTable object 
            %  resultTable = getResultTable(this,tsLabel,resultTableName)
            
            if isempty(tsLabel) || isempty(resultTableName) || isempty(this)
                resultTable = AnalysisResultTable.empty;
                return
            end
            
            tsResult = this.getTSpanResult(tsLabel);
            if isempty(tsResult)
                resultTable = AnalysisResultTable.empty;
            else
                resultTable = tsResult.Result.getResultTable(resultTableName);
            end
            
        end
        
        
        function addParameters(this, analysisParser, varargin)
            % addParameters add analysis parameters to results structure
            %   addParameters(This, AnalysisParser) adds all of the
            %   parameters defined in AnalysisParser (the analysis
            %   technique argument parser) to the analysis parameters.
            %
            %   addParameters(... 'ModifiedValues', ModifiedValues) changes
            %   the value of the parameter to the value in the
            %   ModifiedValues cell, and stores the original value in the
            %   'ModifiedFromValue' field of the parameters strucutre.
            %   ModifiedValues should take the form {'<ParamName>',
            %   <ParamValue>, ...}.
            %
            %   addParameters(... 'IsRequired', IsRequired) excludes any
            %   parameters who have their value in the IsRequired cell set
            %   to false. IsRequired should taek the form {'<ParamName>',
            %   true/false} where false indicates that the parameter should
            %   be excluded from the Parameters field of the Results
            %   structure.  By default, all parameters will be included,
            %   unless indicated otherwise by the IsRequired field.  
            
            p = inputParser;
            p.addParamValue('ModifiedValues',[],...
                @(x)(isempty(x) || (iscell(x) && mod(length(x),2) == 0)));
            p.addParamValue('IsRequired', [], ...
                @(x)(isempty(x) || (iscell(x) && mod(length(x),2) == 0)));
            p.parse(varargin{:})
            modifiedValues = p.Results.ModifiedValues;
            isRequired = p.Results.IsRequired;
            
            % Get the parameter names and assign to the parameter structure
            this.Parameters.Name = analysisParser.Parameters;
            
            % Get the parameter values and assign to the parameter
            % structure
            for k = 1:length(this.Parameters.Name)
                valueK = analysisParser.Results.(this.Parameters.Name{k});
                if isstruct(valueK)
                    if isfield(valueK, 'NameInTree')
                        this.Parameters.Value{k} = valueK.NameInTree;
                    elseif isfield(valueK, 'Context')
                        this.Parameters.Value{k} = valueK.Context.NameInTree;
                    elseif isempty(valueK)
                        this.Parameters.Value{k} = [];
                    end
                else
                    this.Parameters.Value{k} = valueK;
                end
            end
            
            % Get the parameter default indicator and assign to the
            % parameter structure
            this.Parameters.IsDefault = ismember(this.Parameters.Name, analysisParser.UsingDefaults);
            
            this.Parameters.ModifiedFromValue = cell(size(this.Parameters.Name));
            if ~isempty(modifiedValues)
                for k = 1:2:length(modifiedValues)
                      modifiedInd = strcmp(this.Parameters.Name, modifiedValues{k});
                    this.Parameters.ModifiedFromValue(modifiedInd) = ...
                        this.Parameters.Value(modifiedInd);
                    this.Parameters.Value(modifiedInd) = modifiedValues(k+1);
                end
            end
            
            % Parse the parameters that might not be required in the
            % analysis table.
            isParamRequired = true(size(this.Parameters.Name));
            if ~isempty(isRequired)
                for k = 1:2:length(isRequired)
                    reqInd = strcmp(this.Parameters.Name, isRequired{k});
                    isParamRequired(reqInd) = isRequired{k + 1};
                end
                this.Parameters.Name = this.Parameters.Name(isParamRequired);
                this.Parameters.Value = this.Parameters.Value(isParamRequired);
                this.Parameters.IsDefault = this.Parameters.IsDefault(isParamRequired);
                this.Parameters.ModifiedFromValue = this.Parameters.ModifiedFromValue(isParamRequired);
            end
        end
        
        function value = get.AvailableTimespans(this)
            value = {this.TimeSpan.Label};
        end
        
        function status = get.IsRunSuccess(this)
            status = isempty(this.ErrorMsg) && ~isempty(this.TimeSpan);% && all([this.TimeSpan.IsRunSuccess]);
        end
        
        function ts = get.FailedTimeSpans(this)
           ts = findobj(this.TimeSpan,'IsRunSuccess',false);
        end
        
    end
    
end

