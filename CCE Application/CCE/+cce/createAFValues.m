function [afValues] = createAFValues(data, timestamps, statuses, UOM, containsSystemCode)
    %CREATEAFVALUES create and AFValues collection from DATA, datetime TIMESTAMPS,
    %string STATUSES arrays, and a consistent OSIsoft.AF.UnitsOfMeasure.UOM UOM.

    arguments
        data
        timestamps
        statuses
        UOM
        containsSystemCode = false;
    end
        
    if isscalar(UOM) 
            UOM = repmat(UOM, size(data));
    elseif isempty(UOM)
            UOM = cell(size(data));
    end
    
    afValues = OSIsoft.AF.Asset.AFValues(numel(data));
    
    timestamps = string(timestamps, 'dd-MMM-yyyy HH:mm:ss');
    for c = 1:numel(data)
        if isa(data, 'datetime')
            val = OSIsoft.AF.Time.AFTime(string(data(c, :), 'dd-MMM-yyyy HH:mm:ss'));
        elseif isenum(data)
            val = string(data(c, :)); %TODO: handle at Data Connector - write
        else
            val = data(c);
        end
        timestamp = OSIsoft.AF.Time.AFTime(timestamps(c, :));
        if iscell(UOM)
            thisUOM = UOM{c};
        else
            thisUOM = UOM(c);
        end

        if iscell(val) %If data contains System code data is a cell array
            val = val{1};
        end

        if isstring(val) && containsSystemCode
            %Convert val to system state code
            val = OSIsoft.AF.Asset.AFSystemStateCode.(val);
            newAfValue = OSIsoft.AF.Asset.AFValue.CreateSystemStateValue(val, timestamp);
        else
            status = OSIsoft.AF.Asset.AFValueStatus.(statuses(c));
            newAfValue = OSIsoft.AF.Asset.AFValue(val, timestamp, thisUOM, status);
        end

        afValues.Add(newAfValue);
    end
end

