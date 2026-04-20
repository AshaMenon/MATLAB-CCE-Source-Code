classdef ScheduledTask < handle & matlab.mixin.CustomDisplay
    %ScheduledTask  Describe a Windows Scheduled Task
    %   This class provides access to a Scheduled Task in Windows. Using the ScheduledTask class, you
    %   can enable or disable the task, and see specific properties of the task.
    %
    %   You cannot create a ScheduledTask object directly. Instead, use the WindowsScheduler class to
    %   find ScheduledTask objects.
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    % developed as background IP for Anglo American Platinum
    
    properties (Access = private)
        NetTask
    end
    properties (Dependent, SetAccess = private)
        Name
        FolderName
        Author
        Description
        StartTime
        RepeatInterval
        StopOverrun
        Command
        CommandArgs
        Username
        Enabled
        NextRunTime
        LastRunTime
        State
    end
    
    methods (Access = {?WindowsScheduler}) % COnstructor is restricted to the parent only
        function obj = ScheduledTask(netTask)
            %ScheduledTask  Construct a Windows ScheduledTask object
            %   You cannot directly create scheduled tasks. Use the WindowsScheduler class to query the local
            %   computer for tasks.
            if nargin
                if isempty(netTask)
                    obj = ScheduledTask.empty;
                else
                    if isa(netTask, "Microsoft.Win32.TaskScheduler.TaskCollection")
                        te = netTask.GetEnumerator;
                        ind = 1;
                        while (te.MoveNext)
                            if ind==1
                                obj(1,netTask.Count).NetTask = te.Current; % Do this to create the array the right size
                            end
                            obj(ind).NetTask = te.Current;
                            ind = ind+1;
                        end
                    elseif isa(netTask, "Microsoft.Win32.TaskScheduler.Task")
                        obj.NetTask = netTask;
                    else
                        warning("ScheduledTask:Constructor:InvalidClass", "Invalid class %s passed to ScheduledTask", class(netTask));
                    end
                end
            end
        end
    end
    methods (Access = protected) % Display methods
        function displayEmptyObject(obj)
            objName = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
            fprintf('0x0 %s\n', objName);
        end
        function displayNonScalarObject(obj)
            %displayNonScalarObject  Show a table of ScheduledTask properties
            objName = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
            dimStr = matlab.mixin.CustomDisplay.convertDimensionsToString(obj) ;
            fprintf('%s %s array:\n', dimStr, objName);
            disp(table(obj));
        end
    end
    methods % Getters
        function str = get.Name(obj)
            if isempty(obj.NetTask)
                str = "<invalid object>";
            else
                str = safeString(obj.NetTask.Name);
            end
        end
        function str = get.FolderName(obj)
            if isempty(obj.NetTask)
                str = "<invalid object>";
            else
                % Strip the first and last "\" from the path
                pathParts = split(string(obj.NetTask.Path),"\");
                if (numel(pathParts) <= 2)
                    str = "";
                else
                    str = join(pathParts(2:end-1),"\");
                end
            end
        end
        function str = get.Author(obj)
            if isempty(obj.NetTask)
                str = "<invalid object>";
            else
                str = safeString(obj.NetTask.Definition.RegistrationInfo.Author);
            end
        end
        function str = get.Description(obj)
            if isempty(obj.NetTask)
                str = "<invalid object>";
            else
                str = safeString(obj.NetTask.Definition.RegistrationInfo.Description);
            end
        end
        function st = get.StartTime(obj)
            if isempty(obj.NetTask)
                st = NaT;
            else
                e = obj.NetTask.Definition.Triggers.GetEnumerator;
                e.MoveNext;
                sb = e.Current.StartBoundary;
                st = datetime(sb.Year, sb.Month, sb.Day, sb.Hour, sb.Minute, sb.Second);
            end
        end
        function dObj = get.RepeatInterval(obj)
            if isempty(obj.NetTask)
                dObj = duration.empty;
            else
                e = obj.NetTask.Definition.Triggers.GetEnumerator;
                e.MoveNext;
                dObj = bestDurationFormat(seconds(e.Current.Repetition.Interval.TotalSeconds));
            end
        end
        function dObj = get.StopOverrun(obj)
            if isempty(obj.NetTask)
                dObj = duration.empty;
            else
                e = obj.NetTask.Definition.Triggers.GetEnumerator;
                e.MoveNext;
                dObj = bestDurationFormat(seconds(e.Current.ExecutionTimeLimit.TotalSeconds));
            end
        end
        function cmd = get.Command(obj)
            if isempty(obj.NetTask)
                cmd = "<invalid object>";
            else
                e = obj.NetTask.Definition.Actions.GetEnumerator;
                e.MoveNext;
                cmd = safeString(e.Current.Path);
            end
        end
        function cmdArg = get.CommandArgs(obj)
            if isempty(obj.NetTask)
                cmdArg = "<invalid object>";
            else
                e = obj.NetTask.Definition.Actions.GetEnumerator;
                e.MoveNext;
                cmdArg = string(e.Current.Arguments);
                if isempty(cmdArg) || ismissing(cmdArg)
                    cmdArg = "";
                end
            end
        end
        function str = get.Username(obj)
            if isempty(obj.NetTask)
                str = "<invalid object>";
            else
                str = safeString(obj.NetTask.Definition.Principal.Account);
            end
        end
        function tf = get.Enabled(obj)
            if isempty(obj.NetTask)
                tf = false;
            else
                tf = logical(obj.NetTask.Enabled);
            end
        end
        function dt = get.LastRunTime(obj)
            %get.LastRunTime  Last time the task was run
            dt = net2datetime(obj.NetTask.LastRunTime);
        end
        function dt = get.NextRunTime(obj)
            %get.NextRunTime  Next time the task was run
            dt = net2datetime(obj.NetTask.NextRunTime);
        end
        function stateStr = get.State(obj)
            %get.State  Retrieve State from Scheduled task
            stateStr = string(obj.NetTask.State);
        end
    end
    methods (Access = public) % Enable and Disable
        function enable(obj)
            %enable  Enable a scheduled task
            for k=1:numel(obj)
                obj(k).NetTask.Enabled = true;
            end
        end
        function disable(obj)
            %disable  Disable a scheduled task
            for k=1:numel(obj)
                obj(k).NetTask.Enabled = false;
            end
        end
        function run(obj)
            %runTask  Run Scheduled Task
            %   runTask(obj) runs the Scheduled Task(s) in obj immediately.
            for k=1:numel(obj)
                obj(k).NetTask.Run({});
            end
        end
    end
    methods % Data Converters
        function tbl = table(obj)
            tbl = table([obj.Name]', [obj.FolderName]', [obj.Command]', [obj.CommandArgs]', ...
                [obj.StartTime]', [obj.RepeatInterval]', [obj.StopOverrun]', [obj.Username]', ...
                [obj.Enabled]', [obj.Author]', [obj.Description]', ... 
                'VariableNames', ["Name", "FolderName", "Command", ...
                "Arguments", "StartTime", "RepeatInterval", "StopOverrun", "Username", ...
                "Enabled", "Author", "Description"]);
        end
    end
end

%% Local Helpers
function str = safeString(netObj)
    str = string(netObj);
    if isempty(str) || ismissing(str)
        str = "";
    end
end

function dObj = bestDurationFormat(dObj)
    % bestDurationFormat  Make a duration display as meaningfully as possible
    s = seconds(dObj);
    if (s >= 86400)
        if mod(s, 86400) == 0
            dObj.Format = "d";
        else
            dObj.Format = "dd:hh:mm:ss";
        end
    elseif (s >= 3600)
        if mod(s, 3600) == 0
            dObj.Format = "h";
        else
            dObj.Format = "hh:mm:ss";
        end
    elseif (s >= 60)
        if (mod(s, 60) == 0)
            dObj.Format = "m";
        else
            dObj.Format = "mm:ss";
        end
    else
        dObj.Format = "s";
    end
end

function dt = net2datetime(netTime)
    % net2datetime  Convert a .Net datetime to MATLAB datetime
    if (netTime.Year == 1) && (netTime.Month == 1) && (netTime.Day == 1)
        % This is likely a NULL. Return NaT
        dt = NaT;
    else
        dt = datetime(netTime.Year, netTime.Month, netTime.Day, netTime.Hour, netTime.Minute, netTime.Second);
    end
end