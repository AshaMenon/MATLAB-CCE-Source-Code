classdef tSchedulerTask < matlab.unittest.TestCase
    %tSchedulerTask This is the tSchedulerTask test class
    %   This will test SchedulerTask class functions createNew and
    %   fetchFromScheduler
    
    properties
        SchedulerTaskServiceObj
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            testCase.SchedulerTaskServiceObj = SchedulerTaskService;
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.CreateFolder("TestFolder");
            
            startTime = datetime(2021, 8, 8, 15, 40, 00);
            repeatInterval = 3600;
            stopOverrun = 1800;
            commandToRun = "C:\Program Files\Internet Explorer\iexplore.exe";
            commandArgument = "www.office.com";
            testCase.SchedulerTaskServiceObj.createTask("TestFetchTask1", "author",...
                "Scheduler Task to test fetching", startTime, repeatInterval, stopOverrun,...
                commandToRun, commandArgument, false, "TestFolder");
            testCase.SchedulerTaskServiceObj.createTask("TestFetchTask2", "author",...
                "Scheduler Task to test fetching", startTime, repeatInterval, stopOverrun,...
                commandToRun, commandArgument, false, "TestFolder");
        end
    end
    
    methods(TestClassTeardown)
        function removeTaskAndFolder(testCase)
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteTask("TestFolder\NewTestSchedulerTask")
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteTask("TestFolder\TestFetchTask1");
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteTask("TestFolder\TestFetchTask2");
            testCase.SchedulerTaskServiceObj.TaskService.RootFolder.DeleteFolder("TestFolder");
        end
    end
    
    methods(Test)
        
        function tCreateNewTask(testCase)
            startTime = datetime(2021, 8, 8, 15, 40, 00);
            repeatInterval = 3600;
            stopOverrun = 1800;
            commandToRun = "C:\Program Files\Internet Explorer\iexplore.exe";
            commandArgument = "www.office.com";
            
            taskObj = SchedulerTask.createNew(testCase.SchedulerTaskServiceObj, "NewTestSchedulerTask", "NicoleR",...
                "This is a test using Scheduler Task class", startTime, repeatInterval, stopOverrun,...
                commandToRun, false, commandArgument=commandArgument, folderName="TestFolder");
            testCase.verifyClass(taskObj, "SchedulerTask", "SchedulerTask object not returned");
        end
        
        function tCreateNewTaskFail(testCase)
            startTime = datetime(2021, 8, 8, 15, 40, 00);
            repeatInterval = 3600;
            stopOverrun = 1800;
            commandToRun = "C:\Program Files\Internet Explorer\iexplore.exe";
            commandArgument = "www.office.com";
            
            taskObj = SchedulerTask.createNew(testCase.SchedulerTaskServiceObj, "NewTestSchedulerTask", "NicoleR",...
                "This is a test using Scheduler Task class", startTime, repeatInterval, stopOverrun,...
                commandToRun, false, commandArgument=commandArgument, folderName="TestFolder", username="OPTINUM\nicole.ramessar");
            testCase.verifyEmpty(taskObj);
        end
        
        function tFetchExistingTaskFromScheduler(testCase)
            taskObj = SchedulerTask.fetchFromScheduler(testCase.SchedulerTaskServiceObj,...
                taskName="TestFetchTask1",folderName="TestFolder");
            testCase.verifyClass(taskObj, "SchedulerTask", "SchedulerTask object not returned");
        end
        
        function tFetchExistingTasksFromScheduler(testCase)
            taskObj = SchedulerTask.fetchFromScheduler(testCase.SchedulerTaskServiceObj,...
                folderName="TestFolder");
            testCase.verifyClass(taskObj, "SchedulerTask", "SchedulerTask object not returned");
        end
        
        function tFetchNonExistentTaskFromScheduler(testCase)
            taskObj = SchedulerTask.fetchFromScheduler(testCase.SchedulerTaskServiceObj,...
                taskName="NonExistentTask");
            testCase.verifyEmpty(taskObj);
        end
        
        function tFetchTasksFromNonExistentFolder(testCase)
            taskObj = SchedulerTask.fetchFromScheduler(testCase.SchedulerTaskServiceObj,...
                folderName="NonExistentFolder");
            testCase.verifyEmpty(taskObj);
        end
    end
end

