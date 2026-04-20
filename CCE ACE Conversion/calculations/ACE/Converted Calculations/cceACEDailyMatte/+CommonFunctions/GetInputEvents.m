function EventsList = GetInputEvents(Tag, WindowStart, WindowEnd, Period, TagType)

EventsList.Times = [];
EventsList.Values = [];

%Check that the period end is after period start
if WindowStart > WindowEnd
    throw(MException("GetInputEvents:inputError","End date is before start date"))
end

InDateIt = WindowStart; % get start of summary period

try

    try %get input data
        idx = isbetween(Tag.Times, WindowStart, WindowEnd);
        PIInVals.Values = Tag.Values(idx);
        PIInVals.Times = Tag.Times(idx);
    catch 
        PIInVals.Values = [];
        PIInVals.Times = [];
    end

    %Clean data from pi for values required
    PIinVal_SL.Values = [];
    PIinVal_SL.Times = [];

    if iscell(PIInVals.Values)
        doConversion = true;
    else
        doConversion = false;
    end

    %get values meeting time range
    for PIVal = 1:length(PIInVals.Values)
        if PIInVals.Times(PIVal) >= WindowStart && PIInVals.Times(PIVal) <= WindowEnd
            %in time range therefore check if double
            
            if doConversion
                try
                    val = PIInVals.Values(PIVal);
                    val = val{1};
                    val = str2double(val);
                catch
                    val = "Not numeric";
                end
            else
                val = PIInVals.Values(PIVal);
            end

            if isnumeric(val) && ~isnan(val)
                %can convert to double - add to list
                PIinVal_SL.Values = [PIinVal_SL.Values; val];
                PIinVal_SL.Times = [PIinVal_SL.Times; PIInVals.Times(PIVal)];
                %round to find time matches easier
            end
        end
    end

    switch TagType

        case "2tot" %data is from a 2 point totaliser - get data at specific times

            %Itterate through times

            % get data from period start to period end, with corresponding Data from Weighting tag
            while InDateIt <= WindowEnd
                ValTime = InDateIt;

                if ismember(PIinVal_SL.Times, ValTime)
                    %Value is in data add to output list
                    EventsList.Times = [EventsList.Times; PIinVal_SL.Times(ismember(PIinVal_SL.Times, ValTime))];
                    EventsList.Values = [EventsList.Values; PIinVal_SL.Values(ismember(PIinVal_SL.Times, ValTime))];
                end

                InDateIt = InDateIt + seconds(Period); % next date

            end

        case "event" %data is from an event tag - get all values
            EventsList = PIinVal_SL;
    end

catch ex
    throw(MException("GetInputEvents:dataCollection", "Data collection error: " + string(InTag) + " - error: " + ex.Message))
end
end