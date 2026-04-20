function [relatedCalculations, execFreqs] = findRelatedChains(calculations, fullDependencyList)
    
    for c = 1:numel(calculations)
        fullDependencyList{c} = [fullDependencyList{c}, calculations(c)];
    end
    idxEmpty = cellfun(@(c) isempty(c),  fullDependencyList, 'UniformOutput', false);
    idxEmpty = [idxEmpty{:}];
    fullDependencyList(idxEmpty) = {cce.Calculation.empty};
    
    relatedCalculations = zeros(size(fullDependencyList));
    execFreqs = [];
    coord = 1;
    for k = 1:numel(fullDependencyList)
        idx = cellfun(@(c) any(ismember(c, fullDependencyList{k})),  fullDependencyList, 'UniformOutput', false);
        idx = [idx{:}];
        if any(idx)
            if any(relatedCalculations(idx) ~= 0)
                num = relatedCalculations(idx);
                num = num(num ~= 0);
                relatedCalculations(idx) = num(1);
            else
                relatedCalculations(idx) = coord;
                execFreqs(coord) = seconds(fullDependencyList{k}(1).ExecutionFrequency);
                coord = coord + 1;
            end
        end
    end
end