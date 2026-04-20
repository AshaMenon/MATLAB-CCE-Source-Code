classdef tSchedulerTaskService_RemoveTask < matlab.unittest.TestCase
    %tSchedulerTaskService_RemoveTask This is the tSchedulerTaskService_RemoveTask test class
    %   This will test whether the task service can delete a task
    
    properties
        SchedulerTaskServiceObj
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            testCase.SchedulerTaskServiceObj = SchedulerTaskService;
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.CreateFolder("TestFolder");
            newTask = testCase.SchedulerTaskServiceObj.TaskService.NewTask;
            newTask.RegistrationInfo.Author = "NicoleR";
            newTask.RegistrationInfo.Description = "Test Task for Deleting";
            action = Microsoft.Win32.TaskScheduler.ExecAction("C:\Program Files\Internet Explorer\iexplore.exe");
            action.Arguments = "www.office.com";
            NET.invokeGenericMethod(newTask.Actions,'Add',{'Microsoft.Win32.TaskScheduler.Action'},action);
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.RegisterTaskDefinition("TestFolder\TestForDelete", newTask);
        end
    end
    
    methods(TestClassTeardown)
        function removeFolder(testCase)
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteFolder("TestFolder");
        end
    end
    
    methods(Test)
        function tRemoveTaskThatExists(testCase)
            % Delete the task
            testCase.SchedulerTaskServiceObj.removeTask("TestForDelete","TestFolder")
            % Check for the task
            deletedTask = testCase.SchedulerTaskServiceObj.TaskService.GetTask("TestFolder\TestForDelete");
            % Verify that the value returned is empty
            testCase.verifyEmpty(deletedTask);
        end
        
        function tRemoveTaskThatDoesNotExist(testCase)
            testCase.verifyError(@() testCase.SchedulerTaskServiceObj.removeTask("TestForNoNExistentTask","TestFolder"),...
                'SchedulerTaskService:CannotRemoveTask');
        end
        
    end
end

