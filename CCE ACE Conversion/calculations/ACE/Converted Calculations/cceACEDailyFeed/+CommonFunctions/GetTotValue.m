function events = GetTotValue(TotTag, ExecTime)


    WhileItt = 145; % Ok for 5min period over 1 day

    try % Construct totaliser final write time from tag atributes and totalising time

        % isolate date of interest
        idx = abs(days(TotTag.TimeStamp-ExecTime)) < 0.1 ;
        TotTagPeriod = TotTag.TimeStamp(idx);
        TotTagOffset  = 0;

        % First period-in-day end, write out time
        FirstPeriodinDayEndTime = TotTagPeriod + seconds(TotTagOffset);

        if any(FirstPeriodinDayEndTime <= ExecTime) || any(seconds(FirstPeriodinDayEndTime-ExecTime)<1)% Totaliser total is possibly correct or old; go forward
            % Go forward 1 totaliser period
            NextEndTime = TotTagPeriod;

            if NextEndTime > ExecTime

                TotEndTime = FirstPeriodinDayEndTime;

            else % totaliser time is old go forward
                TotEndTime = NextEndTime;

            end


        else % Recurse back because totaliser end time is too far ahead
            % Go back 1 totaliser period
            PreviousEndTime = TotTagPeriod;
            Wit = 0;

            while PreviousEndTime > ExecTime % Stops on first period <= input time

                PreviousEndTime = TotTagPeriod(Wit+1);

                Wit = Wit + 1;
                if Wit > WhileItt
                    ME = MException("Too many itterations");
                    throw(ME)
                    break
                end
            end

            TotEndTime = PreviousEndTime;

        end

    catch
        % Not a totalising tag
        ME = MException("Not a totalising tag");
        throw(ME)
    end

    %  Get data at time
    events.Value = [];
    events.TimeStamp = NaT;
    try
        TimeStep = TotTagPeriod;

        if seconds(TimeStep- TotEndTime) < 1
            events.Value = TotTag.Value(idx);
            events.TimeStamp = TimeStep;  % get event time

        else
            Wit = 0;

            while TimeStep > TotEndTime

                idxTotTagTimeStamps = (TimeStep > TotEndTime);
                TimeStep = TotTag.TimeStamp(idxTotTagTimeStamps);


                if TimeStep == TotEndTime
                    events.Value = (TotTag.Value(idxTotTagTimeStamps));
                    events.TimeStamp = TimeStep;  %get event time
                    break
                end

                Wit = Wit + 1;

                if Wit > WhileItt
                    ME = MException("Too many iterations");
                    throw(ME)
                    break
                end


            end


            while events.TimeStamp < TotEndTime

                idx = (events.TimeStamp < TotEndTime);
                TimeStep = TotTag.TimeStamps(idx);

                if TimeStep == TotEndTime
                    events.Value = string(TotTag.Value(idx));
                    events.TimeStamp = TimeStep;  % Get event time
                    break
                end

            end

        end

        if iscell(events.Value)
            try
                events.Value = str2double(events.Value);
            catch
                events.Value = string(events.Value);
            end
        end

        nanIdx = isnan(events.Value);
        events.Value(nanIdx) = 0;


    catch err
        rethrow(err)
    end

    if isempty(events.Value)
        events.Value = 0;
    end

end