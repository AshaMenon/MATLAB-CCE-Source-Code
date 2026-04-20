classdef APCQuantExpressionTests < matlab.unittest.TestCase
    
    properties
        DataTbl
        Parameters
    end
     properties (TestParameter)
         originalInput = {'APCQuantExpressionINPUT.mat'}
         originalOutput = {'APCQuantExpressionOUTPUT.mat'}
     end
    
    methods (TestMethodSetup)
        function  setup(testCase)
            addpath(genpath('..\..\..\cce\calculationEventLog'))
            addpath(genpath('..\..\..\calculationSupport\derivedCalculations'))
            addpath(genpath('..\..\..\data\derivedCalcsMatFiles'))
            run(fullfile('..','..','..','calculationSupport','calculations','derivedCalculations','setupDerivedCalcs.m'))
        end
        
        function setProps(testCase)
            % Load Data & Parameters
            testCase.DataTbl = readtimetable(fullfile('..','..','..','data','apcQuantExpression_Data.csv'));
            parameterTbl = readtable(fullfile('..','..','..','data','apcQuantExpression_Parameters.csv'));
            parameters.LogName = "APCCalculationLog";
            parameters.CalculationName = "APC Quant Expression";
            parameters.CalculationID = "APC_001";
            parameters.LogLevel = parameterTbl.LogLevel;
            parameters.DerivedSensorClass = parameterTbl.DerivedSensorClass{:};
            parameters.DerivedSensorEU = parameterTbl.DerivedSensorEU;
            parameters.DerivedSensorSG = parameterTbl.DerivedSensorSG;
            parameters.InputSensor1ID = parameterTbl.Sensor1ID{:};
            parameters.InputSensor2ID = parameterTbl.Sensor2ID{:} ;
            parameters.InputSensor3ID = parameterTbl.Sensor3ID{:} ;
            parameters.InputSensor4ID = parameterTbl.Sensor4ID{:} ;
            parameters.InputSensor1Eu = parameterTbl.Sensor1Eu{:};
            parameters.InputSensor1Sg = parameterTbl.Sensor1Sg;
            parameters.InputSensor2Eu = parameterTbl.Sensor2Eu{:};
            parameters.InputSensor2Sg = parameterTbl.Sensor2Sg;
            parameters.InputSensor3Eu = parameterTbl.Sensor3Eu{:};
            parameters.InputSensor3Sg = parameterTbl.Sensor3Sg;
            parameters.InputSensor4Eu = parameterTbl.Sensor4Eu{:};
            parameters.InputSensor4Sg = parameterTbl.Sensor4Sg;
            parameters.Expression = parameterTbl.Expression1{:};
            testCase.Parameters = parameters;
            warning off
        end
    end
    methods (Test)
        function testAPCQuantExpression(testCase)
            %numOfRows = length(testCase.DataTbl.Timestamps);
            numOfRows = 500;
            dVal = zeros(numOfRows,1);
            dQual = zeros(numOfRows,1);
            for i = 1:numOfRows
                inputs.InputSensor1 = testCase.DataTbl.Sensor1Value(i);
                inputs.InputSensor1Quality = testCase.DataTbl.Sensor1Quality(i);
                inputs.InputSensor1Timestamps = testCase.DataTbl.Timestamps(i);
                inputs.InputSensor1Active = testCase.DataTbl.Sensor1Active(i);
                inputs.InputSensor1Condition = testCase.DataTbl.Sensor1Condition(i);
                
                inputs.InputSensor2 = testCase.DataTbl.Sensor2Value(i);
                inputs.InputSensor2Quality = testCase.DataTbl.Sensor2Quality(i);
                inputs.InputSensor2Timestamps = testCase.DataTbl.Timestamps(i);
                inputs.InputSensor2Active = testCase.DataTbl.Sensor2Active(i);
                inputs.InputSensor2Condition = testCase.DataTbl.Sensor2Condition(i);
                
                inputs.InputSensor3 = testCase.DataTbl.Sensor3Value(i);
                inputs.InputSensor3Quality = testCase.DataTbl.Sensor3Quality(i);
                inputs.InputSensor3Timestamps = testCase.DataTbl.Timestamps(i);
                inputs.InputSensor3Active = testCase.DataTbl.Sensor3Active(i);
                inputs.InputSensor3Condition = testCase.DataTbl.Sensor3Condition(i);
                
                inputs.InputSensor4 = testCase.DataTbl.Sensor4Value(i);
                inputs.InputSensor4Quality = testCase.DataTbl.Sensor4Quality(i);
                inputs.InputSensor4Timestamps = testCase.DataTbl.Timestamps(i);
                inputs.InputSensor4Active = testCase.DataTbl.Sensor4Active(i);
                inputs.InputSensor4Condition = testCase.DataTbl.Sensor4Condition(i);
                
                [outputs, ~] = apcQuantExpression(testCase.Parameters,...
                    inputs);
                dVal(i) = outputs.DerivedSensor;
                dQual(i) = outputs.DerivedSensorQuality;
            end
            actualDDVal = testCase.DataTbl.DDVal;
            actualDDQual = testCase.DataTbl.DDQual;
            testCase.verifyEqual({dVal, dQual},...
                {actualDDVal(1:numOfRows,:),actualDDQual(1:numOfRows,:)}, 'AbsTol',1e-5);
        end
        
        function testAPCQuantExpressionCalcServer(testCase)
            %numOfRows = length(testCase.DataTbl.Timestamps);
            numOfRows = 100;
            dVal = zeros(numOfRows,1);
            dQual = zeros(numOfRows,1);
            errorCode = zeros(numOfRows,1);
            actualErrorCode = ones(numOfRows,1) * double(cce.CalculationErrorState.Good);
            hostName = 'ons-mps:9920';
            archive = 'derivedCalcs';
            functionName = 'apcQuantExpression';
            numOfOutputs = 2;
            
            for i = 1:numOfRows
                inputs.InputSensor1 = testCase.DataTbl.Sensor1Value(i);
                inputs.InputSensor1Quality = testCase.DataTbl.Sensor1Quality(i);
                inputs.InputSensor1Timestamps = testCase.DataTbl.Timestamps(i);
                inputs.InputSensor1Active = testCase.DataTbl.Sensor1Active(i);
                inputs.InputSensor1Condition = testCase.DataTbl.Sensor1Condition(i);
                
                inputs.InputSensor2 = testCase.DataTbl.Sensor2Value(i);
                inputs.InputSensor2Quality = testCase.DataTbl.Sensor2Quality(i);
                inputs.InputSensor2Timestamps = testCase.DataTbl.Timestamps(i);
                inputs.InputSensor2Active = testCase.DataTbl.Sensor2Active(i);
                inputs.InputSensor2Condition = testCase.DataTbl.Sensor2Condition(i);
                
                inputs.InputSensor3 = testCase.DataTbl.Sensor3Value(i);
                inputs.InputSensor3Quality = testCase.DataTbl.Sensor3Quality(i);
                inputs.InputSensor3Timestamps = testCase.DataTbl.Timestamps(i);
                inputs.InputSensor3Active = testCase.DataTbl.Sensor3Active(i);
                inputs.InputSensor3Condition = testCase.DataTbl.Sensor3Condition(i);
                
                inputs.InputSensor4 = testCase.DataTbl.Sensor4Value(i);
                inputs.InputSensor4Quality = testCase.DataTbl.Sensor4Quality(i);
                inputs.InputSensor4Timestamps = testCase.DataTbl.Timestamps(i);
                inputs.InputSensor4Active = testCase.DataTbl.Sensor4Active(i);
                inputs.InputSensor4Condition = testCase.DataTbl.Sensor4Condition(i);
                
                functionInputs = {testCase.Parameters,inputs};
                result = callMLProdServer(hostName,archive,...
                    functionName, functionInputs, numOfOutputs);
                outputs = result.lhs(1).mwdata;
                errorCode(i) = result.lhs(2).mwdata;
                dVal(i) = outputs.DerivedSensor.mwdata;
                dQual(i) = outputs.DerivedSensorQuality.mwdata;
            end
            actualDDVal = testCase.DataTbl.DDVal;
            actualDDQual = testCase.DataTbl.DDQual;
            testCase.verifyEqual({dVal, dQual, errorCode},...
                {actualDDVal(1:numOfRows,:),actualDDQual(1:numOfRows,:),...
                actualErrorCode}, 'AbsTol',1e-5);
        end
        
        function testOriginalAPCQuantExpression(testCase, originalInput,...
                originalOutput)
            load(originalInput, 'varargin');
            load(originalOutput, 'dVal','dTime','dQual');
            [val, qual, time] = APCQuantExpressionUpdated(varargin{:});
            testCase.verifyEqual([val, qual, time], [dVal, dQual, dTime]);
            
        end
    end
end
