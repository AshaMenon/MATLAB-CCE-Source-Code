function nextOutputTime = getNextOutputTime(lastCalculationTime, offset, frequency)
    %getNextOutputTime This function will get the nextOutputTime
    % The nextOutputTime is based on the LastCalculationTime, Offset and
    % Frequency values.
    arguments
        lastCalculationTime (1,1) datetime {mustBeNonempty}
        offset (1,1) duration {mustBeNonempty}
        frequency (1,1) duration {mustBeNonempty}
    end
    
    offset.Format = 's';
    frequency.Format = 's';
    
    if offset > frequency
        offset = mod(offset, frequency);
    end
    
    startTime = dateshift(lastCalculationTime, 'start', 'day');
    firstCalculationTime = startTime + offset;
    nextOutputTime = (floor((lastCalculationTime - firstCalculationTime)/frequency) + 1) * frequency + firstCalculationTime;
end

