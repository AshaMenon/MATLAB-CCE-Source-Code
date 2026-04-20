function calcLoad = getCalculationLoad(execFreq)
    persistent coordLoadTbl

    if isempty(coordLoadTbl)
        dataConnector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
        coordLoadTbl = dataConnector.getTable("CoordinatorLoads");
        coordLoadTbl = sortrows(coordLoadTbl,"ExecutionFrequency","ascend");
    end

    if isduration(execFreq)
        execFreq = seconds(execFreq);
    end
    
    idx = execFreq <= coordLoadTbl.ExecutionFrequency;
    idx = find(idx,1,'first');

    if ~isempty(idx)
        calcLoad = coordLoadTbl.CoordinatorLoad(idx);
    else
        calcLoad = cce.System.CoordinatorMaxLoad;
    end
end