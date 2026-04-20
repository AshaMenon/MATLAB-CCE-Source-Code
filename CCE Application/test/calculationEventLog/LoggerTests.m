classdef LoggerTests < matlab.unittest.TestCase
    
    properties
        Inputs
        Parameters
    end
    
    properties (TestParameter)
        noLoggingInput = {900}
        noLoggingOutput = {[40,31,0]}
        errorInput = {0;'900'}
        errorOutput = {{{['oscDet_001, Oscillation Detection, Error, ',...
            'Window length must be a finite positive scalar or 2-element vector of finite nonnegative scalars.']},...
            [NaN, NaN]}; {{['oscDet_001, Oscillation Detection, Error, ', ...
            'Array indices must be positive integers or logical values.']},[NaN, NaN]}}
        warningInput = {800; 850}
        infoInput = {900}
        infoOutput = {{{'oscDet_001, Oscillation Detection, Info, Calculation completed; Successful'},...
            [40, 31]}}
        warningOutput = {{{'oscDet_001, Oscillation Detection, Warning, Fs value below threshold'},...
            [46, 37]}; {{'oscDet_001, Oscillation Detection, Warning, Fs value below threshold'},...
            [37, 28]}}
        msgSeverityInput = {{900, 'None'};{850, 'Info'};{850, 'Debug'}}
        msgSeverityOutput = {{'',[40,31]};{'oscDet_001, Oscillation Detection, Warning, Fs value below threshold',...
            'oscDet_001, Oscillation Detection, Info, Calculation completed; Successful',...
            [37, 28]};{'oscDet_001, Oscillation Detection, Warning, Fs value below threshold',...
            'oscDet_001, Oscillation Detection, Debug, 37',...
            'oscDet_001, Oscillation Detection, Info, Calculation completed; Successful',...
            [37, 28]}}
        logLevelInput = {'Error'; 'Warning'; 'Info'; 'Debug'; 'None'}
        logLevelOutput = {{'Oscillation Detection, oscDet_001, Debug, Test|Debug',...
            'Oscillation Detection, oscDet_001, Error, Array indices must be positive integers or logical values.'};
            {'Oscillation Detection, oscDet_001, Warning, Test warning',...
                'Oscillation Detection, oscDet_001, Debug, Test|Debug',...
                'Oscillation Detection, oscDet_001, Error, Array indices must be positive integers or logical values.'};
            {'Oscillation Detection, oscDet_001, Warning, Test warning',...
                'Oscillation Detection, oscDet_001, Info, Test info',...
                'Oscillation Detection, oscDet_001, Debug, Test|Debug',...
                'Oscillation Detection, oscDet_001, Error, Array indices must be positive integers or logical values.'};
            {'Oscillation Detection, oscDet_001, Debug, Test|Debug'};
                {''}}
        
    end
    methods (TestMethodSetup)
        function  setup(testCase)
            addpath(genpath('..\..\cce\calculationEventLog'))
            addpath(genpath('..\..\calculationSupport\'))
            if ~exist('cce_calc_event_logs', 'dir')
                mkdir('cce_calc_event_logs')
            end
        end
        
        function setProps(testCase)
            % Load Data & Parameters
            dataTbl = readtimetable(fullfile('..','..','mockData','oscillationDetectionSample.csv'));
            inputs.PV = dataTbl.PV;
            inputs.PVTimestamps = dataTbl.Date;
            inputs.RRCount = dataTbl.reversalCount(end);
            inputs.OscCount = dataTbl.oscillationCount(end);
            parameters.TSample = 10;
            parameters.RRWsize = 100;
            parameters.PVThreshold = 10000;
            parameters.TIntegral = 500;
            parameters.Rmax = 10;
            testCase.Parameters.Fs = 900;
            parameters.LogName = 'cce_calc_event_logs\logFileTest.log';
            parameters.CalculationID = 'oscDet_001';
            parameters.LogLevel = 'Debug';
            parameters.CalculationName = 'Oscillation Detection';
            testCase.Parameters = parameters;
            testCase.Inputs = inputs;
        end
    end
    methods (Test,ParameterCombination='sequential')
        
        function testNoLogging(testCase,noLoggingInput, noLoggingOutput)
            if isfile(testCase.Parameters.LogName)
                delete(testCase.Parameters.LogName);
            end
            testCase.Parameters.Fs = noLoggingInput;
            outputs = oscillationDetectionNoLog(testCase.Parameters,...
                testCase.Inputs);
            log = isfile(testCase.Parameters.LogName);
            rrCount = outputs.RRCount;
            oscCount = outputs.OscCount;
            testCase.verifyEqual([rrCount,oscCount,log], noLoggingOutput);
        end
        
        function testErrorLogging(testCase, errorInput, errorOutput)
            if isfile(testCase.Parameters.LogName)
                delete(testCase.Parameters.LogName);
            end
            testCase.Parameters.Fs = errorInput;
            outputs = oscillationDetection(testCase.Parameters,...
                testCase.Inputs);
            rrCount = outputs.RRCount;
            oscCount = outputs.OscCount;
            
            fid = fopen(testCase.Parameters.LogName,'r');
            tline = fgetl(fid);
            tlines = cell(0,1);
            while ischar(tline)
                tlines{end+1,1} = tline;
                tline = fgetl(fid);
            end
            fclose(fid);
            
            for i = 1:length(tlines)
                newLog{i,1} = extractAfter(tlines{i}, 17);
            end
            
            testCase.verifyEqual({newLog,[rrCount,oscCount]}, errorOutput);
        end
        
        function testInfoLogging(testCase,infoInput, infoOutput)
            testCase.Parameters.Fs = infoInput;
            if isfile(testCase.Parameters.LogName)
                delete(testCase.Parameters.LogName);
            end
            testCase.Parameters.Fs = infoInput;
            outputs = oscillationDetection(testCase.Parameters,...
                testCase.Inputs);
            rrCount = outputs.RRCount;
            oscCount = outputs.OscCount;
            
           fid = fopen(testCase.Parameters.LogName,'r');
            tline = fgetl(fid);
            tlines = cell(0,1);
            while ischar(tline)
                tlines{end+1,1} = tline;
                tline = fgetl(fid);
            end
            fclose(fid);
            
            for i = 1:length(tlines)
                newLog{i,1} = extractAfter(tlines{i}, 17);
            end
            
            testCase.verifyEqual({newLog,[rrCount,oscCount]}, infoOutput);
        end
        
        function testWarningLogging(testCase,warningInput, warningOutput)
            testCase.Parameters.Fs = warningInput;
            if isfile(testCase.Parameters.LogName)
                delete(testCase.Parameters.LogName);
            end
            testCase.Parameters.Fs = warningInput;
            outputs = oscillationDetectionNoLog(testCase.Parameters,...
                testCase.Inputs);
            rrCount = outputs.RRCount;
            oscCount = outputs.OscCount;
            
            fid = fopen(testCase.Parameters.LogName,'r');
            tline = fgetl(fid);
            tlines = cell(0,1);
            while ischar(tline)
                tlines{end+1,1} = tline;
                tline = fgetl(fid);
            end
            fclose(fid);
            
            for i = 1:length(tlines)
                newLog{i,1} = extractAfter(tlines{i}, 17);
            end
            testCase.verifyEqual({newLog,[rrCount,oscCount]}, warningOutput);
        end
        
        function testMsgSeverity(testCase, msgSeverityInput, msgSeverityOutput)
            if isfile(testCase.Parameters.LogName)
                delete(testCase.Parameters.LogName);
            end
            testCase.Parameters.Fs = msgSeverityInput{1};
            testCase.Parameters.LogLevel = msgSeverityInput{2};
            outputs = oscillationDetection(testCase.Parameters,...
                testCase.Inputs);
            rrCount = outputs.RRCount;
            oscCount = outputs.OscCount;
            
            if isfile(testCase.Parameters.LogName)
                fid = fopen(testCase.Parameters.LogName,'r');
                tline = fgetl(fid);
                tlines = cell(0,1);
                while ischar(tline)
                    tlines{end+1,1} = tline;
                    tline = fgetl(fid);
                end
                fclose(fid);
                
                for i = 1:length(tlines)
                    newLog{i,1} = extractAfter(tlines{i}, 17);
                end
            else
                newLog = {''};
            end
            testCase.verifyEqual({newLog{:},[rrCount,oscCount]}, msgSeverityOutput);
        end
        
        function testLogLevel(testCase, logLevelInput, logLevelOutput)
             if isfile(testCase.Parameters.LogName)
                delete(testCase.Parameters.LogName);
            end
            testCase.Parameters.Fs = '900';
            testCase.Parameters.LogLevel = logLevelInput;
            outputs = oscillationDetectionLogLevel(testCase.Parameters,...
                testCase.Inputs);
            rrCount = outputs.RRCount;
            oscCount = outputs.OscCount;
            
            if isfile(testCase.Parameters.LogName)
                fid = fopen(testCase.Parameters.LogName,'r');
                tline = fgetl(fid);
                tlines = cell(0,1);
                while ischar(tline)
                    tlines{end+1,1} = tline;
                    tline = fgetl(fid);
                end
                fclose(fid);
                
                for i = 1:length(tlines)
                    newLog{i,1} = extractAfter(tlines{i}, 25);
                end
            else
                newLog = {''};
            end
            testCase.verifyEqual({newLog{:}}, logLevelOutput);
            
        end
        
    end
end
