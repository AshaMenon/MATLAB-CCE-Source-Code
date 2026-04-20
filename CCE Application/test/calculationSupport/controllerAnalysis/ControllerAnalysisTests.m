classdef ControllerAnalysisTests < matlab.unittest.TestCase
    
    properties
        DataTbl
        Parameters
    end
    properties (TestParameter)
        inputs = readcell(fullfile('..','..','..','data','sensorList.xlsx'))
        errorCodeInputs = {'criticalSensorError1.mat'; 
            'criticalSensorError2.mat';
            'criticalSensorError3.mat';
            'qualityError1.mat';
            'qualityError2.mat';
            'typeError1.mat';
            'typeError2.mat';
            'unhandledError.mat'}
        errorCodeOutputs = {uint32(cce.CalculationErrorState.NoData);
            uint32(cce.CalculationErrorState.NoData);
            uint32(cce.CalculationErrorState.NoData);
            uint32(cce.CalculationErrorState.NoData);
            uint32(cce.CalculationErrorState.NoData);
            uint32(cce.CalculationErrorState.BadInput);
            uint32(cce.CalculationErrorState.BadInput);
            uint32(cce.CalculationErrorState.CalcFailed)}
    end
    methods (TestMethodSetup)
        function  setup(testCase)
            addpath(genpath('..\..\..\cce\util\logger'))
            addpath(genpath('..\..\..\data'))
            run(fullfile('..','..','..','calculationSupport','calculations','matlabAnalysis','setupMatlabAnalysisCalcs.m'))
%             addpath(fullfile('..','..','..','calculationSupport', 'matlabAnalysis',...
%             'controllerPlotFcn'))
%             addpath(fullfile('..','..','..','calculationSupport', 'derivedCalculations'))
        end
    end
    methods (Test,ParameterCombination='sequential')
        function testControllerAnalysis(testCase, inputs)
            filenames = {[inputs,'_Data.csv'],...
                [inputs,'_Attributes.csv'],[inputs,'_Parameters.csv']};
            startRange = datetime(2020,12,13,1,0,0);
            endRange = startRange + hours(1);
            timerange = [startRange, endRange];
            [parameters,inputs, actualQuality,...
                actualRootCause] =...
                controllerAnalysisMockInterface(filenames, timerange);
            
            % Call Calculation
            [outputs, errorCode] = controllerAnalysis(parameters, inputs);
            controllerQuality = outputs.ControllerQuality;
            rootCause = outputs.RootCause;
            
            testCase.verifyEqual({controllerQuality, rootCause, errorCode},...
                {actualQuality, actualRootCause, uint32(cce.CalculationErrorState.Good)});
        end
        
        function testErrorCodes(testCase, errorCodeInputs, errorCodeOutputs)
            load(errorCodeInputs)
            [outputs, errorCode] = controllerAnalysis(parameters,inputs);
            
            testCase.verifyEqual(errorCode, errorCodeOutputs);
        end
        
        function testControllerAnalysisCalcServer(testCase, inputs)
             filenames = {[inputs,'_Data.csv'],...
                [inputs,'_Attributes.csv'],[inputs,'_Parameters.csv']};
            startRange = datetime(2020,12,13,1,0,0);
            endRange = startRange + hours(1);
            timerange = [startRange, endRange];
            [parameters,inputStruct, actualQuality,...
                actualRootCause] =...
                controllerAnalysisMockInterface(filenames, timerange);
            hostName = 'ons-mps:9920';
            archive = 'controllerAnalysis';
            functionName = 'controllerAnalysis';
        
            numOfOutputs = 2;
            inputs = {parameters,inputStruct};
            % Call Calculation
            result = callMLProdServer(hostName,archive,...
                functionName, inputs, numOfOutputs);
            output = result.lhs(1).mwdata;
            errorCode = result.lhs(2).mwdata;
            controllerQuality = output.ControllerQuality.mwdata;
            rootCause = output.RootCause.mwdata;
            
            testCase.verifyEqual({controllerQuality, rootCause, errorCode},...
                {actualQuality, actualRootCause, cce.CalculationErrorState.Good});
        end
        
    end
end
        
      
