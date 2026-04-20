%% 1. Create a new task
%% Add .NET assembly
% Add the assembly (Microsoft.Win32.TaskScheduler.dll) to the GAC (the 
% version used is 2.9.1 - but always use the latest version)
tsAssembly = NET.addAssembly('Microsoft.Win32.TaskScheduler');
%% Create a task schedule service
newTaskService = Microsoft.Win32.TaskScheduler.TaskService;
%% Create a new task
newTask = newTaskService.NewTask;
%% Add registration info
newTask.RegistrationInfo.Author = "NicoleR";
newTask.RegistrationInfo.Description = "Fixed Triggers and Actions";
%% Add a weekly trigger
weeklyTrigger = Microsoft.Win32.TaskScheduler.WeeklyTrigger;
% Set to run everyday
weeklyTrigger.DaysOfWeek = Microsoft.Win32.TaskScheduler.DaysOfTheWeek.AllDays;
NET.invokeGenericMethod(newTask.Triggers,'Add',{'Microsoft.Win32.TaskScheduler.Trigger'},weeklyTrigger);
%% Add a custom trigger
eventTrigger = Microsoft.Win32.TaskScheduler.EventTrigger;
eventTrigger.Subscription = "<QueryList><Query Id=""0"" Path=""Microsoft-Windows-TaskScheduler/Operational""><Select Path=""Microsoft-Windows-TaskScheduler/Operational"">*[System[(EventID=102)] and EventData[Data[@Name='TaskName']='\MyTasks\Test2']]</Select></Query></QueryList>";
eventTrigger.ValueQueries.Add("Name", "Value");
NET.invokeGenericMethod(newTask.Triggers,'Add',{'Microsoft.Win32.TaskScheduler.Trigger'},eventTrigger);
%% Add action
action = Microsoft.Win32.TaskScheduler.ExecAction("C:\Program Files\Internet Explorer\iexplore.exe");
%% Add argument
NET.invokeGenericMethod(newTask.Actions,'Add',{'Microsoft.Win32.TaskScheduler.Action'},action);
%% Register task
newTaskService.RootFolder.RegisterTaskDefinition("MyTasks\Test2", newTask);
%% 2. Delete a scheduled task
newTaskService.RootFolder.DeleteTask("MyTasks\Test2");
%% 3. List all tasks in a folder
taskFolder = newTaskService.GetFolder("MyTasks");
if ~isempty(taskFolder)
    tasksInFolder = taskFolder.GetTasks;
    for ii = 0:double(tasksInFolder.Count)-1
        taskList(ii+1) = string(tasksInFolder.Item(ii).Name);
    end
    taskList = taskList';
end
%% 4. Retrieve a specific task
specificTask = newTaskService.GetTask("MyTasks\MyNewTaskFromMATLAB");