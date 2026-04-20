%% Scheduler Task Examples
% This is a script to show the behaviour of the Scheduler Task class (and
% the SchedulerTaskService class as they are closely linked)
%% Creating a scheduled task
% When creating a scheduled task the following arguments will be required:
% taskService - task scheduler service object
% name - the name of the task (string)
% author - the author of the task (string)
% description - the description of the task (string)
% startTime - the time that the task should begin the first run (datetime)
% repeatInterval - the interval in seconds that the task should repeat after it starts running (double)
% stopOverrun - overrun limit of a task in seconds (double)
% commandToRun - the command that the task will execute, path to the exe (string)
% commandArgument - the argument that is necessary for a task to execute (string)
% repeatTask - this will determine whether a task should be run when it ends - used for long running tasks (logical)
% nvArgs.folderName - optional folderName argument, it will use default CCETasks if folder not specified (string)
% nvArgs.username - optional username argument (will default to SYSTEM) -
% requires admin priviledges to create tasks, must use the app/script
% creating the task as administrator - in this case run MATLAB as admin)
% nvArgs.password - password required to create a task (will not be
% required for SYSTEM)

% Create the task service
schedulerTaskServiceObj = SchedulerTaskService;

% Create a scheduler task (SYSTEM as user account)
schedulerTaskObj = SchedulerTask.createNew(schedulerTaskServiceObj, "NewSchedulerTask", "User1",...
    "This is a new task created programmatically", datetime('now'), 3600, 600,...
    "C:\Program Files\Internet Explorer\iexplore.exe", true, folderName="MyTasks", commandArgument="www.optinum.co.za");

%% Deleting a scheduled task
% A scheduled task that needs to be removed requires the following arguments:
% taskService - A scheduler task service object
% taskName - The name of the task
% taskFolder - Folder of the task (this is optional, if not provided, the
% default folder will be used, a task will be deleted provided that the
% task can be found in the folder.

SchedulerTask.removeFromScheduler(schedulerTaskServiceObj, "NewSchedulerTask", folderName="MyTasks");

%% Get a task from the task scheduler
% A scheduled task that needs to be retrieved requires the following arguments:
% taskService - A scheduler task service object
% taskName - The name of the task (this is optional, if not provided, all
% the tasks in the folder will be returned)
% taskFolder - Folder of the task (this is optional, if not provided, the
% default folder will be used.
%
% A task will be retrieved based on whether
% the task exists in the folder, otherwise an empty task object will be
% returned.

% Return a single task
returnedSchedulerTaskObj = SchedulerTask.fetchFromScheduler(schedulerTaskServiceObj, taskName="NewSchedulerTask", folderName="MyTasks");
% Return all tasks in a folder
allTasksObj = SchedulerTask.fetchFromScheduler(schedulerTaskServiceObj, folderName="MyTasks");
%% Modify a task
% A scheduled task can be modified by editing the SchedulerTask object
% The properties that can be modified are: 
% Author - The author of the task
% Description - The description of the task
% StartTime - The time that the task should start
% RepeatInterval - The duration that the task should repeat in seconds
% StopOverrun - The overrun value for when a task should stop in seconds 
% RestartTask - The trigger to restart the task, whether this is true or false
% CommandToRun - The command that needs to be run, the full path needs to be provided
% CommandArgument - The argument that the CommandToRun needs to run successfully

returnedSchedulerTaskObj.Author = "User2";
returnedSchedulerTaskObj.RestartTask = false;
returnedSchedulerTaskObj.RestartTask = true;
returnedSchedulerTaskObj.CommandToRun = "C:\Program Files\Internet Explorer\iexplore.exe";
