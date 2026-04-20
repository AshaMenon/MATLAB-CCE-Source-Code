classdef testBPFStatsOnCCE < matlab.unittest.TestCase
    %Test that BFP stats runs as expected on CCE server using PI AF
    %elements.
    
    properties
        CalcElement
        ElementFolder
        DataConnector
    end


    methods (TestClassSetup)
        function createAndPopulateElement(testCase)
            %Ensure data folder is added to path
            testRootFolder = fileparts(mfilename("fullpath"));
            dataFolder = fullfile(testRootFolder, "..", "..", "..", "data");
            addpath(genpath(dataFolder));

            %Create test element
            connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); %Create wacp connector (default is LetheConversion)
            elementFolder = af.Element.addElementToRoot("TestBpfStats", "Connector", connector); %Note how this is called since it is a static method - ie does not require existing obj

            newElem = elementFolder.addElement("bpfStats2", "Template", 'bpf_stats');
            newElem.createPiPoints("ChildInclusion", true);
            newElem.setAttributeValue(["ExecutionParameters","ExecutionFrequency"], 300);
            newElem.setAttributeValue("CalculationState", "Idle");
            newElem.setAttributeValue("CoordinatorID", 200);
            newElem.setAttributeValue("LastCalculationTime", datetime("01/01/1970 00:00:00", "Format", 'dd/MM/uuuu HH:mm:ss'));
            newElem.setAttributeValue(["InputSensor", "RelativeTimeRange"], "*-30d, *, 1d")

            %Set input values
            dataTbl = readtimetable(fullfile('BPFStatsData1.csv'));
            % parameterTbl = readtable(fullfile('BPFStatsParameters.csv'));

            for iTime = 1:numel(dataTbl.Timestamps)
                % newElem.setAttributeValue
                newElem.setHistoricalAttributeValue("InputSensor", dataTbl.InputSensor(iTime), dataTbl.Timestamps(iTime));
                newElem.setHistoricalAttributeValue(["InputSensor", "quality"], dataTbl.InputSensorQuality(iTime), dataTbl.Timestamps(iTime));
            end

            %Set parameter values - leave as is
            elementFolder.applyAndCheckIn;
            testCase.CalcElement = newElem;
            testCase.ElementFolder = elementFolder;
            testCase.DataConnector = connector;

        end

    end
    methods (TestClassTeardown)
        function deleteElements(testCase)
            testCase.CalcElement.deleteElement;
            testCase.ElementFolder.deleteElement;

        end

    end
    methods (Test)
        function testBPFStatsRunning(testCase)
            %Run single calculation
            calcToRun = cce.Calculation.createSingleCalc(testCase.CalcElement, testCase.DataConnector); %Create calc obj from element
            testLogger = Logger("C:\CCE\calcLogs\testCalcs.log", "testBPF", "testBPF", "Trace"); %optionally specify specific logger
            calcToRun.runSingleCalculation("Logger", testLogger, "CalcTime", datetime(2020, 12, 07)) %Run calc obj

            testCase.CalcElement.applyAndCheckIn;

            %Test that calc ran properly
            lastError = testCase.CalcElement.getAttributeValue("LastError");
            testCase.verifyEqual(lastError, "Good");

        end

    end
end