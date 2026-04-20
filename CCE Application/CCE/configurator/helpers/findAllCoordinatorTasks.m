function allCoordinatorTasks = findAllCoordinatorTasks()
    %FINDALLCOORDINATORTASKS returns all the SCHEDULERTASK objects for the MS Windows
    %Scheduled Tasks in the "CCETasks" folder.
    
    [taskFolder] = cce.getTaskPath([]);
    allCoordinatorTasks = SchedulerTask.fetchFromScheduler(SchedulerTaskService, folderName=taskFolder);
end