classdef SchedulerTask < handle
    %SchedulerTask This is a scheduler task class
    %   A scheduler task class is used to determine information pertaining to itself
    %
    %   A scheduler task will consist of the following properties:
    %   Name: The name of the task
    %   FolderName: Name of the folder that the task will be stored
    %   Author: The entity that created the task
    %   Description: Some details regarding the task
    %   StartTime: The time that a task is set to start running
    %   RepeatInterval: The frequency that the task should run (in seconds)
    %   StopOverrun: The period of time that a task is allowed to run over before it is stopped (in seconds)
    %   RestartTask: Restart a task immediately if it ends
    %   CommandToRun: The application/command that the task needs to execute
    %   CommandArgument: Input argument required by the command to run
    %   User: The user that the task will run as
    
    properties (Access = private)
        SchedulerTaskService (1,1)
        UpdateTaskInScheduler (1,1) logical
    end
    
    properties
        Name (1,1) string
        FolderName (1,1) string
        Author (1,1) string
        Description (1,1) string
        StartTime (1,1) datetime
        RepeatInterval (1,1) double
        StopOverrun (1,1) double
        RestartTask (1,1) logical
        CommandToRun (1,1) string
        CommandArgument (1,1) string
        User (1,1) string
    end
    
    methods         
        function set.Author(obj, val)
            obj.Author = val;
            obj.setTaskProperty("Author", val);
        end

        function set.Description(obj, val)
            obj.Description = val;
            obj.setTaskProperty("Description", val);
        end
        
        function set.StartTime(obj, val)
            obj.StartTime = val;
            obj.setTaskProperty("StartTime", val);
        end
        
        function set.RepeatInterval(obj, val)
            obj.RepeatInterval = val;
            obj.setTaskProperty("RepeatInterval", val);
        end
        
        function set.StopOverrun(obj, val)
            obj.StopOverrun = val;
            obj.setTaskProperty("StopOverrun", val);
        end
        
        function set.RestartTask(obj, val)
            obj.RestartTask = val;
            obj.setTaskProperty("RestartTask", val);
        end
        
        function set.CommandToRun(obj, val)
            obj.CommandToRun = val;
            obj.setTaskProperty("CommandToRun", val);
        end
        
        function set.CommandArgument(obj, val)
            obj.CommandArgument = val;
            obj.setTaskProperty("CommandArgument", val);
        end
    end
    
    methods (Access = private)
        function obj = SchedulerTask(taskService, updateTaskInScheduler, rawTask)
            %SchedulerTask Create a Scheduler Task object that is the
            %MATLAB representation of the task
            obj.SchedulerTaskService = taskService;
            obj.UpdateTaskInScheduler = updateTaskInScheduler;
            readTask(obj, rawTask);
        end
        
        function readTask(obj, rawTask)
            %readTask Read the task to convert it to MATLAB data types
            % This function will read the raw task values and convert them
            % to the appropriate data types to represent the Scheduler Task
            % properties
            arguments
                obj (1,1) SchedulerTask
                rawTask (1,1) {mustBeNonempty}
            end
            
            obj.Name = string(rawTask.Name);
            obj.FolderName = string(rawTask.Folder.Path);
            author = string(rawTask.Definition.RegistrationInfo.Author);
            obj.Author = author;
            obj.Description = string(rawTask.Definition.RegistrationInfo.Description);
            frequencyTrigger = rawTask.Definition.Triggers.Item(0);
            obj.StartTime = datetime(frequencyTrigger.StartBoundary.Year, ...
                frequencyTrigger.StartBoundary.Month, frequencyTrigger.StartBoundary.Day,...
                frequencyTrigger.StartBoundary.Hour, frequencyTrigger.StartBoundary.Minute,...
                frequencyTrigger.StartBoundary.Second);
            obj.RepeatInterval = double(frequencyTrigger.Repetition.Interval.TotalSeconds);
            obj.StopOverrun = double(frequencyTrigger.ExecutionTimeLimit.TotalSeconds) - obj.RepeatInterval;
            if rawTask.Definition.Triggers.Count == 2
                obj.RestartTask = true;
            else
                obj.RestartTask = false;
            end 
            obj.CommandToRun = string(rawTask.Definition.Actions.Item(0).Path); %Assumes only one action
            if ~isempty(string(rawTask.Definition.Actions.Item(0).Arguments))
                obj.CommandArgument = string(rawTask.Definition.Actions.Item(0).Arguments); %Assumes only one argument
            else
                obj.CommandArgument = "";
            end
            
            obj.User = string(rawTask.Definition.Principal.Account);
        end
        
        function setTaskProperty(obj, taskProperty, value)
            %setTaskProperty This will update the task in the scheduler
            % The task will be updated in the scheduler if the
            % UpdateTaskInScheduler flag is set to true
            arguments
                obj
                taskProperty (1,1) string
                value
            end
            if obj.UpdateTaskInScheduler
                obj.SchedulerTaskService.updateTask(obj.Name, obj.FolderName, taskProperty, value);
            end
        end
    end
    
    methods(Static)
        function obj = createNew(taskService, name, author, description, startTime,...
                repeatInterval, stopOverrun, commandToRun, restartTask, nvArgs)
            %createNew Create a new Scheduler Task
            % This will create a new Scheduler Task
            % If a username and password is supplied, the task will run as
            % that user. If a username and password is not supplied, the
            % task will run as SYSTEM. If a folderName is supplied, the
            % task will be created in that folder, if a folderName is not
            % supplied, a task will be created in the default folder "CCETasks"
            arguments
                taskService (1,1) SchedulerTaskService {mustBeNonempty}
                name (1,1) string {mustBeNonempty}
                author (1,1) string {mustBeNonempty}
                description (1,1) string {mustBeNonempty}
                startTime (1,1) datetime {mustBeNonempty}
                repeatInterval (1,1) double {mustBeNonempty}
                stopOverrun (1,1) double {mustBeNonempty}
                commandToRun (1,1) string {mustBeNonempty}
                restartTask (1,1) logical {mustBeNonempty}
                nvArgs.commandArgument (1,1) string = ""
                nvArgs.folderName (1,1) string = ""
                nvArgs.username (1,1) string = ""
                nvArgs.password (1,1) string = ""
            end
            
            task = taskService.createTask(name, author, description, startTime,...
                repeatInterval, stopOverrun, commandToRun, nvArgs.commandArgument,...
                restartTask, nvArgs.folderName, nvArgs.username, nvArgs.password);
            if ~isempty(task)
                updateTaskInScheduler = false;
                obj = SchedulerTask(taskService, updateTaskInScheduler, task);
                obj.UpdateTaskInScheduler = true;
            else
                obj = SchedulerTask.empty;
            end
        end
        
        function obj = fetchFromScheduler(taskService, nvArgs)
            %fetchFromScheduler This will fetch tasks from the Scheduler
            % A task/tasks will be fetched from the Scheduler. If a
            % taskName and folderName is supplied, that task will be fetched from that folder
            % If a taskName is only supplied, the task will be fetched from
            % the default folder "CCETasks", if it exists. If only a
            % folderName is supplied, then all tasks in that folder will be
            % returned provided that the folder exists and contains tasks.
            arguments
                taskService (1,1) SchedulerTaskService {mustBeNonempty}
                nvArgs.taskName (1,1) string = ""
                nvArgs.folderName (1,1) string = ""
            end
            
            if nvArgs.taskName ~= ""
                task = taskService.readTask(nvArgs.taskName, nvArgs.folderName);
                if ~isempty(task)
                    updateTaskInScheduler = false;
                    obj = SchedulerTask(taskService, updateTaskInScheduler, task);
                    obj.UpdateTaskInScheduler = true;
                else
                    obj = SchedulerTask.empty;
                end
            else
                tasks = taskService.findTasks(nvArgs.folderName);
                if ~isempty(tasks)
                    updateTaskInScheduler = false;
                    for ii = 0:double(tasks.Count)-1
                        obj(ii+1) = SchedulerTask(taskService, updateTaskInScheduler, tasks.Item(ii));
                        obj(ii+1).UpdateTaskInScheduler = true;
                    end
                else
                    obj = SchedulerTask.empty;
                end
            end
        end
        
        function removeFromScheduler(taskService, taskName, nvArgs)
            %removeFromScheduler Remove tasks from the Scheduler
            % Tasks will be deleted from the Scheduler. If a folderName is
            % supplied, then the task will be deleted from that folder. If
            % a folderName is not supplied, a task will be deleted from the
            % default folder "CCETasks" provided that it exists.
            arguments
                taskService (1,1) SchedulerTaskService {mustBeNonempty}
                taskName (1,1) string {mustBeNonempty}
                nvArgs.folderName (1,1) string = ""
            end
            
            taskService.removeTask(taskName, nvArgs.folderName);
            
        end
        
        function runSchedulerTask(taskService, taskName, nvArgs)
            % runSchedulerTask This will run a Scheduled task
            % A scheduled task will run if that task exists and the task is
            % set to enabled
            arguments
                taskService (1,1) SchedulerTaskService {mustBeNonempty}
                taskName (1,1) string {mustBeNonempty}
                nvArgs.folderName (1,1) string = ""
            end
            
            taskService.runTask(taskName, nvArgs.folderName);
            
        end
    end
end

