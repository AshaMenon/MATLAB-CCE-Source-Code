function outTT = combineSoundings(inputs)
    fields = string(fieldnames(inputs));

    % find sounding ports
    idx = contains(fields, "SoundingPort");
    fields = fields(idx);

    % remove timestamps
    fields(contains(fields,"Timestamps")) = [];

    outTT = table;
    outTT.Timestamp = inputs.(fields(1)+"Timestamps");
    outTT.(fields(1)) = inputs.(fields(1));
    fields(1) = [];

    for field = fields'
        tempTT = table;
        tempTT.Timestamp = inputs.(field+"Timestamps");
        tempTT.(field) = inputs.(field);

        outTT = outerjoin(outTT,tempTT,"Keys","Timestamp","MergeKeys",true);
    end
    
    % Add code to evaluate if multiple entries for the same measurement was
    % made within 30 mins (use last value entered unles it is matte or slag = 0, then use the first) time of sounding is the
    % first timestamp data was entered at.
    changeInTime = diff(outTT.Timestamp);
    sameSoundingFlag = [0; changeInTime < minutes(30)];
    multipleEntriesIdx = find(sameSoundingFlag);
    outTT = table2timetable(outTT);
        
    for idx = numel(multipleEntriesIdx):-1:1
        timeIdx = multipleEntriesIdx(idx);       
        colIdx = ~isnan(outTT{timeIdx,:});
        outTT(timeIdx-1, colIdx) = outTT(timeIdx, colIdx);

        outTT(timeIdx, :) = [];
    end
    % dt = minutes(30);
    % outTT = retime(outTT,'regular',"mean",'TimeStep',dt);
end
