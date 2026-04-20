function [startTime] = findScheduledTaskStartTime(offset, frequency)
    %FINDSCHEDULEDTASKSTARTTIME find the earliest viable time for the Coordinator Scheduled
    %Task to start.
    
    arguments
        offset duration;
        frequency duration;
    end
    
    if ~isnan(frequency)
        % Find all possible start times from the first possible start after midnight (i.e.
        % midnight + the offset) in increments of the Coordinator's calculation frequency to
        % the current time plus the greater of the frequency or 10 minutes.
        possibleStarts = dateshift(datetime('now'), 'start', 'day') + offset:frequency:datetime('now') + max([minutes(10), frequency]);
    elseif isnan(frequency)
        possibleStarts = dateshift(datetime('now'), 'start', 'minute'):minutes(1):datetime('now') + minutes(10);
    end
    
    % Find all times that are greater than now
    durToNow = possibleStarts - datetime('now');
    % Find all times that are greater than a minute from now (to allow time for the Task to be
    % created)
    possibleStarts = possibleStarts(durToNow >= minutes(1));
    
    startTime = min(possibleStarts);
end