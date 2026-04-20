function [schedulerTaskObj] = createScheduledTask(id, offset, frequency, repeatInterval)
    %CREATESCHEDULEDTASK creates a scheduled task to run the Coordinator with
    %CoordinatorID, ID, starting at an OFFSET from midnight restarting at a frequency
    %defined by EXECFREQUENCY.
    % Inputs:
    %   ID          -	(uint32) Unique CoordinatorID used as the input argument for the
    %                   cce.Coordinator (cceCoordinator.exe) task. ID is used to uniquely
    %                   name the scheduled task.
    %   OFFSET      -   (duration) time since midnight for the first run of the
    %                   cce.Coordinator (cceCoordinator.exe) task.
    %   FREQUENCY   -   (duration) the frequency in seconds that a Coordinator must run a
    %                   Calculation since the midnight offset
    %   REPEATINTERVAL   -	(duration) the interval in seconds that the task should repeat
    %                       after it starts running.
    
    arguments
        id (1,1) int32;
        offset (1,1) duration;
        frequency (1,1) duration;
        repeatInterval (1,1) duration;
    end
    
    if ~cce.System.TestMode
        [taskFolder, taskName] = cce.getTaskPath(id);
        descriptionStr = sprintf("CCE Coordinator Task for CoordinatorID: %d", id);
        taskSchedulerService = WindowsScheduler;
        encrypterService = AESEncrypter;
        
        if ismissing(frequency)
            frequency = minutes(1);
        end
        
        %Find the next possible start time.
        [startTime] = findScheduledTaskStartTime(offset, frequency);
        stopOverrun = (1 + cce.System.CoordinatorLifetimeOverrunPercentage/100) * repeatInterval;
        coordpath = fullfile(cce.System.RootFolder, "bin", "cceCoordinator.exe");
        inArgument = string(id);

        % Do not auto-restart if the frequency is greater than the Coordinator Frequency Limit
        mustRestart = (frequency < cce.System.CoordinatorFrequencyLimit);
        
        % Create a Coordinator Scheduled Task in the CCE folder
        schedulerTaskObj = taskSchedulerService.createTask(taskName, coordpath, inArgument, startTime, repeatInterval, ...
            stopAfter=stopOverrun, autoRestart=mustRestart, folderName=taskFolder, ...
            description=descriptionStr, author="CCE Configurator", ...
            userCredentials = [string(cce.System.CCEUsername), string(cce.System.CCEPassword)], ...
            passwordDecrypter=@(x)encrypterService.decrypt(x));
    else
        schedulerTaskObj = SchedulerTask.empty;
    end
end