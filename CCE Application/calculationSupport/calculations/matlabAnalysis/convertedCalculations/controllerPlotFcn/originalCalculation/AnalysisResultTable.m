classdef AnalysisResultTable < matlab.mixin.Copyable
    % Copyable handle class defines a set of results table objects
    % A result table object may contain actual table and MATLAB figure handle. 
    % A table may be a cell array or a struct object. 
    % A relevant exception may be stored in the object for fault tracing. 
    % The result table object may be named, in support of finding a particular
    % result table object in a vector of such objects. In addition, report and
    % figure titles may be stored for reporting purposes. 
    %
    % AnalysisResultTable Properties:
    %     Name
    %     ReportTitle
    %     FigureTitle
    %     Table
    %     ImageH
    %     MovieH
    %     Error
    %     ImgName
    %     IsDefault
    %     IsRunSuccess
    
    properties 
        Name          = '' % name of table or image
        ReportTitle   = '' % title of table in report
        FigureTitle   = '' % title of figure in report
        Table         = {} % table of results
        ImageH        = [] % vector of MATLAB graphics handle
        MovieH        = [] % vector of MATLAB movie graphics handle
        Error         = MException.empty % MException object or error message
        ImgName       = {} % list of image file names
        IsStaticTable = false % default value for static/dynamic table
        IsHeading     = true % default value for table containing heading
    end
    
    properties (Dependent)
        IsDefault    % isempty(this.Name)
        IsRunSuccess % post-run status of result 
    end
    
    methods
        
        function this = AnalysisResultTable(varargin)
            % Constructor
            % obj = AnalysisResultTable() constructs default result table object
            % obj = AnalysisResultTable(name) constructs result table object with specified
            % name
            
            if nargin == 0
                return
            else            
                [name] = varargin{:};
                validateattributes(name,{'char','cell'},{},methodname([],dbstack),'name')
                if ischar(name)
                    this.Name = name;
                elseif iscellstr(name)
                    [this(1:numel(name)).Name] = name{:};
                end
                    
            end
            
        end
        
        function s = struct(this)
            %Overload builtin struct
            
            s(numel(this)) = struct('Name',[],'Table',[],'ImageH',[],'MovieH',[],'ReportTitle',[],'FigureTitle',[],'ImgName',[]);
            
            for k = 1:numel(this)
                thisK = this(k);
                s(k)  = struct('Name',{thisK.Name},...
                               'Table',{thisK.Table},...
                               'ImageH',{thisK.ImageH},...
                               'MovieH',{thisK.MovieH},...
                               'ReportTitle',{thisK.ReportTitle},...
                               'FigureTitle',{thisK.FigureTitle},...
                               'ImgName',{thisK.ImgName},...
                               'IsStaticTable',{thisK.IsStaticTable});
            end
                  
        end
        
        function resultTable = getResultTable(this,name)
            resultTable = getResultTable(this,name)
            
            if isempty(name) || isempty(this)
                resultTable = this([]);
                return
            end
            
            validateattributes(name,{'char'},{'vector'},'','name')
            resultTable = findobj(this,'Name',name);
            
        end
        
        
        function set.Table(this,value)
            validateattributes(value,{'cell','numeric','struct'},{},methodname([],dbstack),'table')
            this.Table = value;
        end
        
        function set.Name(this,value)
            validateattributes(value,{'char'},{},methodname([],dbstack),'name')
            this.Name = value;
        end
        
        function set.ImageH(this,value)
            matlabVersion = ver('MATLAB');
            if str2double(matlabVersion.Version) < 8.4
                % Matlab R2014a and earlier
            	validateattributes(value,{'double'},{'vector'},methodname([],dbstack),'image handle')
            else
                % Matlab R2014b and onwards
                validateattributes(value,{'matlab.ui.Figure'},{'vector'},methodname([],dbstack),'image handle')
            end
            this.ImageH = value;
        end
        
        function set.MovieH(this,value)
            this.MovieH = value;
        end
        
        function set.ImgName(this,value)
            validateattributes(value,{'cell','char'},{},methodname([],dbstack),'image filename')
            this.ImgName = cellstr(value);
        end        
        
        function set.IsStaticTable(this,value)
            validateattributes(value,{'logical'},{},methodname([],dbstack),'is static table')
            this.IsStaticTable = value;
        end
        
        function value = get.IsDefault(this)
           value = ~isempty(this) && isempty(this.Name);
        end
        
        function status = get.IsRunSuccess(this)
            status = ~(isempty(this.Table) && isempty(this.ImageH));
        end
    end
    
end
