classdef tSchedulerTaskService_CreateTask < matlab.unittest.TestCase
    %tSchedulerTaskService_CreateTask This is the tSchedulerTaskService_CreateTask test class 
    %   This will test whether the task service can create tasks   
    
    properties
        SchedulerTaskServiceObj
        Username = "" %Input username to run tCreateTaskAsUser
        Password = ""; %Input password to run test tCreateTaskAsUser
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            testCase.SchedulerTaskServiceObj = SchedulerTaskService;
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.CreateFolder("TestFolder");
        end
    end
    
    methods(TestClassTeardown)
        function removeTasksAndFolder(testCase)
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteTask("TestFolder\TestCreate1")
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteTask("TestFolder\TestCreate2");
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteTask("CCETasks\TestCreate3");
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteFolder("TestFolder");
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteFolder("CCETasks");
        end
    end
    
    methods(Test)
        function tCreateTaskAsUser(testCase)
            startTime = datetime(2021, 8, 8, 15, 40, 00);
            repeatInterval = 3600;
            stopOverrun = 1800;
            commandToRun = "C:\Program Files\Internet Explorer\iexplore.exe";
            commandArgument = "www.office.com";
            createdTask = testCase.SchedulerTaskServiceObj.createTask("TestCreate1", "author",...
                "Task created as user", startTime, repeatInterval, stopOverrun,...
                commandToRun, commandArgument, true, "TestFolder", testCase.Username, testCase.Password);
            testCase.verifyClass(createdTask, 'Microsoft.Win32.TaskScheduler.Task',...
                'Microsoft.Win32.TaskScheduler.Task object not returned');
            testCase.verifyEqual(string(createdTask.Definition.Principal.Account), testCase.Username);
        end
        
        function tCreateTaskAsSystem(testCase)
            startTime = datetime(2021, 8, 8, 15, 40, 00);
            repeatInterval = 3600;
            stopOverrun = 1800;
            commandToRun = "C:\Program Files\Internet Explorer\iexplore.exe";
            commandArgument = "www.office.com";
            createdTask = testCase.SchedulerTaskServiceObj.createTask("TestCreate2", "author",...
                "Task created as System", startTime, repeatInterval, stopOverrun,...
                commandToRun, commandArgument, true, "TestFolder");
            testCase.verifyClass(createdTask, 'Microsoft.Win32.TaskScheduler.Task',...
                'Microsoft.Win32.TaskScheduler.Task object not returned');
            testCase.verifyEqual(string(createdTask.Definition.Principal.Account), "NT AUTHORITY\SYSTEM");
        end
        
        function tCreateTaskInDefaultFolder(testCase)
            startTime = datetime(2021, 8, 8, 15, 40, 00);
            repeatInterval = 3600;
            stopOverrun = 1800;
            commandToRun = "C:\Program Files\Internet Explorer\iexplore.exe";
            commandArgument = "www.office.com";
            createdTask = testCase.SchedulerTaskServiceObj.createTask("TestCreate3", "author",...
                "Task created in default folder", startTime, repeatInterval, stopOverrun,...
                commandToRun, commandArgument, true);
            testCase.verifyClass(createdTask, 'Microsoft.Win32.TaskScheduler.Task',...
                'Microsoft.Win32.TaskScheduler.Task object not returned');
            testCase.verifyEqual(string(createdTask.Folder.Name), "CCETasks");
        end
    end
end

