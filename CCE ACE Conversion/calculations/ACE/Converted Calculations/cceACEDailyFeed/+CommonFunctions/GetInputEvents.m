function EventsList = GetInputEvents(Tag, WindowStart, WindowEnd, Period, TagType) 

        % Check that the period end is after period start
        if WindowStart > WindowEnd 
          throw(MException("End date is before start date"))
       end


        InDateIt = WindowStart; % Get start of summary period

        try

            PIInVals = [];  % input values from PI

            try % Get input data
                idx = isbetween(Tag.Timestamp,WindowStart, WindowEnd);
                PIInVals = Tag.Value(idx);
            catch 
                PIInVals = [];
            end 


            % Clean data from pi for values required
            Res = 0;


            % get values meeting time range
             PIinVal_SL = [];
            for idx =1:numel(PIInVals)
                PIVal = PIInVals(idx);
                if all(Tag.Timestamp >= WindowStart & Tag.Timestamp <= WindowEnd)
                    % In time range therefore check if double
                    if isnumeric(Res) 
                        %can convert to double - add to list
                        PIinVal_SL = [PIinVal_SL; round(PIVal)];
                    end 
                end 
            end

            EventsList= [];

                switch TagType
                case "2tot" % data is from a 2 point totaliser - get data at specific times

                    % Iterate through times
                    % Get data from period start to period end, with corresponding Data from Weighting tag
                    while InDateIt <= WindowEnd
                        ValTime = InDateIt;
                        if PIinVal_SL.ContainsKey(ValTime) 
                            % Value is in data add to output list
                            EventsList = [EventsList; PIinVal_SL(ValTime), PIinVal_SL(ValTime)];
                        end 

                        InDateIt = InDateIt +seconds(Period); % next date
                    end


                case "event" % Data is from an event tag - get all values
                    EventsList = PIinVal_SL;
                end



        catch 
            EventsList = [];
            % Throw(New Exception("Data collection error: " & InTag.Tag.ToString & " - error: " & ex.Message))
        end 

    end 