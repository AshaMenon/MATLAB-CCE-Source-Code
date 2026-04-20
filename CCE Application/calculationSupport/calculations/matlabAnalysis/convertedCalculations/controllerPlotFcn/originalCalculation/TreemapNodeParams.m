classdef TreemapNodeParams < matlab.mixin.Copyable
    %TreemapNodeParams Define a Treemap parameter container with struct cast
    %   Container for parameters that determine Treemap block colour status and
    %   area. The container provides a struct cast. 
    %
    %   TreemapNodeParams Properties;
    %           Area  - numeric scalar, determines a Treemap block relative area
    %   ColourStatus  - ap.TreemapColourStatus scalar, determines Treemap block
    %                   colour
    %   OpmNameInTree - char string, OPM Tree object full name in plant tree. 
    
    properties
        
        Area = []
        %ColourStatus = ap.TreemapColourStatus.empty
        ColourStatus
        OpmNameInTree = ''
        Description = '';

    end
    
    methods (Static)
        
        function s = treemapParamStruct(varargin)
            
            s = struct(ap.TreemapNodeParams(varargin{:}));
            
        end
        
        function status = isTreemapParamStruct(s)
            
            status = all(isfield(struct(ap.TreemapNodeParams()),fieldnames(s)));
            
        end
        
    end
    
    methods
        
        function this = TreemapNodeParams(varargin)
            %Constructor
            %   obj = TreemapNodeParams() constructs default object
            %   obj = TreemapNodeParams(sParam) constructs specific object from parameter
            %   struct, sParam, which must fully specify object properties. This form
            %   is vectorised, so as to support the construction of a vector of objects from
            %   a vector, sParam.
            %   obj = TreemapNodeParams(colourStatus, area) constructs specific object
            %   from struct inputs (one for colour status and one for area value). The OPM
            %   tree node full name must be specified in each struct and must agree. 
            %   obj = TreemapNodeParams(colourStatus, area, name) constructs specific object
            %   from inputs for colour status, area, and OPM tree node full name. 
            
            if nargin < 1
                return
            end
            
            narginchk(0,4);
            parser = inputParser();
            
            switch nargin 
                case 1
                    if isa(varargin{1},class(this))
                        % copy constructor
                        this = copy(varargin{1});
                        return
                    end
                    parser.addRequired('Params',@isstruct);
                    parser.parse(varargin{:});
                    params = parser.Results.Params;
                    [colourStatus{1:numel(params)}] = params.ColourStatus;
                    [area{1:numel(params)}] = params.Area;
                    [name{1:numel(params)}] = params.OpmNameInTree;
                    [description{1:numel(params)}] = params.Description;
                case 2
                    parser.StructExpand = false;
                    parser.addRequired('Colour',@isstruct);
                    parser.addRequired('Area',@isstruct);
                    parser.parse(varargin{:});
                    colourStatus{1} = parser.Results.Colour.ColourStatus;
                    area{1} = parser.Results.Area.Area;
                    name{1} = validatestring(parser.Results.Colour.OpmNameInTree,{parser.Results.Area.OpmNameInTree},'','NameInTree');
                    description{1} = validatestring(parser.Results.Colour.OpmNameInTree,{parser.Results.Area.OpmNameInTree},'','NameInTree');
                case 3
                    parser.addRequired('Colour');
                    parser.addRequired('Area');
                    parser.addRequired('OpmNameInTree');
                    parser.parse(varargin{:});
                    colourStatus{1} = parser.Results.Colour;
                    area{1} = parser.Results.Area;
                    name{1} = parser.Results.OpmNameInTree;
                    description{1} = parser.Results.OpmNameInTree;
                case 4
                    parser.addRequired('Colour');
                    parser.addRequired('Area');
                    parser.addRequired('OpmNameInTree');
                    parser.addRequired('Description');
                    parser.parse(varargin{:});
                    colourStatus{1} = parser.Results.Colour;
                    area{1} = parser.Results.Area;
                    name{1} = parser.Results.OpmNameInTree;
                    description{1} = parser.Results.Description;
            end
            [this(1:numel(colourStatus)).ColourStatus] = colourStatus{:};
            [this(1:numel(area)).Area] = area{:};
            [this(1:numel(name)).OpmNameInTree] = name{:};
            [this(1:numel(name)).Description] = description{:};
            
        end
        
        function s = struct(this)
            %struct Override builtin struct
            
            s(numel(this)) = struct();
            [s.ColourStatus] = this.ColourStatus;
            [s.Area] = this.Area;
            [s.OpmNameInTree] = this.OpmNameInTree;
            [s.Description] = this.Description;
            
        end
        
        function set.ColourStatus(this,value)
            
            validateattributes(value,{class(this.ColourStatus)},{'scalar'},'','colourStatus')
            this.ColourStatus = value;
            
        end
        
        function set.Area(this,value)
            
            validateattributes(value,{'numeric'},{'scalar'},'','area')
            this.Area = value;
            
        end
        
        function set.OpmNameInTree(this,value)
            
            validateattributes(value,{'char'},{'vector'},'','name')
            this.OpmNameInTree = value;
            
        end        
        
        function set.Description(this,value)
            
            validateattributes(value,{'char'},{'vector'},'','description')
            this.Description = value;
            
        end 
    end
    
end

