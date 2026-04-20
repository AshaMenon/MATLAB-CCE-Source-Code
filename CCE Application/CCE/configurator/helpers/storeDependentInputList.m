function storeDependentInputList(calculations, directDepedencies)
    %storeDependentInputList formats the list of calculations, and
    %directDependencies cell array into depender and dependee IDs to be written
    %to the CSV file

    arguments
        calculations (1, :) cce.Calculation; %List of call CCE calculations
        directDepedencies (1, :) cell; %Direct dependencies is a cell of {numCalcs, 1}, containing unique
        % cce.Calculation dependee's. 
        % Eg cell 1 would contain any calculations
        %that must run before calculation 1 can run.
    end

    %Check which calcs have dependent calcs that must run first
    hasDependentInputs = cellfun(@(dependees) numel(dependees) >= 1, directDepedencies);

    
    if any(hasDependentInputs)
        %Collect all depender calc IDs - (index n+1)
        dependerCalcIDs = [calculations(hasDependentInputs).CalculationID];
        
        %Collect all dependee calcs (index n)
        dependeeCalcs = directDepedencies(hasDependentInputs);

        %Repeat depender calcs, so that depender and dependee lists are the
        %same size
        dependerCalcIDs = cellfun(@(id, dependeeCalcs) repmat(string(id), 1, numel(dependeeCalcs)), ...
            dependerCalcIDs, dependeeCalcs, 'UniformOutput', false);
        dependerCalcIDs = [dependerCalcIDs{:}]';

        %Convert dependee calcs from cell array to list of IDs
        dependeeCalcs = [dependeeCalcs{:}];
        dependeeCalcsIDs = [dependeeCalcs.CalculationID]';
    else
        dependerCalcIDs = "";
        dependeeCalcsIDs = "";
    end

    writeCalculationDependentInputMap(dependerCalcIDs, dependeeCalcsIDs);
end