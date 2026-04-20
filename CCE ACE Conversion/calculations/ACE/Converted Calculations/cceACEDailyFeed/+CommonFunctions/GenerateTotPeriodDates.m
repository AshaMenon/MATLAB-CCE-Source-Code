function dates = GenerateTotPeriodDates(ExecTime, TotPeriod, TotOffset) 
        
        % Generate relevant datetimes
        format longG

        try
            % This gets the local date as seconds past 1 Jan 1970 00:00:00
            %ExecTime_UTC = convertTo(ExecTime,'posixtime');
            ExecTime_UTC = ExecTime - datetime(1970,01,01,0,0,0);
            ExecTime_UTC = seconds(ExecTime_UTC);

            % Get the remainder of the current time less the offset and the period
            ModTime = rem(ExecTime_UTC - TotOffset, TotPeriod);

            diffSecs = ExecTime_UTC - ModTime;
            second_date = datetime(1970,01,01,0,0,0) + seconds(diffSecs); % Convert to universal time

            first_date = second_date + seconds(-TotPeriod) + seconds(1); % Less period and add 1 second;
            dates  = {first_date, second_date};

        catch ex 
             %Me = MException("Fundamental date calculation failed.");
             rethrow(ex)
        end 

end