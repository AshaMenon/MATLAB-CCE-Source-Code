classdef DependentCalcTests < matlab.unittest.TestCase
    
    properties
        DataTbl
        Parameters
    end
    properties (TestParameter)
        sensorAddInputs = {{25, 5, datetime(2021,08,24,16,10,30)}; {60, 10, datetime(2021,08,24,16,10,10)}; {10, 12, datetime(2021,08,24,16,10,05)}}
        sensorAddOutputs = {{30, datetime(2021,08,24,16,10,30)};...
              {70, datetime(2021,08,24,16,10,10)};...
              {22, datetime(2021,08,24,16,10,05)}}
        depAddInputs = {{datetime(2021,08,24,16,10,00),10, 20};...
            {datetime(2021,08,24,16,10,00),10, 20, 30};...
            {[datetime(2021,08,24,16,10,00),datetime(2021,08,24,16,10,10)],[10, 20], [20, 30]}};
        depAddOutputs = {{30, datetime(2021,08,24,16,10,00)};...
            {60, datetime(2021,08,24,16,10,00)};...
            {[30, 50], [datetime(2021,08,24,16,10,00),datetime(2021,08,24,16,10,10)]}}
    end
    methods (TestMethodSetup)
        function  setup(testCase)
            addpath(genpath('..\..\..\cce\util\logger'))
            addpath(genpath('..\..\..\calculationSupport\calculations\dependentCalculations'))
        end
        
        function setProps(testCase)
            % Load Parameters
            testCase.Parameters.LogName = 'dependentCalcs';
            testCase.Parameters.LogLevel = 4;
            warning off
        end
    end
    methods (Test,ParameterCombination='sequential')
        function testSensorAdd(testCase, sensorAddInputs, sensorAddOutputs)
            testCase.Parameters.CalculationID = 'senAdd001';
            testCase.Parameters.CalculationName = 'Sensor Add';
            testCase.Parameters.Constant = sensorAddInputs{2};
            testCase.Parameters.OutputTime = sensorAddInputs{3};
            inputs.SensorReference = sensorAddInputs{1};
            inputs.SensorReferenceTimestamps = datetime(2021,08,24,16,10,00);
            [outputs, errorCode] = sensorAdd(testCase.Parameters,inputs);
            sensorAddOutputs{3} = uint32(cce.CalculationErrorState.Good);
            testCase.verifyEqual({outputs.OutputSensor, outputs.Timestamp,...
                errorCode}, sensorAddOutputs);
        end
        
        function testDepAdd(testCase, depAddInputs, depAddOutputs)
            testCase.Parameters.CalculationID = 'depAdd001';
            testCase.Parameters.CalculationName = 'Dependent Add';
            sensorNum = length(depAddInputs)- 1;
            for i = 1:sensorNum
                inputs.(sprintf('Sensor%d', i)) = depAddInputs{1+i};
            end
                
            inputs.Sensor1Timestamps = depAddInputs{1};
            [outputs, errorCode] = dependentAdd(testCase.Parameters,inputs);
            depAddOutputs{3} = uint32(cce.CalculationErrorState.Good);
            testCase.verifyEqual({outputs.OutputSensor, outputs.Timestamp,...
                errorCode}, depAddOutputs);
        end
        
        function testSensorAddMPS(testCase, sensorAddInputs, sensorAddOutputs)
            hostName = 'ons-mps:9920';
            archive = 'dependentCalcs';
            functionName = 'sensorAdd';
            numOfOutputs = 2;
            testCase.Parameters.CalculationID = 'senAdd001';
            testCase.Parameters.CalculationName = 'Sensor Add';
            testCase.Parameters.Constant = sensorAddInputs{2};
            testCase.Parameters.OutputTime = sensorAddInputs{3};
            inputs.SensorReference = sensorAddInputs{1};
            inputs.SensorReferenceTimestamps = datetime(2021,08,24,16,10,00);
            functionInputs = {testCase.Parameters,inputs};
            result = callMLProdServer(hostName,archive,...
                    functionName, functionInputs, numOfOutputs);
            outputs = result.lhs(1).mwdata;
            errorCode = result.lhs(2).mwdata; 
            outputSensor = outputs.OutputSensor.mwdata;
            timestamp = datetime(outputs.Timestamp.mwdata.TimeStamp.mwdata/1000,'convertFrom', 'posixtime');
            sensorAddOutputs{3} = double(cce.CalculationErrorState.Good);
            testCase.verifyEqual({outputSensor, timestamp, errorCode},...
               sensorAddOutputs);
        end
       
         function testDepAddMPS(testCase, depAddInputs, depAddOutputs)
            hostName = 'ons-mps:9920';
            archive = 'dependentCalcs';
            functionName = 'dependentAdd';
            numOfOutputs = 2;
            testCase.Parameters.CalculationID = 'depAdd001';
            testCase.Parameters.CalculationName = 'Dependent Add';
            sensorNum = length(depAddInputs)- 1;
            for i = 1:sensorNum
                inputs.(sprintf('Sensor%d', i)) = depAddInputs{1+i};
            end
                
            inputs.Sensor1Timestamps = depAddInputs{1};
            functionInputs = {testCase.Parameters,inputs};
            result = callMLProdServer(hostName,archive,...
                    functionName, functionInputs, numOfOutputs);
            outputs = result.lhs(1).mwdata;
            errorCode = result.lhs(2).mwdata; 
            outputSensor = outputs.OutputSensor.mwdata;
            depAddOutputs{3} = double(cce.CalculationErrorState.Good);
            timestamp = datetime(outputs.Timestamp.mwdata.TimeStamp.mwdata/1000,'convertFrom', 'posixtime');
            testCase.verifyEqual({outputSensor', timestamp', errorCode},...
               depAddOutputs);
        end
        
    end
end
