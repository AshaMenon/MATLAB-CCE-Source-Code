classdef ComponentArrayTests < matlab.unittest.TestCase
    
    properties
        DataTb1
        DataTb2
        Timesteps
        Parameters
    end
    
    methods (TestMethodSetup)
        function  setup(~)
            testRootFolder = fileparts(mfilename("fullpath"));
            lethePath = fullfile(testRootFolder, '..', '..', '..',...
                'calculationSupport', 'calculations', 'lethe');
            addpath(lethePath);
            setupLetheCalcs;
        end
        
        function setProps(testCase)
            % Load Data & Parameters
            parameters = struct();
            parameters.CalculationName = "Component Array";
            parameters.CalculationID = "CompArr01";
            parameters.LogName = 'data\LetheCalcs\componentArrayLog';
            parameters.LogLevel = 255;
            
            parameters.RollupInputs = ["Assay", "DryMass", "Estimate"];
            parameters.ComponentIsPercent = false;
            parameters.DoRollupAssay = true;
            parameters.DoRollupDry = false;
            parameters.RequireAllAssayInputs = false;
            
            testCase.Parameters = parameters;
            
            
            load('LetheCalcs\compArray\inputTabs.mat', 'dataTab1', 'dataTab2', 'calcDates')
            testCase.DataTb1 = dataTab1;
            testCase.DataTb2 = dataTab2;
            testCase.Timesteps = calcDates;
            warning off
        end
    end
    methods (Test)
        function testCompArray1(testCase)
            %Parameters
            parameters = testCase.Parameters;
            
            %Inputs
            data1 = testCase.DataTb1(1, :);
            inputs = struct();
            inputs.Assay = data1.Assay;
            inputs.Assay_Cr = data1.Assay_Cr;
            inputs.AssayTimestamps = testCase.Timesteps(1);
            
            inputs.DryMass = data1.DryMass;
            inputs.DryMass_Cr = data1.DryMass_Cr;
            inputs.Estimate = NaN;
            
            %Expected outputs
            expectOut.Component = data1.Component;
            expectOut.RollupAssay = data1.RollupAssay;
            expectOut.RollupDry = NaN;
            
            %Run function
            [outputs, ~] = componentArray(parameters,...
                inputs);
            
            expectOutCell = {expectOut.Component,...
                expectOut.RollupAssay,...
                expectOut.RollupDry};
            
            actualOutCell = {empty2nan(outputs.Component),...
                empty2nan(outputs.RollupAssay),...
                empty2nan(outputs.RollupDry)};
            
            testCase.verifyEqual(expectOutCell, actualOutCell, 'RelTol', 1e-6);
        end
        
        function testCompArray2(testCase)
            %Parameters
            parameters = testCase.Parameters;
            
            %Inputs
            data2 = testCase.DataTb2(1, :);
            inputs = struct();
            inputs.Assay = data2.Assay;
            inputs.Assay_Cr = data2.Assay_Cr;
            inputs.AssayTimestamps = testCase.Timesteps(1);
            
            inputs.DryMass = data2.DryMass;
            inputs.DryMass_Cr = data2.DryMass_Cr;
            inputs.Estimate = NaN;
            
            %Expected outputs
            expectOut.Component = data2.Component;
            expectOut.RollupAssay = data2.RollupAssay;
            expectOut.RollupDry = NaN;
            
            %Run function
            [outputs, ~] = componentArray(parameters,...
                inputs);
            
            expectOutCell = {expectOut.Component,...
                expectOut.RollupAssay,...
                expectOut.RollupDry};
            
            actualOutCell = {empty2nan(outputs.Component),...
                empty2nan(outputs.RollupAssay),...
                empty2nan(outputs.RollupDry)};
            
            testCase.verifyEqual(expectOutCell, actualOutCell, 'RelTol', 1e-6);
        end
        
        function testCompArrayCalcServer(testCase)
            numTimes = 1;
            errorCode = zeros(numTimes, 1);
            expectedErrorCode = ones(numTimes, 1) * double(cce.CalculationErrorState.Good);
            
            component_val = nan(numTimes, 1);
            rollupAssay_val = nan(numTimes, 1);
            rollupDry_val = nan(numTimes, 1);
            
            hostName = 'ons-opcdev:9910';
            archive = 'componentArray';
            functionName = 'componentArray';
            numOfOutputs = 2;
            
            %Parameters
            parameters = testCase.Parameters;
            
            
            %Inputs
            data2 = testCase.DataTb2(5, :);
            Assay = data2.Assay;
            Assay_Cr = data2.Assay_Cr;
            AssayTimestamps = testCase.Timesteps(5);
            
            DryMass = data2.DryMass;
            DryMass_Cr = data2.DryMass_Cr;
            
            for iTimeStamp = 1:numTimes
                %Inputs
                inputs = struct();
                inputs.Assay = Assay(iTimeStamp);
                inputs.Assay_Cr = Assay_Cr(iTimeStamp);
                inputs.AssayTimestamps = AssayTimestamps(iTimeStamp);
                
                inputs.DryMass = DryMass(iTimeStamp);
                inputs.DryMass_Cr = DryMass_Cr(iTimeStamp);
                inputs.Estimate = NaN;
                
                %Expected outputs
                functionInputs = {parameters, inputs};
                
                result = callMLProdServer(hostName, archive,...
                    functionName, functionInputs, numOfOutputs);
                
                outputs = result.lhs(1).mwdata;
                errorCode(iTimeStamp) = result.lhs(2).mwdata;
                component_val(iTimeStamp) = empty2nan(outputs.Component.mwdata);
                rollupAssay_val(iTimeStamp) = empty2nan(outputs.RollupAssay.mwdata);
                rollupDry_val(iTimeStamp) = empty2nan(outputs.RollupDry.mwdata);
            end
            
            expectOut = struct();
            %Expected outputs
            expectOut.Component = data2.Component;
            expectOut.RollupAssay = data2.RollupAssay;
            expectOut.RollupDry = nan(numTimes, 1);
            
            
            expectOutCell = {expectOut.Component',...
                expectOut.RollupAssay',...
                expectOut.RollupDry',...
                expectedErrorCode};
            
            actualOutCell = {component_val,...
                rollupAssay_val,...
                rollupDry_val,...
                errorCode};
            
            testCase.verifyEqual(expectOutCell,...
                actualOutCell, 'RelTol', 1e-6);
        end
        
    end
end
