function writeCalculationDependentInputMap(dependerCalcID, dependeeCalcID)
    %WRITECALCULATIONDEPENDENTINPUTMAP takes in string lists of calculation
    %IDS, writes these into DependentInputsMap.csv file. 

    arguments
        dependerCalcID (:, 1) string %List of dependent calculations (i.e index n + 1)
        dependeeCalcID (:, 1) string %List of calculations that are dependended on (i.e. index n)
    end
    
    if ~exist(cce.System.DbFolder, 'dir')
        mkdir(cce.System.DbFolder)
    end
    filePath = fullfile(cce.System.DbFolder, "DependentInputsMap.csv");
    
    dependentInputsMap = table(dependerCalcID, dependeeCalcID, ...
        'VariableNames', {'DependerCalculationID', 'DependeeCalculationID'});
    writetable(dependentInputsMap, filePath, 'WriteVariableNames', true);
end