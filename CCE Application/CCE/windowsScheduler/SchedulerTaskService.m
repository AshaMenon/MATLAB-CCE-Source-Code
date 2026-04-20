classdef SchedulerTaskService < handle
    %SchedulerTaskService Class This is a SchedulerTaskService class
    %   The SchedulerTaskService class provides an interface to the Windows
    %   Task Scheduler by using the .NET assembly
    %   Microsoft.Win32.TaskScheduler.dll to communicate.
    %
    %   The SchedulerTaskService class will contain two properties,
    %   TaskService that will be created when an object is instantiated and
    %   the default folder that will be used if no folder is specified.
    
    properties
        TaskService (1,1)
        DefaultFolder (1,1) string
    end
    
    methods
        function obj = SchedulerTaskService()
            %SchedulerTaskService Construct an instance of the class
            %   The constructor will create a TaskService by loading the
            %   .NET library and then creating the service. It will set a
            %   default folder that will be used if no folder is provided
            %   by the user when interacting with the task scheduler
            rootPath = fileparts(mfilename("fullpath"));
            assemblyPath = fullfile(rootPath, "private", "Microsoft.Win32.TaskScheduler.dll");
            NET.addAssembly(assemblyPath);
            obj.TaskService = Microsoft.Win32.TaskScheduler.TaskService;
            obj.DefaultFolder = "CCETasks";
        end
        
        function task = createTask(obj, name, author, description,...
                startTime, repeatInterval, stopOverrun, commandToRun,...
                commandArgument, restartTask, folderName, username, password)
            arguments
                obj
                name (1,1) string
                author (1,1) string
                description (1,1) string
                startTime (1,1) datetime
                repeatInterval (1,1) double
                stopOverrun (1,1) double
                commandToRun (1,1) string
                commandArgument (1,1) string
                restartTask (1,1) logical
                folderName (1,1) string = ""
                username (1,1) string = ""
                password (1,1) string = ""
            end
            
            if folderName == ""
                folderName = obj.DefaultFolder;
            end
            % Create a task
            % DR: Try to use the current user instance
            newTask = obj.TaskService.Instance.NewTask;
            % Add registration info
            newTask.RegistrationInfo.Author = author;
            newTask.RegistrationInfo.Description = description;
            % Add principal info
            if username == ""
                username = "SYSTEM";
            end
            % Add triggers - frequency and restart
            newTask.Settings.ExecutionTimeLimit = System.TimeSpan(0, 0, repeatInterval+stopOverrun);
            oneTimeTrigger = Microsoft.Win32.TaskScheduler.TimeTrigger;
            oneTimeTrigger.StartBoundary = System.DateTime(startTime.Year,...
                startTime.Month, startTime.Day, startTime.Hour,...
                startTime.Minute, startTime.Second);
            oneTimeTrigger.Repetition.Interval = System.TimeSpan(0, 0, repeatInterval);
            oneTimeTrigger.Repetition.Duration = System.TimeSpan.Zero;
            oneTimeTrigger.ExecutionTimeLimit = System.TimeSpan(0, 0, repeatInterval+stopOverrun);
            NET.invokeGenericMethod(newTask.Triggers, 'Add', {'Microsoft.Win32.TaskScheduler.Trigger'}, oneTimeTrigger);
            
            if restartTask
                eventTrigger = Microsoft.Win32.TaskScheduler.EventTrigger;
                eventTrigger.Subscription = sprintf("<QueryList><Query Id=""0"" Path=""Microsoft-Windows-TaskScheduler/Operational""><Select Path=""Microsoft-Windows-TaskScheduler/Operational"">*[System[(EventID=102)] and EventData[Data[@Name='TaskName']='\\%s\\%s']]</Select></Query></QueryList>",folderName,name);
                eventTrigger.ValueQueries.Add("Name", "Value");
                NET.invokeGenericMethod(newTask.Triggers,'Add',{'Microsoft.Win32.TaskScheduler.Trigger'},eventTrigger);
            end
            % Add action and argument
            action = Microsoft.Win32.TaskScheduler.ExecAction(commandToRun);
            if ~(commandArgument == "")
                action.Arguments = commandArgument;
            end
            NET.invokeGenericMethod(newTask.Actions,'Add',{'Microsoft.Win32.TaskScheduler.Action'},action);
            % Register task (add to Windows Task Scheduler)
            taskName = fullfile(folderName, name);
            taskAction = Microsoft.Win32.TaskScheduler.TaskCreation.CreateOrUpdate;
            try
                if isempty(username)
                    logonType = [];
                elseif (username == "SYSTEM")
                    logonType = Microsoft.Win32.TaskScheduler.TaskLogonType.ServiceAccount;
                    password = []; % Ensure that we don't provide any password
                else
                    logonType = Microsoft.Win32.TaskScheduler.TaskLogonType.Password;
                end
                obj.TaskService.Instance.RootFolder.RegisterTaskDefinition(taskName, newTask, taskAction, username, password, logonType);
                task = obj.readTask(name, folderName);
            catch ME
                warning('SchedulerTaskService:CannotCreateTask','Cannot create task: %s', ME.message);
                task = [];
            end
        end
        
        function tf = taskExists(obj, taskName, folderName)
            %taskExists Check if a task exists in the Windows Task Scheduler
            %   This method will check if a task exists in the Windows Task Scheduler
            %   A taskName and folderName will need to be provided.
            %   If the task is found it will return a task object, if it is
            %   not found, it will return an empty value. The output will
            %   return true if the task was found or false if it was not
            %   found.
            arguments
                obj
                taskName (1,1) string {mustBeNonempty}
                folderName (1,1) string {mustBeNonempty}
            end
            
            tf = false;
            
            returnedTask = obj.TaskService.GetTask(fullfile(folderName, taskName));
            
            if ~isempty(returnedTask)
                tf = true;
            end
            
        end
        
        function tf = taskFolderExists(obj, folderName)
            %taskFolderExists Check if a folder exists in Windows Task Scheduler
            %   This method will check if a folder exists in the Windows Task Scheduler
            %   A folderName will need to be provided.
            %   If the folder is found it will return a TaskFolder object, if it is
            %   not found, it will return an empty value. The output will
            %   return true if the task folder was found or false if it was not
            %   found.
            arguments
                obj
                folderName (1,1) {mustBeNonempty}
            end
            
            tf = false;
            
            taskFolder = obj.TaskService.GetFolder(folderName);
            
            if ~isempty(taskFolder)
                tf = true;
            end
        end
        
        function updateTask(obj, taskName, folderName, taskProperty, value)
            %updateTask The properties of a task will be updated
            %   This method will update a task if the task properties have
            %   changed. 
            
            task = readTask(obj, taskName, folderName);
            
            switch(taskProperty)
                case "Author"
                    task.Definition.RegistrationInfo.Author = value;
                case "Description"
                    task.Definition.RegistrationInfo.Description = value;
                case "StartTime"
                    task.Definition.Triggers.Item(0).StartBoundary = System.DateTime(value.Year,...
                        value.Month, value.Day, value.Hour, value.Minute, value.Second);
                case "RepeatInterval"
                    task.Definition.Triggers.Item(0).Repetition.Interval = System.TimeSpan(0,0,value);
                case "StopOverrun"
                    repeatInterval = double(task.Definition.Triggers.Item(0).Repetition.Interval.TotalSeconds);
                    task.Definition.Triggers.Item(0).ExecutionTimeLimit = ...
                        System.TimeSpan(0,0,repeatInterval + value);
                    task.Definition.Settings.ExecutionTimeLimit = ...
                        System.TimeSpan(0,0,repeatInterval + value);
                case "RestartTask"
                    if value == true
                        if task.Definition.Triggers.Count == 1
                            eventTrigger = Microsoft.Win32.TaskScheduler.EventTrigger;
                            eventTrigger.Subscription = sprintf("<QueryList><Query Id=""0"" Path=""Microsoft-Windows-TaskScheduler/Operational""><Select Path=""Microsoft-Windows-TaskScheduler/Operational"">*[System[(EventID=102)] and EventData[Data[@Name='TaskName']='\\%s\\%s']]</Select></Query></QueryList>",folderName,taskName);
                            eventTrigger.ValueQueries.Add("Name", "Value");
                            NET.invokeGenericMethod(task.Definition.Triggers,'Add',{'Microsoft.Win32.TaskScheduler.Trigger'},eventTrigger);
                        end
                    else
                        if task.Definition.Triggers.Count == 2
                            task.Definition.Triggers.RemoveAt(1);
                        end
                    end
                case "CommandToRun"
                    task.Definition.Actions.Item(0).Path = value;
                case "CommandArgument"
                    task.Definition.Actions.Item(0).Arguments = value;
            end
            
            try
                obj.TaskService.RootFolder.RegisterTaskDefinition(fullfile(folderName, taskName), task.Definition);
            catch ME
                error('SchedulerTaskService:CannotUpdateTask', 'Cannot update task due to error: %s',ME.message);
            end
        end
        
        function task = readTask(obj, taskName, folderName)
            %readTask The task properties will be returned
            %   This method will return the details of a task, if the task
            %   does not exist an empty task will be returned.
            arguments
                obj
                taskName (1,1) string {mustBeNonempty}
                folderName (1,1) string
            end
            
            if folderName == ""
                folderName = "CCETasks";
            end
            
            tf = taskExists(obj, taskName, folderName);
            
            if tf
                task = obj.TaskService.GetTask(fullfile(folderName, taskName));
            else
                task = [];
            end
        end
        
        function taskList = findTasks(obj, folderName)
            %findTasks A list of tasks in a folder will be returned
            %   This method will find all tasks contained in a particular
            %   folder. The task list will be returned, if no tasks are
            %   found, an empty task list is returned.
            arguments
                obj
                folderName (1,1) string
            end
            
            if folderName == ""
                folderName = obj.DefaultFolder;
            end
            
            tf = taskFolderExists(obj, folderName);
            
            if tf
                taskFolder = obj.TaskService.GetFolder(folderName);
                if ~isempty(taskFolder)
                    returnedTaskCollection = taskFolder.GetTasks;
                    if double(returnedTaskCollection.Count) > 0
                        taskList = returnedTaskCollection;
                    else
                        taskList = [];
                    end
                else
                    taskList = [];
                end
            else
                taskList = [];
            end  
        end
        
        function removeTask(obj, taskName, folderName)
            %removeTask A task is deleted from the folder specified
            %   This method will delete a task from the task folder
            %   specified.
            arguments
                obj
                taskName (1,1) string {mustBeNonempty}
                folderName (1,1) string
            end
            
            if folderName == ""
                folderName = obj.DefaultFolder;
            end
            
            tf = taskExists(obj, taskName, folderName);
            if tf
                obj.TaskService.RootFolder.DeleteTask(fullfile(folderName, taskName));
            else
                error('SchedulerTaskService:CannotRemoveTask', 'Cannot remove task %s from folder %s: task does not exist', taskName, folderName);
            end
        end
        
        function runTask(obj, taskName, folderName)
            arguments
                obj
                taskName (1,1) string {mustBeNonempty}
                folderName (1,1) string
            end
            
            if folderName == ""
                folderName = obj.DefaultFolder;
            end
            
            tf = taskExists(obj, taskName, folderName);
            if tf
                task = obj.readTask(taskName, folderName);
                if task.Enabled
                    task.Run({});
                else
                    error('SchedulerTaskService:CannotRunTask', 'Cannot run task %s from folder %s: task is disabled', taskName, folderName);
                end
            else
                error('SchedulerTaskService:CannotRunTask', 'Cannot run task %s from folder %s: task does not exist', taskName, folderName);
            end
            
        end
        
    end
end

