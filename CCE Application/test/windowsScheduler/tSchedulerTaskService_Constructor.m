classdef tSchedulerTaskService_Constructor < matlab.unittest.TestCase
    %tWindowsSceduler
    
    properties
        SchedulerTaskServiceObj
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            testCase.SchedulerTaskServiceObj = SchedulerTaskService;
        end
    end
    
    methods(Test)
        
        function tConstructor(testCase)
            % T1 - Test that a Scheduler Task Service object is returned
            testCase.verifyClass(testCase.SchedulerTaskServiceObj, 'SchedulerTaskService', ...
                'Constructor failed to create SchedulerTaskService object');
            
            % T2 - Test that a TaskService object is returned
            testCase.verifyClass(testCase.SchedulerTaskServiceObj.TaskService, ...
                'Microsoft.Win32.TaskScheduler.TaskService',... 
                'Constructor failed to create TaskService as Microsoft.Win32.TaskScheduler.TaskService object');
            
            % T3 - Check that the default folder is set
            testCase.verifyEqual(testCase.SchedulerTaskServiceObj.DefaultFolder, ...
                "CCETasks", 'Incorrect default folder specified');
        end
    end
end

