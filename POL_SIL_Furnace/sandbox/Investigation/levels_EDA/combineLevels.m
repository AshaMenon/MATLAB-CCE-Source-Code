function dataTbl = combineLevels(dataTbl)
    %UNTITLED Summary of this function goes here
    %   Detailed explanation goes here
    
    variableNames = dataTbl.Properties.VariableNames;

    % Slag
    slagColumns = contains(variableNames, 'SlagLevels');
    slagData = dataTbl{:, slagColumns};
    dataTbl.SlagCombinedLevel = calculateLevelAverage(slagData, slagColumns);

    % Matte
    matteColumns = contains(variableNames, 'MatteLevels');
    % dataTbl.combinedMatteLevel = max(dataTbl{:, matteColumns}, [], 2);

    % Extract only the 'level' columns
    matteData = dataTbl{:, matteColumns};
    maxMatteValues = calculateLevelMax(matteData, matteColumns);
    dataTbl.MatteCombinedLevel = maxMatteValues;

    % Bonedry Levels
    bonedryColumns = contains(variableNames, 'ConcentrateLevels');
    bonedryData = dataTbl{:, bonedryColumns};
    maxBonedryValues = calculateLevelAverage(bonedryData, bonedryColumns);
    dataTbl.BonedryCombinedLevel = maxBonedryValues;

    % Bath Levels
    bathColumns = contains(variableNames, 'BathLevels');
    bathData = dataTbl{:, bathColumns};
    maxBathValues = calculateLevelAverage(bathData, bathColumns);
    dataTbl.BathCombinedLevel = maxBathValues;

end