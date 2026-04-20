classdef tSchedulerTaskService_FindTasks < matlab.unittest.TestCase
    %tSchedulerTaskservice This is the tSchedulerTaskService_FindsTasks test class
    %   This will test whether the SchedulerTaskService class can find a
    %   specified task or all tasks
    
    properties
        SchedulerTaskServiceObj
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            testCase.SchedulerTaskServiceObj = SchedulerTaskService;
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.CreateFolder("TestFolder");
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.CreateFolder("EmptyFolder");
            newTask = testCase.SchedulerTaskServiceObj.TaskService.NewTask;
            newTask.RegistrationInfo.Author = "NicoleR";
            newTask.RegistrationInfo.Description = "Test Task for Finding A Task By Name";
            action = Microsoft.Win32.TaskScheduler.ExecAction("C:\Program Files\Internet Explorer\iexplore.exe");
            action.Arguments = "www.office.com";
            NET.invokeGenericMethod(newTask.Actions,'Add',{'Microsoft.Win32.TaskScheduler.Action'},action);
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.RegisterTaskDefinition("TestFolder\TestForFind1", newTask);
            
            newTask = testCase.SchedulerTaskServiceObj.TaskService.NewTask;
            newTask.RegistrationInfo.Author = "NicoleR";
            newTask.RegistrationInfo.Description = "Test Task for Finding A Task By Name";
            action = Microsoft.Win32.TaskScheduler.ExecAction("C:\Program Files\Internet Explorer\iexplore.exe");
            action.Arguments = "www.office.com";
            NET.invokeGenericMethod(newTask.Actions,'Add',{'Microsoft.Win32.TaskScheduler.Action'},action);
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.RegisterTaskDefinition("TestFolder\TestForFind2", newTask);
            
        end
    end
    
    methods(TestClassTeardown)
        function removeTasksAndFolders(testCase)
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteTask("TestFolder\TestForFind1")
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteTask("TestFolder\TestForFind2");
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteFolder("TestFolder");
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteFolder("EmptyFolder");
        end
    end
    
    methods(Test)
        function tFindTaskByNameThatExists(testCase)
            % Find the task
            returnedTask = testCase.SchedulerTaskServiceObj.readTask("TestForFind1","TestFolder");
            % Check that the task contains a task object
            testCase.verifyClass(returnedTask, 'Microsoft.Win32.TaskScheduler.Task',...
                'Microsoft.Win32.TaskScheduler.Task object not returned');
        end
        
        function tFindTaskByNameThatDoesNotExist(testCase)
            returnedTask = testCase.SchedulerTaskServiceObj.readTask("TestNonExistentTask","TestFolder");
            testCase.verifyEmpty(returnedTask);
        end
        
        function tRetrieveTaskList(testCase)
            % Get list of tasks in a folder
            taskList = testCase.SchedulerTaskServiceObj.findTasks("TestFolder");
            % Check that a task collection is returned
            testCase.verifyClass(taskList, 'Microsoft.Win32.TaskScheduler.TaskCollection',...
                'Microsoft.Win32.TaskScheduler.TaskCollection not returned');
        end
        
        function tRetrieveTasksFromEmptyFolder(testCase)
            taskList = testCase.SchedulerTaskServiceObj.findTasks("EmptyFolder");
            testCase.verifyEmpty(taskList);
        end
        
        function tRetrieveTasksFromFolderThatDoesNotExist(testCase)
            taskList = testCase.SchedulerTaskServiceObj.findTasks("FolderThatDoesNotExist");
            testCase.verifyEmpty(taskList);
        end
    end
end

