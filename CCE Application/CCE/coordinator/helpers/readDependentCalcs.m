function dependeeCalcIDs = readDependentCalcs(calculationID)
    %readDependentCalcs Read the dependee Calculation's that that calculation is dependent on.
    %Produces a list of calculation IDs that must run first -
    %dependeeCalcIDs
    
    %calculationDependentInputs timetable is saved as a pesistent variable,
    %to prevent rereading every time
    persistent dependentCalculationTable readTime

    filePath = fullfile(cce.System.DbFolder, "DependentInputsMap.csv");
    fileInfo = dir(filePath);
    
    %Only read if neccessary - if file has changed, or if not saved in
    %memory
    if isempty(dependentCalculationTable) || (fileInfo.datenum ~= readTime)
    
        readTime = fileInfo.datenum;
        try
            dependentCalculationTable = readtable(filePath, 'Format', '%s%s',...
                'Delimiter', ',', 'HeaderLines', 0, 'ReadVariableNames', true);
        catch
            pause(5/1000)
            dependentCalculationTable = readtable(filePath, 'Format', '%s%s',...
                'Delimiter', ',', 'HeaderLines', 0, 'ReadVariableNames', true);
        end
    end
    
    idxCalcID = ismember(dependentCalculationTable.DependerCalculationID, calculationID);
    dependeeCalcIDs = dependentCalculationTable.DependeeCalculationID(idxCalcID);
end