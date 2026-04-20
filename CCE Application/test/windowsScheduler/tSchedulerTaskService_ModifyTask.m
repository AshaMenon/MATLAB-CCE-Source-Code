classdef tSchedulerTaskService_ModifyTask < matlab.unittest.TestCase
    %tSchedulerTask_ModifyTask This is a tSchedulerTaskService_ModifyTask test class
    %   This will test whether the SchedulerTaskService class can modify
    %   tasks
    
    properties
        SchedulerTaskServiceObj
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            testCase.SchedulerTaskServiceObj = SchedulerTaskService;
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.CreateFolder("TestFolder");
            newTask = testCase.SchedulerTaskServiceObj.TaskService.NewTask;
            newTask.RegistrationInfo.Author = "Test";
            newTask.RegistrationInfo.Description = "Test Task for Modifying a Task";
            startTime = datetime('now');
            repeatInterval = double(60); %seconds
            stopOverrun = double(10); %seconds
            oneTimeTrigger = Microsoft.Win32.TaskScheduler.TimeTrigger;
            oneTimeTrigger.StartBoundary = System.DateTime(startTime.Year,...
                startTime.Month, startTime.Day, startTime.Hour,...
                startTime.Minute, startTime.Second);
            oneTimeTrigger.Repetition.Interval = System.TimeSpan(0, 0, repeatInterval);
            oneTimeTrigger.Repetition.Duration = System.TimeSpan.Zero;
            oneTimeTrigger.ExecutionTimeLimit = System.TimeSpan(0, 0, repeatInterval+stopOverrun);
            NET.invokeGenericMethod(newTask.Triggers, 'Add', {'Microsoft.Win32.TaskScheduler.Trigger'}, oneTimeTrigger);
            
            action = Microsoft.Win32.TaskScheduler.ExecAction("C:\Program Files\Internet Explorer\iexplore.exe");
            action.Arguments = "www.office.com";
            NET.invokeGenericMethod(newTask.Actions,'Add',{'Microsoft.Win32.TaskScheduler.Action'},action);
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.RegisterTaskDefinition("TestFolder\TestForModifying", newTask);
        end
    end
    
    methods(TestClassTeardown)
        function removeTaskAndFolder(testCase)
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteTask("TestFolder\TestForModifying");
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteFolder("TestFolder");
        end
    end
    
    methods(Test)
        function tModifyAuthor(testCase)
            testCase.SchedulerTaskServiceObj.updateTask("TestForModifying", "TestFolder", "Author", "TestAuthorUpdate");
            modifiedTask = testCase.SchedulerTaskServiceObj.TaskService.GetTask("TestFolder\TestForModifying");
            testCase.verifyEqual(string(modifiedTask.Definition.RegistrationInfo.Author), "TestAuthorUpdate");
        end
        
        function tModifyDescription(testCase)
            testCase.SchedulerTaskServiceObj.updateTask("TestForModifying", "TestFolder", "Description", "TestDescriptionUpdate");
            modifiedTask = testCase.SchedulerTaskServiceObj.TaskService.GetTask("TestFolder\TestForModifying");
            testCase.verifyEqual(string(modifiedTask.Definition.RegistrationInfo.Description), "TestDescriptionUpdate");
        end
        
        function tModifyStartTime(testCase)
            modifiedStartTime = datetime(2021, 08, 08, 15, 15, 15);
            testCase.SchedulerTaskServiceObj.updateTask("TestForModifying", "TestFolder", "StartTime", modifiedStartTime);
            modifiedTask = testCase.SchedulerTaskServiceObj.TaskService.GetTask("TestFolder\TestForModifying");
            modifiedTaskStartTime = modifiedTask.Definition.Triggers.Item(0).StartBoundary;
            modifiedTaskStartTimeConverted = datetime(modifiedTaskStartTime.Year, modifiedTaskStartTime.Month,...
                modifiedTaskStartTime.Day, modifiedTaskStartTime.Hour, modifiedTaskStartTime.Minute, modifiedTaskStartTime.Second);
            testEqual = isequal(modifiedTaskStartTimeConverted,modifiedStartTime);
            testCase.verifyEqual(testEqual,true);
        end
        
        function tModifyRepeatInterval(testCase)
            modifiedRepeatInterval = 70;
            testCase.SchedulerTaskServiceObj.updateTask("TestForModifying", "TestFolder", "RepeatInterval", modifiedRepeatInterval);
            modifiedTask = testCase.SchedulerTaskServiceObj.TaskService.GetTask("TestFolder\TestForModifying");
            modifiedTaskRepeatInterval = double(modifiedTask.Definition.Triggers.Item(0).Repetition.Interval.TotalSeconds);
            testEqual = isequal(modifiedTaskRepeatInterval, modifiedRepeatInterval);
            testCase.verifyEqual(testEqual, true);
        end
        
        function tModifyStopOverrun(testCase)
            repeatInterval = 70;
            modifiedStopOverrun = 10;
            testCase.SchedulerTaskServiceObj.updateTask("TestForModifying", "TestFolder", "StopOverrun", modifiedStopOverrun);
            modifiedTask = testCase.SchedulerTaskServiceObj.TaskService.GetTask("TestFolder\TestForModifying");
            modifiedTaskStopOverun = modifiedTask.Definition.Triggers.Item(0).ExecutionTimeLimit.TotalSeconds;
            testEqual = isequal(modifiedTaskStopOverun, modifiedStopOverrun + repeatInterval);
            testCase.verifyEqual(testEqual, true);
        end
        
        function tModifyAddRestartTask(testCase)
            modifyRestartTask = true;
            testCase.SchedulerTaskServiceObj.updateTask("TestForModifying", "TestFolder", "RestartTask", modifyRestartTask);
            modifiedTask = testCase.SchedulerTaskServiceObj.TaskService.GetTask("TestFolder\TestForModifying");
            testCase.verifyEqual(double(modifiedTask.Definition.Triggers.Count),2);
        end
        
        function tModifyRemoveRestartTask(testCase)
            modifyRestartTask = false;
            testCase.SchedulerTaskServiceObj.updateTask("TestForModifying", "TestFolder", "RestartTask", modifyRestartTask);
            modifiedTask = testCase.SchedulerTaskServiceObj.TaskService.GetTask("TestFolder\TestForModifying");
            testCase.verifyEqual(double(modifiedTask.Definition.Triggers.Count),1);
        end
        
        function tModifyCommandToRun(testCase)
            modifiedCommandToRun = "C:\Program Files\Notepad++\notepad++.exe";
            testCase.SchedulerTaskServiceObj.updateTask("TestForModifying", "TestFolder", "CommandToRun", modifiedCommandToRun);
            modifiedTask = testCase.SchedulerTaskServiceObj.TaskService.GetTask("TestFolder\TestForModifying");
            testCase.verifyEqual(string(modifiedTask.Definition.Actions.Item(0).Path), modifiedCommandToRun);
        end
        
        function tModifyCommandArgument(testCase)
            modifiedCommandArg = "testCommand";
            testCase.SchedulerTaskServiceObj.updateTask("TestForModifying", "TestFolder", "CommandArgument", modifiedCommandArg);
            modifiedTask = testCase.SchedulerTaskServiceObj.TaskService.GetTask("TestFolder\TestForModifying");
            testCase.verifyEqual(string(modifiedTask.Definition.Actions.Item(0).Arguments), modifiedCommandArg);
        end
    end
end

