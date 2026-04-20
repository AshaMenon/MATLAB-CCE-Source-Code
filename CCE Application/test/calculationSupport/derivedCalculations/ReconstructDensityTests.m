classdef ReconstructDensityTests < matlab.unittest.TestCase
    
    properties
        DataTbl
        Parameters
    end
    
    methods (TestMethodSetup)
        function  setup(testCase)
            addpath(genpath('..\..\..\cce\calculationEventLog'))
            run(fullfile('..','..','..','calculationSupport','calculations','derivedCalculations','setupDerivedCalcs.m'))
        end
        
        function setProps(testCase)
            % Load Data & Parameters
            testCase.DataTbl = readtimetable(fullfile('..','..','..','data','reconstructDensity_Data.csv'));
            parameterTbl = readtable(fullfile('..','..','..','data','reconstructDensity_Parameters.csv'));
            parameters.LogName = parameterTbl.LogName{:};
            parameters.CalculationID =  parameterTbl.CalculationID{:};
            parameters.LogLevel =  parameterTbl.LogLevel;
            parameters.CalculationName =  parameterTbl.CalculationName{:};
            parameters.K1 = parameterTbl.K1;
            parameters.K2 = parameterTbl.K2;
            parameters.K3 = parameterTbl.K3;
            parameters.K4 = parameterTbl.K4;
            testCase.Parameters = parameters;
            warning off
        end
    end
    methods (Test)
        function testReconstructDensity(testCase)
            %numOfRows = length(testCase.DataTbl.Timestamps);
            numOfRows = 100;
            dDVal = zeros(numOfRows,1);
            dDQual = zeros(numOfRows,1);
            for i = 1:numOfRows
                inputs.SolidsFeed = testCase.DataTbl.SolidsFeed(i);
                inputs.SolidsFeedTimestamps = testCase.DataTbl.Timestamps(i);
                inputs.SolidsFeedQuality = testCase.DataTbl.SolidsFeedQuality(i);
                inputs.WaterFeed = testCase.DataTbl.WaterFeed(i);
                inputs.WaterFeedTimestamps = testCase.DataTbl.Timestamps(i);
                inputs.WaterFeedQuality = testCase.DataTbl.WaterFeedQuality(i);
                [outputs, ~] = reconstructDensity(testCase.Parameters,...
                    inputs);
                dDVal(i) = outputs.DerivedSensor;
                dDQual(i) = outputs.DerivedSensorQuality;
            end
            actualDDVal = testCase.DataTbl.DDVal;
            actualDDQual = testCase.DataTbl.DDQual;
            testCase.verifyEqual({dDVal, dDQual},...
                {actualDDVal(1:numOfRows,:),actualDDQual(1:numOfRows,:)}, 'AbsTol',1e-14);
        end
        
        function testReconstructDensityCalcServer(testCase)
            %numOfRows = length(testCase.DataTbl.Timestamps);
            numOfRows = 100;
            dDVal = zeros(numOfRows,1);
            dDQual = zeros(numOfRows,1);
            errorCode = zeros(numOfRows,1);
            actualErrorCode = ones(numOfRows,1) * double(cce.CalculationErrorState.Good);
            hostName = 'ons-mps:9920';
            archive = 'derivedCalcs';
            functionName = 'reconstructDensity';
            numOfOutputs = 2;

            for i = 1:numOfRows
                inputs.SolidsFeed = testCase.DataTbl.SolidsFeed(i);
                inputs.SolidsFeedTimestamps = testCase.DataTbl.Timestamps(i);
                inputs.SolidsFeedQuality = testCase.DataTbl.SolidsFeedQuality(i);
                inputs.WaterFeed = testCase.DataTbl.WaterFeed(i);
                inputs.WaterFeedTimestamps = testCase.DataTbl.Timestamps(i);
                inputs.WaterFeedQuality = testCase.DataTbl.WaterFeedQuality(i);
                functionInputs = {testCase.Parameters,inputs};
                result = callMLProdServer(hostName,archive,...
                    functionName, functionInputs, numOfOutputs);
                outputs = result.lhs(1).mwdata;
                errorCode(i) = result.lhs(2).mwdata;
                dDVal(i) = outputs.DerivedSensor.mwdata;
                dDQual(i) = outputs.DerivedSensorQuality.mwdata;
            end
            actualDDVal = testCase.DataTbl.DDVal;
            actualDDQual = testCase.DataTbl.DDQual;
            testCase.verifyEqual({dDVal, dDQual, errorCode},...
                {actualDDVal(1:numOfRows,:),actualDDQual(1:numOfRows,:),...
                actualErrorCode}, 'AbsTol',1e-14);
        end
    end
end
