function [loads] = balanceSimilarCoordinators(similarCoordinators, loads, activeCalculations)
    %BALANCESIMILARCOORDINATORS distributes calculation load between similar coordinators
    
    %TODO: If a calculation is assigned to a coordinator and is busy running - don't
    %change its coordinator?
    numCoords = numel(similarCoordinators);
    coordID = [similarCoordinators.CoordinatorID];
    calcCoorID = [activeCalculations.CoordinatorID];
    totalLoad = sum(loads);
    assignedCalcs = activeCalculations(ismember(calcCoorID, coordID));
    
    idealLoad = floor(totalLoad / numCoords);
    remLoad = mod(totalLoad, numCoords);
    loads = repmat(idealLoad, 1, numCoords);
    loads(1:remLoad) = loads(1:remLoad) + 1;
    
    calcInd = 0;
    for k = 1:numCoords
        thisCoord = similarCoordinators(k);
        thisCoord.CalculationLoad = loads(k);
        
        thisCoordID = coordID(k);
        for calcs = 1:loads(k)
            calcInd = calcInd + 1;
            assignedCalcs(calcInd).CoordinatorID = thisCoordID;
        end
    end
end