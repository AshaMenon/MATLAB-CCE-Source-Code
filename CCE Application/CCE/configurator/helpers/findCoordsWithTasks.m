function [hasScheduledTask] = findCoordsWithTasks(coordinators)
    %FINDCOORDSWITHTASKS finds the index of the COORDINATORS that have an existing
    %scheduled task.
    % Inputs:
    %   COORDINATORS	-	(cce.Coordinator) cce.Coordinator array of CCE Coordinators to
    %                       be checked for existing corresponding scheduled tasks.
    
    %Get all the coordinator tasks
    allCoordinatorTasks = findAllCoordinatorTasks();
    %Get the CoordinatorIDs
    ids = [coordinators.CoordinatorID];
    if ~isempty(allCoordinatorTasks)
        %If the CoordinatorID is used as an input argument in one of the Scheduled Tasks,
        %then the Coordinator has an associated 
        inArg = [allCoordinatorTasks.CommandArgument];
        idString = string(ids);
        [hasScheduledTask] = ismember(idString, inArg);
    else
        hasScheduledTask = false(size(coordinators));
    end
end