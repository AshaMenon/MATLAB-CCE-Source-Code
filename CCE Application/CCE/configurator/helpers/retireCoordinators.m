function retireCoordinators(coordinatorIDs)
    %RETIRECOORDINATORS remove scheduled task associated with the coordinator id
    % Inputs:
    %   COORDINATORIDS	-	(uint32) List of unique COORDINATORIDS with associated
    %                        Coordinator tasks to remove, the CoordinatorID is used to
    %                        uniquely name the scheduled task. On deletion, the
    %                        CoordinatorID is used to identify the associated Coordinator
    %                        task.
    
    if ~cce.System.TestMode
        for c = 1:numel(coordinatorIDs)
            % Remove scheduled task for the Coordinator with CoordinatorID
            id = coordinatorIDs(c);
            removeScheduledTask(id);
        end
    end
end