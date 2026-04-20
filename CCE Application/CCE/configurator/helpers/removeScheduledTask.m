function removeScheduledTask(id)
    %REMOVESCHEDULEDTASK remove a scheduled task associated with the CoordinatorID, ID.
    % Inputs:
    %   ID          -	(uint32) Unique CoordinatorID, ID is used to uniquely name the
    %                   scheduled task. On deletion, ID is used to identify the associated
    %                   Coordinator task.
    
    if ~cce.System.TestMode
        % Find the name of the Task associated with the ID
        [taskFolder, taskName] = cce.getTaskPath(id);
        taskSchedulerService = SchedulerTaskService;
        try
            % Delete the Scheduled Task in the folder with the task name
            SchedulerTask.removeFromScheduler(taskSchedulerService, taskName, folderName=taskFolder);
        catch MExc
            % If this is because the task doesn't exist, exit; we got what we wanted!
            if ~strcmp(MExc.identifier, "SchedulerTaskService:CannotRemoveTask")
                MExc.rethrow();
            end
        end
    end
end