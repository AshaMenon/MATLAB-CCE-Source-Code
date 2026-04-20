function sensor = inputTranslation(values, sensorQuality,timestamps)
    %UNTITLED9 Summary of this function goes here
    %   Detailed explanation goes here
    sensor(1).Value = values;
    sensor(1).Quality = sensorQuality;
    sensor(1).TimeStamp = timestamps;
    sensor(1).Length = length(values);
    sensor(1).TimeStep = seconds(diff(timestamps(1:2)));
    sensor(1).IsEmpty = isempty(values);
end

