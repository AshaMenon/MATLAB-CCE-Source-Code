function [derivedSensorClass,derivedSensorEU,derivedSensorSG,numInputs,id,value,quality,timeStamp,active,condition,eu,sg,constants,leadingConstants,ignoreInd] = parseInputs(funcInputs,modifyData,convertEUtoDerived)

%PARSEINPUTS Parse derived calc inputs
%   [derivedSensorClass,derivedSensorEU,derivedSensorSG,numInputs,id,value,quality,timeStamp,...
%     active,condition,eu,sg,constants,leadingConstants,ignoreInd] = parseInputs(funcInputs,modifyData,convertEUtoDerived); parse derived calc inputs
%
%   Expected inputs: funcInputs (derivedSensorClass, derivedSensorEU, derivedSensorSG, class, id, value, quality, timeStamp, active, condition, eu
%                  : modifyData (true false)
%                  : convertEUtoDerived ('output' 'generic' 'sg' '')
%
%   Outputs: 

% save('c:\opmWork\tmp.mat','funcInputs','modifyData','convertEUtoDerived');


derivedSensorClass = funcInputs{1}; % Read output sensor class from inputs
funcInputs(1) = [];
derivedSensorEU = funcInputs{1}; % Read output sensor engineering units from inputs
funcInputs(1) = [];
derivedSensorSG = funcInputs{1}; % Read output sensor SG from inputs
funcInputs(1) = [];
numInputs = 8;  % Define number of inputs to read
% Identify Constants
constants = [];
if max(strcmpi('Constants',funcInputs)) > 0
    constantInd = find(strcmpi('Constants',funcInputs)==1)+1;
    constants = cell2mat(funcInputs(constantInd));
    funcInputs([constantInd constantInd-1]) = [];
end
% Identify LeadingConstants
leadingConstants = [];
if max(strcmpi('LeadingConstant',funcInputs)) > 0
    constantInd = find(strcmpi('LeadingConstant',funcInputs)==1)+1;
    leadingConstants = cell2mat(funcInputs(constantInd));
    funcInputs([constantInd constantInd-1]) = [];
end
% Parse individual inputs
ignoreInd = logical([]);
maxDataSize = 0;
for i = 1:size(funcInputs,2)
    if isnumeric(funcInputs{i})
        maxDataSize = nanmax([maxDataSize nanmax(size(funcInputs{i}))]);
    end
end
% Need to pre-assigned matrices for when no dependable sensors other than self exist
value = nan(maxDataSize,size(funcInputs,2)/numInputs);
quality = nan(maxDataSize,size(funcInputs,2)/numInputs);
active = nan(maxDataSize,size(funcInputs,2)/numInputs);
condition = nan(maxDataSize,size(funcInputs,2)/numInputs);
% goodQualityVal = ap.DataQuality.opmqualityval('good'); % Identify the missing values
% notRunningQualityVal = ap.DataQuality.opmqualityval('not running'); % Identify the not running values
% mappedGoodQualityVal = ap.DataQuality.opmqualityval('mapped good'); % Identify the not running values
goodQualityVal = 0;
mappedGoodQualityVal = 65534;
notRunningQualityVal = 3;
for i = 1:size(funcInputs,2)/numInputs
    % Read inputs
    id{i} = funcInputs{i*numInputs-(numInputs-1)}; % Read input sensor ID
    % Handle for when P0 is present
    if ~strcmpi(id{i},'P0')
        % Read input sensor Value
        try value(:,i) = funcInputs{i*numInputs-(numInputs-2)}; catch, end
        try
            quality(:,i) = funcInputs{i*numInputs-(numInputs-3)}; % Read input sensor Quality
        catch
            quality(:,i) = zeros(size(value(:,i))); % Handle for when referencing own sensor|parameter
        end
    else
        value(:,i) = zeros(size(value(:,i-1)));
        quality(:,i) = goodQualityVal*ones(size(quality(:,i-1)));
    end
    timeStamp(:,i) = funcInputs{i*numInputs-(numInputs-4)}; % Read input sensor timeStamp
    % Read input sensor Active
    try active(:,i) = funcInputs{i*numInputs-(numInputs-5)}; catch, end
    % Read input sensor Condition
    try condition(:,i) = funcInputs{i*numInputs-(numInputs-6)}; catch, end
    eu{i} = funcInputs{i*numInputs-(numInputs-7)}; % Read input sensor engineering units
    sg{i} = funcInputs{i*numInputs-(numInputs-8)}; % Read input sensor SG
    % Assign run signal quality to active
    active(quality(:,i)==notRunningQualityVal,i) = 0;  % Assign sensor active as 0 wherever sensor quality = notRunning
    % Prep data & qualities
    warning off
    quality(quality(:,i)==goodQualityVal,i) = mappedGoodQualityVal; % Map good quality for sorting
    if modifyData
        ignoreInd(:,i) = active(:,i)~=1 | condition(:,i)~=1; % Identify notRunning qualities
        value(ignoreInd(:,i),i) = NaN; % Mark notRunning values as NaN
        quality(ignoreInd(:,i),i) = NaN; % Mark notRunning qualities as NaN
    end
    warning on
    % Convert Engineering units where required
    if strcmpi(convertEUtoDerived,'output')
        % Convert value based on expected EU
        value(:,i) = convertEU(derivedSensorEU,value(:,i),eu{i},sg{i}); % Convert input sensor to required engineering units
    elseif strcmpi(convertEUtoDerived,'generic')
        % Convert value of input sensor to required engineering units
        if strcmpi(id{i},'DrySolidsFeed'), value(:,i) = convertEU('ton/hr',value(:,i),eu{i},sg{i}); 
        elseif strcmpi(id{i},'InletWaterFlow'), value(:,i) = convertEU('m^3/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'MillDischSumpFlowIn') ,value(:,i) = convertEU('ton/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'MillDischSumpFlowOut'), value(:,i) = convertEU('ton/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'MillCircLoad'), value(:,i) = convertEU('ton/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'CoarseFeed'), value(:,i) = convertEU('ton/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'TotalSolidsFeed'), value(:,i) = convertEU('ton/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'MillDischSumpSolidsFlowOut'), value(:,i) = convertEU('ton/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'MillDischSumpWaterFlowOut'), value(:,i) = convertEU('ton/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'MillDischSumpSolidsFlowIn'), value(:,i) = convertEU('ton/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'MillDischSumpWaterFlowIn'), value(:,i) = convertEU('ton/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'MillDischSumpMakeUpWater'), value(:,i) = convertEU('m^3/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'GenericSumpSolidsFlowOut'), value(:,i) = convertEU('ton/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'GenericSumpWaterFlowOut'), value(:,i) = convertEU('ton/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'GenericSumpSolidsFlowIn'), value(:,i) = convertEU('ton/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'GenericSumpWaterIn'), value(:,i) = convertEU('ton/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'GenericDischSumpMakeUpWater'), value(:,i) = convertEU('m^3/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'TotalConcMassFlow'), value(:,i) = convertEU('m3/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'CellConcMassFlow'), value(:,i) = convertEU('m3/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'Power'), value(:,i) = convertEU('kW',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'Load'), [value(:,i),convertedA] = convertEU('ton',value(:,i),eu{i},sg{i}); if convertedA == 0, value(:,i) = convertEU('kPa',value(:,i),eu{i},sg{i}); end
        elseif strcmpi(id{i},'Flow'), value(:,i) = convertEU('m^3/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'Density'), value(:,i) = convertEU('sg',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'Level'), value(:,i) = convertEU('%',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'Air'), value(:,i) = convertEU('m^3/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'Frt'), % Do nothing
        elseif strcmpi(id{i},'ThisFrt'), % Do nothing
        elseif strcmpi(id{i},'ConcSumpFlow'), value(:,i) = convertEU('m3/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'Mp'), % Do nothing
        elseif strcmpi(id{i},'ThisMp'), % Do nothing
        elseif strcmpi(id{i},'ConcSumpFlowSp'), value(:,i) = convertEU('m3/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'Input'), value(:,i) = convertEU('m^3/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'Output'), value(:,i) = convertEU('m^3/hr',value(:,i),eu{i},sg{i});
        elseif strcmpi(id{i},'OtherDenominators'), % Do nothing
        elseif strcmpi(id{i},'Nominator'), % Do nothing
        end
    elseif strcmpi(convertEUtoDerived,'sg')
        value(:,i) = convertEU('sg',value(:,i),eu{i},sg{i});
    elseif strcmpi(convertEUtoDerived,'')
        value(:,i) = convertEU('',value(:,i),eu{i},sg{i});
    end
end