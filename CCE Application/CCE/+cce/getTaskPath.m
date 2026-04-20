function [taskFolder, taskName] = getTaskPath(id)
    %GETTASKPATH 
    
    taskFolder = cce.System.SchedulerFolderName;
    taskName = "CCE Coordinator #" + string(id);
end