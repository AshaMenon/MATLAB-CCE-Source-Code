classdef WindowsScheduler < handle
    %WindowsScheduler  Windows Scheduler accessor class
    %   The WindowsScheduler class provides functions to discover, create and delete Scheduled Tasks in
    %   Windows Scheduler.
    %
    %   CAUTION: The createTask method requires a password to be passed either as a plain text string,
    %   or an encrypted string using a password decrypter function. For security reasons, you should
    %   p-code this class when using it.
    %
    %   Properties: WindowsScheduler has no publically accessible properties.
    %
    %   Methods:
    %   + createTask: Create a Windows Scheduled Task
    %   + getTaskByName: Retrieve the properties of a Scheduled Task
    %   + deleteTask: Delete a Scheduled Task from the Scheduler
    %   + getTasksByFolder: Get all tasks in a specified folder
    %   + enableTask: Enable an existing Scheduled Task
    %   + disableTask: Disable an existing Scheduled Task
        
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    % developed as background IP for Anglo American Platinum
        
    properties (Access = private)
        NetService (1,1) 
    end
    
    methods % Constructor/Destructor
        function obj = WindowsScheduler()
            %WindowsScheduler  Construct an interface to Windows Scheduler
            %   schedObj = WindowsScheduler creates an interface to Windows Scheduler.
            if ~exist("Microsoft.Win32.TaskScheduler.TaskService", "Class")
                rootPath = fileparts(mfilename("fullpath"));
                assemblyPath = fullfile(rootPath, "private", "Microsoft.Win32.TaskScheduler.dll");
                NET.addAssembly(assemblyPath);
            end
            obj.NetService = Microsoft.Win32.TaskScheduler.TaskService;
        end
    end
    
    methods % Creation, deletion, existence of tasks
        function taskObj = createTask(obj, taskName, commandToRun, commandArguments, startTime, repeatInterval, nvArgs)
            % createTask  Create a Windows Scheduled Task
            %   taskObj = schedulerObj.createTask(taskName, commandToRun, commandArguments, startTime, frequencyDefinition, nameValuePairs)
            %       creates a Scheduled Task with the following properties:
            %           taskName: The name of the task (a string)
            %           commandToRun: The task to execute. (The Programme/script in “Start a program” action)
            %           commandArguments: The arguments passed to the commandToRun. (The “Add Arguments” in
            %               “Start a program” action)
            %           startTime: A datetime specifying when the task should first run. 
            %           repeatInterval: A duration specifying how often the task must be repeated. Note that
            %               complex frequency definitions are not supported (such as “Every weekday”)
            %       Other arguments must be passed as name/value pairs. Defaults are used if not passed:
            %           folderName: [""] Name of folder to create scheduled task in. Folder need not exist. If
            %               not passed, no folder name is used; the task is created in the root folder.
            %           userCredentials: [username, password] Username and (possibly encrypted) password for the user to run as.
            %               username can be empty (logged in user, runs the task only if logged in) or "SYSTEM" for
            %               the LocalSystem account (password is ignored). password can be encrypted, but you must
            %               specify a decrypter function in the passwordDecrypter argument.
            %           autoRestart: [true/FALSE] Define whether the task must restart after the process exits.
            %           stopAfter: [stopDuration] Stop task if it runs for longer than stopDuration. Not set if this
            %               parameter is not passed.
            %           author: [“MATLAB”] Name of author field.
            %           description: [taskName] Description of the task.
            %           passwordDecrypter: [none] A function handle that accepts a string as input and passes out a
            %               decrypted version of the string. Use this and an encrypted string to secure passwords.
            %               Note that you can only secure the password reasonably (but not against MATLAB users) if
            %               this class file and the decrypter function are p-coded or compiled. For an example decrypter
            %               function, see AESEncrypter.
            %
            %   See also: deleteTask, runTask.
            arguments
                obj (1,1) WindowsScheduler
                taskName (1,1) string {mustBeNonzeroLengthText}
                commandToRun (1,1) string {mustBeNonzeroLengthText}
                commandArguments (1,1) string
                startTime (1,1) datetime = datetime('now')
                repeatInterval duration {mustBeScalarOrEmpty} = duration.empty
                nvArgs.userCredentials (1,2) string = ["",""]
                nvArgs.folderName (1,1) string = ""
                nvArgs.autoRestart (1,1) logical = false
                nvArgs.stopAfter duration {mustBeScalarOrEmpty} = duration.empty
                nvArgs.author (1,1) string = "MATLAB"
                nvArgs.description (1,1) string = taskName
                nvArgs.passwordDecrypter function_handle = @(x)x
            end
            
            % Create a full name
            fullTaskName = getFullTaskName(nvArgs.folderName, taskName);
            % Decode the username and password
            username = nvArgs.userCredentials(1);
            password = nvArgs.userCredentials(2);
            
            % Create a task - Might need a special credential TaskService
            taskInstance = obj.NetService.Instance;
            newTask = taskInstance.NewTask;
            % Add registration info
            newTask.RegistrationInfo.Author = nvArgs.author;
            if strlength(nvArgs.description) > 0
                newTask.RegistrationInfo.Description = nvArgs.description;
            end
            % Add stop after only if it's specified
            if ~isempty(nvArgs.stopAfter)
                newTask.Settings.ExecutionTimeLimit = System.TimeSpan(0, 0, seconds(nvArgs.stopAfter));
            end
            % Add runFrequency trigger
            oneTimeTrigger = Microsoft.Win32.TaskScheduler.TimeTrigger;
            oneTimeTrigger.StartBoundary = System.DateTime(startTime.Year,...
                startTime.Month, startTime.Day, startTime.Hour,...
                startTime.Minute, startTime.Second);
            if ~isempty(repeatInterval)
                oneTimeTrigger.Repetition.Interval = System.TimeSpan(0, 0, seconds(repeatInterval));
            end
            oneTimeTrigger.Repetition.Duration = System.TimeSpan.Zero;
            if ~isempty(nvArgs.stopAfter)
                oneTimeTrigger.ExecutionTimeLimit = System.TimeSpan(0, 0, seconds(nvArgs.stopAfter));
            end
            NET.invokeGenericMethod(newTask.Triggers, 'Add', ...
                {'Microsoft.Win32.TaskScheduler.Trigger'}, oneTimeTrigger);
            % Handle restartTask trigger
            if nvArgs.autoRestart
                queryStr = "<QueryList><Query Id=""0"" Path=""Microsoft-Windows-TaskScheduler/Operational""><Select Path=""Microsoft-Windows-TaskScheduler/Operational"">*[System[(EventID=102)] and EventData[Data[@Name='TaskName']='\\%s\\%s']]</Select></Query></QueryList>";
                eventTrigger = Microsoft.Win32.TaskScheduler.EventTrigger;
                eventTrigger.Subscription = sprintf(queryStr,nvArgs.folderName,taskName);
                eventTrigger.ValueQueries.Add("Name", "Value");
                NET.invokeGenericMethod(newTask.Triggers,'Add',{'Microsoft.Win32.TaskScheduler.Trigger'},eventTrigger);
            end
            % Add action and argument
            action = Microsoft.Win32.TaskScheduler.ExecAction(commandToRun);
            if (strlength(commandArguments) > 0)
                action.Arguments = commandArguments;
            end
            NET.invokeGenericMethod(newTask.Actions,'Add',{'Microsoft.Win32.TaskScheduler.Action'},action);
            % Register task (add to Windows Task Scheduler)
            taskAction = Microsoft.Win32.TaskScheduler.TaskCreation.CreateOrUpdate;
            try
                if (username == "SYSTEM") % System account
                    logonType = Microsoft.Win32.TaskScheduler.TaskLogonType.ServiceAccount;
                    password = []; % Ensure empty password
                elseif (strlength(username) == 0) % Running user
                    logonType = Microsoft.Win32.TaskScheduler.TaskLogonType.InteractiveToken;
                    username = [];
                    password = [];
                else
                    logonType = Microsoft.Win32.TaskScheduler.TaskLogonType.Password;
                end
                taskInstance.RootFolder.RegisterTaskDefinition(fullTaskName, newTask, taskAction, ...
                    username, nvArgs.passwordDecrypter(password), logonType);
                taskObj = ScheduledTask(taskInstance.GetTask(fullTaskName));
            catch ME
                warning('SchedulerTaskService:CannotCreateTask','Cannot create task: %s', ME.message);
                taskObj = ScheduledTask.empty;
            end
        end
        function deleteTask(obj, taskName, taskFolder)
            %deleteTask  Delete a Scheduled Task by name
            %   deleteTask(wsObj, taskName, taskFolder) deletes the task named taskName from the folder
            %   taskFolder. A warning is issued if the task cannot be found.
            %
            %   See also: createTask, runTask.
            arguments
                obj
                taskName (1,1) string {mustBeNonzeroLengthText}
                taskFolder (1,1) string = ""
            end

            if taskExists(obj, taskName, taskFolder)
                obj.NetService.RootFolder.DeleteTask(getFullTaskName(taskFolder, taskName));
            else
                warning("WindowsScheduler:deleteTask:TaskDoesNotExist", "Task %s does not exist, so cannot be deleted.", getFullTaskName(taskFolder, taskName));
            end
        end
        function runTask(obj, taskName, taskFolder)
            %runTask  Run Scheduled Task by name
            %   runTask(wsObj, taskName, taskFolder) immediately runs the task named taskName found in folder
            %       taskFolder.
            %
            %   See also: createTask, deleteTask.
            arguments
                obj (1,1) WindowsScheduler
                taskName (1,1) string {mustBeNonzeroLengthText}
                taskFolder (1,1) string = ""
            end
            taskObj = getTaskByName(obj, taskName, taskFolder);
            run(taskObj);
        end
        function taskObj = getTaskByName(obj, taskName, taskFolder)
            %getTaskByName  Return a task object by name
            %   taskObj = getTaskByName(wsObj, taskName, taskFolder) returns the task named TaskName in folder
            %       TaskFolder. If TaskFolder is empty the task from the root folder is returned.
            %
            %   taskObj is returned as a ScheduledTask object.
            %
            %   See also: taskExists
            
            arguments
                obj (1,1) WindowsScheduler
                taskName (1,1) string {mustBeNonzeroLengthText}
                taskFolder (1,1) string = ""
            end
            taskObj = ScheduledTask(obj.NetService.GetTask(getFullTaskName(taskFolder, taskName)));
        end
        function tf = taskExists(obj, taskName, taskFolder)
            %taskExists  True if a task exists
            %   tf = taskExists(wsObj, TaskName, TaskFolder) returns true if a task with the name TaskName
            %       exists in folder TaskFolder. If TaskFolder is empty or not specified, taskExists looks in
            %       the root folder.
            %
            %   See also: getTaskByName
            
            arguments
                obj
                taskName (1,1) string {mustBeNonzeroLengthText}
                taskFolder (1,1) string = ""
            end
            tf = ~isempty(getTaskByName(obj, taskName, taskFolder));
        end
    end
    methods % Folder management
        function taskList = getTasksByFolder(obj, folderName)
            % getTasksByFolder  Retrieve all tasks in a given folder
            %   folderTasks = getTasksByFolder(FolderName) retrieves all tasks in folder FolderName. Tasks from
            %       sub-folders are not returned.
            %
            %   folderTasks is returned as an array of ScheduledTasks objects.
            %
            %   See also: getSubfolders.

            arguments
                obj (1,1) WindowsScheduler
                folderName (1,1) string = ""
            end
            
            taskFolder = obj.NetService.GetFolder("\"+folderName);
            if ~isempty(taskFolder)
                returnedTaskCollection = taskFolder.GetTasks;
                if double(returnedTaskCollection.Count) > 0
                    taskList = ScheduledTask(returnedTaskCollection);
                else
                    taskList = ScheduledTask.empty;
                end
            else
                taskList = ScheduledTask.empty;
            end
        end
    end
    methods % Task management
        function tf = enableTask(obj, taskName, taskFolder)
            %enableTask  Enable a Scheduled Task
            % enabled = enableTask(wsObj, taskName, folderName) enables the task given by taskName,
            %   existing in folder folderName. Returns true if the task could be enabled, false if the task
            %   could not be found (with a warning) and an error if the operation fails in some other way.
            %
            %   See also: disableTask

            arguments
                obj (1,1) WindowsScheduler
                taskName (1,1) string {mustBeNonzeroLengthText}
                taskFolder (1,1) string = ""
            end
            netTask = obj.NetService.GetTask(getFullTaskName(taskFolder, taskName));
            if ~isempty(netTask)
                netTask.Enabled = true;
                tf = true;
            else
                warning("WindowsScheduler:enableTask:TaskNotFound", ...
                    "Task %s does not exist, so cannot be enabled.", getFullTaskName(taskName, taskFolder));
                tf = false;
            end
        end
        function tf = disableTask(obj, taskName, taskFolder)
            %disableTask  Disable a Scheduled Task
            % disabled = disableTask(wsObj, taskName, folderName) disables the task given by taskName,
            %   existing in folder folderName. Returns true if the task could be disabled, false if the task
            %   could not be found (with a warning) and an error if the operation fails in some other way.
            %
            %   See also: enableTask

            arguments
                obj (1,1) WindowsScheduler
                taskName (1,1) string {mustBeNonzeroLengthText}
                taskFolder (1,1) string = ""
            end
            netTask = obj.NetService.GetTask(getFullTaskName(taskFolder, taskName));
            if ~isempty(netTask)
                netTask.Enabled = false;
                tf = true;
            else
                warning("WindowsScheduler:enableTask:TaskNotFound", ...
                    "Task %s does not exist, so cannot be enabled.", getFullTaskName(taskName, taskFolder));
                tf = false;
            end
        end
    end
end

%% Helpers
function fullName = getFullTaskName(folderName, taskName)
    if strlength(folderName) > 0
        fullName = folderName + "\" + taskName;
    else
        fullName = taskName;
    end
end
