classdef AnalysisTSpanResult < matlab.mixin.Copyable
    % Copyable handle class defines an analysis result for a timespan
    properties
        Label  = ''                           % timespan label
        TimeRange = []                        % [start, end] as date numbers
        Result = AnalysisResultTable.empty % analysis result table
    end
    
    properties (Dependent)
        
        AvailableResultTables  % list of Result names
        IsDefault              % isempty(this.Result)
        IsRunSuccess           % post-run status of this result
        FailedResults          % vector of failed AnalysisResultTable objects
        
    end
    
    methods
        
        function this = AnalysisTSpanResult(varargin)
            
            this.Result = AnalysisResultTable();
            
            if nargin == 0
                return
            else
                [label] = varargin{:};
                validateattributes(label,{'char'},{},methodname([],dbstack),'label')
                this.Label = label;
            end
        end
        
        function s = struct(this)
            
            s(numel(this)) = struct('Label',[],'Result',[]);
            
            for k = 1:numel(this)
                thisK = this(k);
                s(k) = struct('Label',{thisK.Label},...
                              'Result',{struct(thisK.Result)});

            end
            
        end
        
        function set.Label(this,value)
            validateattributes(value,{'char'},{},...
                methodname([],dbstack),'timespan label')
            
            this.Label = value;
        end
        
        function set.Result(this,value)
            validateattributes(value,{'AnalysisResultTable'},{'vector'},...
                'result table')
                %methodname([],dbstack),'result table')
            
            this.Result = value;
        end
        
        function addResultTable(this,result)
            % Add either default or specific result table
            
            if nargin < 2
                this.Result(end+1) = AnalysisResultTable();
            else
                validateattributes(result,{class(this.Result)},{},methodname([],dbstack),'result table')
                if isscalar(this.Result) && this.Result.IsDefault
                    % replace first element, if default object (empty Name)
                    this.Result(1) = result;
                else
                    this.Result(end+1) = result;
                end
            end
            
        end
        
        function ts = getTSpanResult(this,label)
            %ts = getTSpanResult(this,label)
            
            if isempty(label) || isempty(this)
                ts = this([]);
                return
            end
            
            validateattributes(label,{'char'},{'vector'},'','label')

            ts = findobj(this,'Label',label);
            
        end
        
        function value = get.AvailableResultTables(this)
           value = {this.Result.Name}; 
        end
        
        function value = get.IsDefault(this)
            value = ~isempty(this) && isempty(this.Result);
        end
        
        function status = get.IsRunSuccess(this)
            status = ~isempty(this.Result) && all([this.Result.IsRunSuccess]);
        end
        
        function ts = get.FailedResults(this)
           ts = findobj(this.Result,'IsRunSuccess',false);
        end        
    end
    
end
