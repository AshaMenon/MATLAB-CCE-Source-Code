function directDependencies = findDirectDependencies(calculations)
    %FINDDIRECTDEPENDENCIES finds a list of direct dependencies for each cce.Calculation
    %in CALCULATIONS.

    %Direct dependencies is a cell of {numCalcs, 1}, containing unique
    %cce.Calculation dependee's. 
    % 
    % Eg cell 1 would contain any calculations
    %that must run before calculation 1 can run. 
    
    arguments
        calculations cce.Calculation
    end
    idxEvent = ismember([calculations.ExecutionMode], cce.CalculationExecutionMode.Event);
    indPeriodic = find(~idxEvent);
    
    % Resolve each cce.Calculation Input and Output references to their PIPoint Path
    inputPIPointPath = cell(size(calculations));
    outputPIPointPath = cell(size(calculations));
    for c = 1:numel(calculations)
        try
            inputPIPointPath{c} = calculations(c).retrieveInputPIPointPaths;
            outputPIPointPath{c} = calculations(c).retrieveOutputPIPointPaths;
        catch
            % This calculation has inputs/outputs that are not configurable; set the inputs and
            % outputs to empty.
            inputPIPointPath{c} = string.empty;
            outputPIPointPath{c} = string.empty;
        end
    end
    
    % For each cce.Calculation determine if any of its Input PIPoint Paths are found in
    % any of the Calculations' Output PIPoint Paths. If so, this means that the
    % cce.Calculation is dependent on that Calculation's Output(s). Add the dependent
    % Calculation to the directDependencies for this cce.Calculation.
    directDependencies = cell(1, numel(calculations));
  
    for c = 1:numel(indPeriodic)
        for k = 1:numel(indPeriodic)
            [isDepend] = ismember(inputPIPointPath{indPeriodic(c)}, outputPIPointPath{indPeriodic(k)}) & ~ismember(inputPIPointPath{indPeriodic(c)}, "");
            if any(isDepend)
                directDependencies{indPeriodic(c)} = unique([directDependencies{indPeriodic(c)}, calculations(indPeriodic(k))]);
            end
        end
    end
end