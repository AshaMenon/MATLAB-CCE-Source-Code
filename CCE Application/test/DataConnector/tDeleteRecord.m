classdef tDeleteRecord < matlab.unittest.TestCase

    %tDeleteRecord tests record removal in AFDataConnector. Created to find bug
    %on prod 2024/01/15. Currently doesn't do value comparison.



    properties
        ElementFolder
        Connector
    end

    methods (TestClassSetup)

        function createTestElementFolder(testCase)
            testCase.Connector = af.AFDataConnector("ons-opcdev.optinum.local", "wacp"); %Create wacp connector (default is LetheConversion)
            testCase.ElementFolder = af.Element.addElementToRoot("ProgrammaticallyCreated", "Connector", testCase.Connector); %Note how this is called since it is a static method - ie does not require existing obj
        end

    end

    methods (TestClassTeardown)
        function teardown(testCase)
            testCase.ElementFolder.deleteElement;
        end
    end

    methods (Test)
        function tDeleteRecordWithoutHistory(testCase)
            %tMissingComponent creates a test element with an incorrect ComponentName,
            % to cause an unhandledException and corresponding coordinator

            newElem1 = testCase.ElementFolder.addElement("failedInputTest1", "Template", 'sensorAdd');
            newElem1.createPiPoints;

            field = testCase.Connector.getFieldByName(newElem1.NetElement, "SensorReference");
            timeRange = ["01-01-2020 00:00:00 - 2h"; "01-01-2020 00:00:00"];
            testCase.Connector.removeFieldRecordedHistory(field, timeRange)
        end

        function tDeleteFromMissingPiPoint(testCase)
            %tMissingComponent creates a test element with an incorrect ComponentName,
            % to cause an unhandledException and corresponding coordinator

            newElem2 = testCase.ElementFolder.addElement("failedInputTest2", "Template", 'sensorAdd');

            field = testCase.Connector.getFieldByName(newElem2.NetElement, "SensorReference");
            timeRange = ["01-01-2020 00:00:00 - 2h"; "01-01-2020 00:00:00"];
            testCase.Connector.removeFieldRecordedHistory(field, timeRange)
        end

        function testWrittenValuesRemoval(testCase)
            %tMissingComponent creates a test element with an incorrect ComponentName,
            % to cause an unhandledException and corresponding coordinator

            newElem3 = testCase.ElementFolder.addElement("failedInputTest3", "Template", 'sensorAdd');
            newElem3.createPiPoints;
            newElem3.setHistoricalAttributeValue("SensorReference", 15, datetime('now'));
            newElem3.setHistoricalAttributeValue("SensorReference", 16, datetime('now'));
            newElem3.setHistoricalAttributeValue("SensorReference", 17, datetime('now'));

            field = testCase.Connector.getFieldByName(newElem3.NetElement, "SensorReference");
            timeRange = ["*- 2h"; "* + 2h"];
            testCase.Connector.removeFieldRecordedHistory(field, timeRange)
        end

        function testInvalidTimeRange(testCase)
            %tMissingComponent creates a test element with an incorrect ComponentName,
            % to cause an unhandledException and corresponding coordinator

            newElem4 = testCase.ElementFolder.addElement("failedInputTest4", "Template", 'sensorAdd');
            newElem4.createPiPoints;
            newElem4.setHistoricalAttributeValue("SensorReference", 15, datetime('now'));
            newElem4.setHistoricalAttributeValue("SensorReference", 16, datetime('now'));
            newElem4.setHistoricalAttributeValue("SensorReference", 17, datetime('now'));

            field = testCase.Connector.getFieldByName(newElem4.NetElement, "SensorReference");
            timeRange = ["*"; "*-2h"];
            testCase.Connector.removeFieldRecordedHistory(field, timeRange)
        end

    end

end