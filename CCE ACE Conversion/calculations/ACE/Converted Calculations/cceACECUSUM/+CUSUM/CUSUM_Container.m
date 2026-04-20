classdef CUSUM_Container < handle
    %CUSUM_CONTAINER Summary of this class goes here
    %   Detailed explanation goes here

    methods (Static)

        function writeTime = RetrieveWriteTimes(exetime)
            execTime = string(exetime);
            writeTime = execTime + string(second(exetime)) + "s";
        end

        function properties = RetrieveProperties(parameters)
            properties.XAveLimits(1) = parameters.BaseTagAveMin;
            properties.XAveLimits(2) = parameters.BaseTagAveMax;
            properties.XAveTime = parameters.CUSUMBaseAveTimeSec;
            properties.CUSUMLim = parameters.CUSUMLimit;
            properties.AvePctGood = parameters.TagAvePercentGood;
        end

        function output = PopulateCUSUMInformation(inputs,exeTime,parameters)
            PIAliases = fieldnames(inputs);
            for i = 1:(length(PIAliases))/4
                name = "Alias"+i;
                inputPoint = inputs.(name);
                outputPoint = inputs.(name+"_CUSUM");

                priorOutput = GetLastGood(outputPoint,inputs.(name+"_CUSUM"+"Timestamps"),exeTime);
               
                priorInput = (inputPoint + parameters.TagAvePercentGood)./ 2;

                average = parameters.("Average_"+name);

                output.(name+"_InputPoint") = inputPoint;
                output.(name+"_OutputPoint") = outputPoint;
                output.(name+"_CurrentSample")= priorInput;
                output.(name+"_PreviousOutput") = priorOutput;
                output.(name+"_Average") = average;
                
            end
        end

        function output = UpdateCUSUMValue(popInfo,properties,input)
            PIAliases = fieldnames(input);
            for i = 1:(length(PIAliases))/4
                name = "Alias"+i;
                newValue = popInfo.(name+"_PreviousOutput")(end) + popInfo.(name+"_CurrentSample")(end) - popInfo.(name+"_Average")(end);

                if newValue > properties.CUSUMLim || newValue < -properties.CUSUMLim
                    popInfo.(name+"_Average") = (popInfo.(name+"_InputPoint") + properties.AvePctGood) ./ 2;
                    newValue = popInfo.(name+"_CurrentSample") - popInfo.(name+"_Average");
                end
                output.(name+"_OutputPoint") = newValue(end); 
            end
        end

    end
end
function output = GetLastGood(input,timestamp,exetime)

try
    if numel(timestamp) > 1
        i = 1;
        if timestamp(i) == exetime
            i = 2;
        end
        output = input(i:end);
    else
        output = input;
    end
catch
    output = input;
end
end

