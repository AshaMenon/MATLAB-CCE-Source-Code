classdef BPFStatsTests < matlab.unittest.TestCase
    
    properties
        Parameters
    end
    
    properties(TestParameter)
        input = {{'BPFStatsData1.csv'}; {'BPFStatsData2.csv'}; {'BPFStatsData3.csv'}}
        expectedOutput = {{'BPFStatsOutputs1.csv'}; {'BPFStatsOutputs2.csv'}; {'BPFStatsOutputs3.csv'}}
    end
    
    methods (TestMethodSetup)
        function  setup(testCase)
            %addpath(genpath('..\..\..\calculationSupport\python\pythonDeployFolder'))
            run(fullfile('..','..','..','calculationSupport','calculations','python','setupPythonCalcs.m'))
        end
        
        function setProps(testCase)
            % Load Data & Parameters
            parameterTbl = readtable(fullfile('..','..','..','data','BPFStatsParameters.csv'));
            parameters.LogName = parameterTbl.LogName{:};
            parameters.CalculationID =  parameterTbl.CalculationID{:};
            parameters.LogLevel =  parameterTbl.LogLevel;
            parameters.CalculationName =  parameterTbl.CalculationName{:};
            
            parameters.InputSensorC80 = parameterTbl.C80;
            parameters.InputSensorP75 = parameterTbl.P75;
            parameters.InputSensorUCL = parameterTbl.UCL;
            parameters.InputSensorLCL = parameterTbl.LCL;
            parameters.RunRule = parameterTbl.RunRule;
            parameters.ZeroPoints = parameterTbl.ZeroPoints;
            parameters.Inverse = parameterTbl.Inverse;
            parameters.ExcludeData = parameterTbl.ExcludeData;
            parameters.DateAsMatlab = parameterTbl.DateAsMatlab;
            parameters.DateAsJS = parameterTbl.DateAsJS;
            parameters.InputSensorSensorType = parameterTbl.SensorType{:};
            parameters.InputSensorTrendHigh = parameterTbl.TrendHigh;
            parameters.InputSensorTrendLow = parameterTbl.TrendLow;
            parameters.InputSensorSensorHigh = parameterTbl.SensorHigh;
            parameters.InputSensorSensorLow = parameterTbl.SensorLow;
            parameters.StandardStd = parameterTbl.StandardStd;
            testCase.Parameters = parameters;
            warning off
            
             % Get absolute path of the deployment folder
             filePath = which('BPFstatsFcnCCE.py');
             filePath = erase(filePath,'\BPFstatsFcnCCE.py');
             
             % Add this path to the Python Search Path
             if count(py.sys.path,filePath) == 0
                 insert(py.sys.path,int32(0),filePath);
             end
             
             loggerPath = fullfile('..','..','..','cce/pythonLogger');
             
             % Add this path to the Python Search Path
             if count(py.sys.path,loggerPath) == 0
                 insert(py.sys.path,int32(0),loggerPath);
             end
        end
    end
    methods (Test,ParameterCombination='sequential')
        function testBPFStats(testCase, input, expectedOutput)
            dataTbl = readtable(fullfile('..','..','..','data',input{:}));
            outputTbl = readtable(fullfile('..','..','..','data',expectedOutput{:}));
            inputs.InputSensor = dataTbl.InputSensor;
            inputs.InputSensorTimestamps = dataTbl.Timestamps;
            inputs.InputSensorQuality = dataTbl.InputSensorQuality;
            
            [outputs, errorCode] = bpf_stats(testCase.Parameters,inputs);
            testCase.verifyEqual([outputs.UCL(1), outputs.LCL(1), outputs.EstStdev(1),...
                outputs.Mean(1), outputs.C80(1), outputs.P75(1), errorCode],[outputTbl.UCL,...
                outputTbl.LCL, outputTbl.estStdev, outputTbl.Mean,...
                outputTbl.C80, outputTbl.P75, 305], 'AbsTol',1e-11);
        end
        
        function testBPFStatsCalcServer(testCase, input, expectedOutput)
            dataTbl = readtable(fullfile('..','..','..','data',input{:}));
            outputTbl = readtable(fullfile('..','..','..','data',expectedOutput{:}));
            inputs.InputSensor = dataTbl.InputSensor;
            inputs.InputSensorTimestamps = dataTbl.Timestamps;
            inputs.InputSensorQuality = dataTbl.InputSensorQuality;
            
            hostName = 'ons-mps:9920';
            archive = 'bpf_stats';
            functionName = 'bpf_stats';
            functionInputs = {testCase.Parameters,inputs};
            
            numOfOutputs = 2;
            result = callMLProdServer(hostName,archive,...
                functionName, functionInputs, numOfOutputs);
            
            outputs = result.lhs(1).mwdata;
            errorCode = result.lhs(2).mwdata;
            outputFields = fieldnames(outputs);
            for i = 1:length(outputFields)
                if isa(outputs.(outputFields{i}).mwdata, 'cell')
                    outputs.(outputFields{i}).mwdata = outputs.(outputFields{i}).mwdata{:};
                    if outputs.(outputFields{i}).mwdata == 'NaN'
                        outputs.(outputFields{i}).mwdata = nan;
                    end
                end
            end

            testCase.verifyEqual([outputs.UCL.mwdata(1), outputs.LCL.mwdata(1),...
                outputs.EstStdev.mwdata(1), outputs.Mean.mwdata(1),...
                outputs.C80.mwdata(1), outputs.P75.mwdata(1), errorCode],[outputTbl.UCL,...
                outputTbl.LCL, outputTbl.estStdev, outputTbl.Mean,...
                outputTbl.C80, outputTbl.P75, 305], 'AbsTol',1e-11); 
            
        end
    end
end