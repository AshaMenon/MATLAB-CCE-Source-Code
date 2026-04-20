classdef tSchedulerTaskService_RunTask < matlab.unittest.TestCase
    %tSchedulerTaskService_RunTask This is the tSchedulerTaskService_RemoveTask test class
    %   This will test whether the task service can run a task
    
    properties
        SchedulerTaskServiceObj
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            testCase.SchedulerTaskServiceObj = SchedulerTaskService;
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.CreateFolder("TestFolder");
            newTask = testCase.SchedulerTaskServiceObj.TaskService.NewTask;
            newTask.RegistrationInfo.Author = "NicoleR";
            newTask.RegistrationInfo.Description = "Test Task for Running";
            action = Microsoft.Win32.TaskScheduler.ExecAction("C:\Program Files\Internet Explorer\iexplore.exe");
            action.Arguments = "www.office.com";
            NET.invokeGenericMethod(newTask.Actions,'Add',{'Microsoft.Win32.TaskScheduler.Action'},action);
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.RegisterTaskDefinition("TestFolder\TestForRunning1", newTask);
            
            newTask = testCase.SchedulerTaskServiceObj.TaskService.NewTask;
            newTask.RegistrationInfo.Author = "NicoleR";
            newTask.RegistrationInfo.Description = "Test Task for Running";
            action = Microsoft.Win32.TaskScheduler.ExecAction("C:\Program Files\Internet Explorer\iexplore.exe");
            action.Arguments = "www.office.com";
            NET.invokeGenericMethod(newTask.Actions,'Add',{'Microsoft.Win32.TaskScheduler.Action'},action);
            newTask.Settings.Enabled = false;
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.RegisterTaskDefinition("TestFolder\TestForRunning2", newTask);
            
        end
    end
    
    methods(TestClassTeardown)
        function removeTaskAndFolder(testCase)
            taskForRunning1 = testCase.SchedulerTaskServiceObj.TaskService.GetTask("TestFolder\TestForRunning1");
            taskForRunning1.Stop();
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteTask("TestFolder\TestForRunning1");
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteTask("TestFolder\TestForRunning2");
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteFolder("TestFolder");
        end
    end
    
    methods(Test)
        function tRunTaskThatExists(testCase)
            testCase.SchedulerTaskServiceObj.runTask("TestForRunning1", "TestFolder");
            taskForRunning = testCase.SchedulerTaskServiceObj.TaskService.GetTask("TestFolder\TestForRunning1");
            testCase.verifyEqual(string(taskForRunning.State), "Running");
        end
        
        function tRunTaskThatDoesNotExist(testCase)
            testCase.verifyError(@() testCase.SchedulerTaskServiceObj.runTask("TestForNoNExistentTask","TestFolder"),...
                'SchedulerTaskService:CannotRunTask');
        end
        
        function tRunDisabledTask(testCase)
            testCase.verifyError(@() testCase.SchedulerTaskServiceObj.runTask("TestForRunning2","TestFolder"),...
                'SchedulerTaskService:CannotRunTask');
        end
    end
    
end

