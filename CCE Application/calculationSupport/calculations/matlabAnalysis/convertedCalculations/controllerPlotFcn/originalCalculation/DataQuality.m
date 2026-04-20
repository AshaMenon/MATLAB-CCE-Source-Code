classdef DataQuality
    %DataQuality Provides Anglo American Platinum data quality enumeration services
    %   DataQuality defines quality for Anglo American Platinum process data and
    %   provides enumeration and mapping services
    
    % TODO: JPB
    % Remove local DefaultQualityStr and revert to formal PMQuality table
    % for initialising data quality mappings. Change PMQuality names as
    % necessary.
    %
    % Copyright 2013 Anglo American Platinum
    
    properties (Constant, Hidden)
        DefaultUnknownStr  = constants.DataQuality.UnknownStr
        DefaultUnknownEnum = ap.constants.DataQuality.UnknownEnum
        AllEnumFlag        = ap.constants.DataQuality.AllEnumFlag
        Untested           = ap.constants.DataQuality.Untested
        QualityStr         = ap.constants.DataQuality.QualityStr
        QualityEnum        = ap.constants.DataQuality.QualityEnum
        QualityExport      = ap.constants.DataQuality.QualityExport
        
        QValueMap  = containers.Map(lower(ap.constants.DataQuality.QualityStr),...
                                    num2cell(ap.constants.DataQuality.QualityEnum));
        QStringMap = containers.Map(num2cell(ap.constants.DataQuality.QualityEnum),...
                                    ap.constants.DataQuality.QualityStr);
    end
    
    methods
        function display(this)
            keys = strvcat(this.QStringMap.values);
            values = this.QStringMap.keys;
            
            fprintf(1,'\nQuality Enumeration\n\n');
            for k = 1:length(values)
                fprintf(1,'%s : %d\n',keys(k,:),values{k});
            end
        end                
    end
    
    methods (Static)
        
        function value = opmqualityval(qIn)
            % VALUE = opmqualityval(this,QSTR) return quality value(s) for
            % given quality string(s), QSTR. If QSTR is a cell array of
            % strings, VALUE is a cell array of values.
            % In case of unknown quality strings, the return value is the
            % default unknown value.
            
            if ischar(qIn)
                if strcmpi(qIn,ap.DataQuality.AllEnumFlag)
                    value = sort(cell2mat(DataQuality.QValueMap.values));
                else
                    value = DataQuality.qualityValue(lower(qIn));
                end
            elseif iscellstr(qIn)
                value = DataQuality.qualityValue(lower(qIn));
            elseif isnumeric(qIn) || iscell(qIn)
                value = DataQuality.qualityString(qIn);
            end
        end
        
    end

    methods (Static, Hidden)
        
        function value = qualityValue(qStr)
            if ~any(ap.DataQuality.QValueMap.isKey(lower(qStr)))
                value = ap.DataQuality.DefaultUnknownEnum;
                
            elseif iscellstr(qStr)
                value = ap.DataQuality.QValueMap.values(lower(qStr));
                
            else
                value = ap.DataQuality.QValueMap(lower(qStr));
                
            end
        end
        
        function str = qualityString(qVal)
            if isnumeric(qVal) && ~isscalar(qVal)
                qVal = num2cell(qVal);
            end
                
            if iscell(qVal) && isscalar(qVal)
                qVal = qVal{1};
            end
            
            if ~any(ap.DataQuality.QStringMap.isKey(qVal))
                str = ap.DataQuality.DefaultUnknownStr;
                
            else
                if isscalar(qVal)
                    str = ap.DataQuality.QStringMap(qVal);
                    
                elseif iscell(qVal)
                    str = cell(size(qVal));
                    hasVal = ap.DataQuality.QStringMap.isKey(qVal);
                    str(hasVal) = ap.DataQuality.QStringMap.values(qVal(hasVal));
                    str(~hasVal) = {ap.DataQuality.DefaultUnknownStr};
                end
            end
        end
    end
    
end

