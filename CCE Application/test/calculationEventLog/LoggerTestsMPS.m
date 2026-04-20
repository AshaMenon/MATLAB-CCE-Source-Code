classdef LoggerTestsMPS < matlab.unittest.TestCase
    
    properties
        Inputs
        Parameters
    end
    
    properties (TestParameter)
        noLoggingInput = {900}
        noLoggingOutput = {[40,31]}
        errorInput = {0;'900'}
        errorOutput = {{'NaN', 'NaN'};{'NaN', 'NaN'}}
        warningInput = {800; 850}
        infoInput = {900}
        infoOutput = {[40, 31]}
        warningOutput = {[46, 37];[37, 28]}
        logLevelInput = {{900, 'None'};{850, 'Info'};{850, 'Debug'}}
        logLevelOutput = {[40,31];[37, 28];[37, 28]}
    end
    methods (TestMethodSetup)
        function  setup(testCase)
            addpath(genpath('..\..\cce\calculationEventLog'))
            addpath(genpath('..\..\calculationSupport\'))
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
            parameters.LogName = 'logFileTest.log';
            parameters.CalculationID = 'oscDet_001';
            parameters.CalculationName = 'Oscillation Detection';
            parameters.LogLevel = 'Debug';
            testCase.Parameters = parameters;
            testCase.Inputs = inputs;
            if isfile(testCase.Parameters.LogName)
                delete(testCase.Parameters.LogName);
            end
        end
    end
    methods (Test,ParameterCombination='sequential')
        
        function testNoLogging(testCase,noLoggingInput, noLoggingOutput)
            testCase.Parameters.Fs = noLoggingInput;
            hostName = 'ons-mps:9920';
            archive = 'oscillationDetectionNoLog';
            functionName = 'oscillationDetectionNoLog';
            inputs = {testCase.Parameters, testCase.Inputs};
            numOfOutputs = 1;
            
            output = callMLProdServer(hostName,archive,...
                functionName, inputs, numOfOutputs);
            
            rrCount = output.lhs.mwdata.RRCount.mwdata;
            oscCount = output.lhs.mwdata.OscCount.mwdata;
            testCase.verifyEqual([rrCount,oscCount], noLoggingOutput);
        end
        
        function testErrorLogging(testCase, errorInput, errorOutput)
            testCase.Parameters.Fs = errorInput;

            hostName = 'ons-mps:9920';
            archive = 'oscillationDetection';
            functionName = 'oscillationDetection';
            inputs = {testCase.Parameters,testCase.Inputs};
            numOfOutputs = 1;
            
            output = callMLProdServer(hostName,archive,...
                functionName, inputs, numOfOutputs);
            
            rrCount = output.lhs.mwdata.RRCount.mwdata;
            oscCount = output.lhs.mwdata.OscCount.mwdata;
            
            testCase.verifyEqual({rrCount{:}, oscCount{:}}, errorOutput);
        end
        
        function testInfoLogging(testCase,infoInput, infoOutput)
            testCase.Parameters.Fs = infoInput;
            hostName = 'ons-mps:9920';
            archive = 'oscillationDetection';
            functionName = 'oscillationDetection';
            inputs = {testCase.Parameters, testCase.Inputs};
            numOfOutputs = 1;
            
            output = callMLProdServer(hostName,archive,...
                functionName, inputs, numOfOutputs);
            
            rrCount = output.lhs.mwdata.RRCount.mwdata;
            oscCount = output.lhs.mwdata.OscCount.mwdata;
            
            testCase.verifyEqual([rrCount,oscCount], infoOutput);
        end
        
        function testWarningLogging(testCase,warningInput, warningOutput)
            testCase.Parameters.Fs = warningInput;
             hostName = 'ons-mps:9920';
            archive = 'oscillationDetectionNoLog';
            functionName = 'oscillationDetectionNoLog';
            inputs = {testCase.Parameters, testCase.Inputs};
            numOfOutputs = 1;
            
            output = callMLProdServer(hostName,archive,...
                functionName, inputs, numOfOutputs);
            
            rrCount = output.lhs.mwdata.RRCount.mwdata;
            oscCount = output.lhs.mwdata.OscCount.mwdata;
            testCase.verifyEqual([rrCount,oscCount], warningOutput);
        end
        
        function testLogLevel(testCase, logLevelInput, logLevelOutput)
            testCase.Parameters.Fs = logLevelInput{1};
            testCase.Parameters.LogLevel = logLevelInput{2};
            hostName = 'ons-mps:9920';
            archive = 'oscillationDetection';
            functionName = 'oscillationDetection';
            inputs = {testCase.Parameters, testCase.Inputs};
            numOfOutputs = 1;
            
            output = callMLProdServer(hostName,archive,...
                functionName, inputs, numOfOutputs);
            
            rrCount = output.lhs.mwdata.RRCount.mwdata;
            oscCount = output.lhs.mwdata.OscCount.mwdata;
            testCase.verifyEqual([rrCount,oscCount], logLevelOutput);
        end
    end
end
