classdef tConfiguratorElement < matlab.unittest.TestCase
        
    properties
        DataConnector af.AFDataConnector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
        TestCoordinator af.Element
    end
    
    methods (TestClassSetup)

    end
    
    methods (TestClassTeardown)

    end
    
    methods (Test)
        function tElementCreation(testCase)
            testCase.deleteConfigurator

            cce.Configurator();
            configuratorElement = af.Element.findByTemplate("CCEConfigurator","Connector",testCase.DataConnector);

            testCase.assertNotEmpty(configuratorElement)
        end

        function tConfiguratorState(testCase)
            configuratorObj = cce.Configurator;
            configuratorElement = af.Element.findByTemplate("CCEConfigurator","Connector",testCase.DataConnector);

            newState = "Running";
            configuratorObj.ConfiguratorState = newState;
            testCase.DataConnector.refreshAFDbCache;

            testCase.assertEqual(newState, configuratorElement.getAttributeValue("ConfiguratorState"))

            newState = "NotRunning";
            configuratorObj.ConfiguratorState = newState;
            testCase.DataConnector.refreshAFDbCache;

            testCase.assertEqual(newState, configuratorElement.getAttributeValue("ConfiguratorState"))

            newState = "Failed";
            configuratorObj.ConfiguratorState = newState;
            testCase.DataConnector.refreshAFDbCache;

            testCase.assertEqual(newState, configuratorElement.getAttributeValue("ConfiguratorState"))

            newState = NaN;
            configuratorObj.ConfiguratorState = newState;
            testCase.DataConnector.refreshAFDbCache;

            testCase.assertEqual("NotRunning", configuratorElement.getAttributeValue("ConfiguratorState"))
        end

        function tConfiguratorRun(testCase)
            configuratorObj = cce.Configurator;
            configuratorElement = af.Element.findByTemplate("CCEConfigurator","Connector",testCase.DataConnector);

            configuratorObj.ConfiguratorState = "Running";

            cceConfigurator
            testCase.DataConnector.refreshAFDbCache;

            testCase.assertEqual("NotRunning", configuratorElement.getAttributeValue("ConfiguratorState"))
        end

        function tConfiguratorFailedRun(testCase)
            configuratorObj = cce.Configurator;
            configuratorElement = af.Element.findByTemplate("CCEConfigurator","Connector",testCase.DataConnector);

            configuratorObj.ConfiguratorState = "Running";

            testCase.createTestCoord % Create a coordinator that would cause the configurator to fail
            cceConfigurator
            testCase.DataConnector.refreshAFDbCache;

            testCase.assertEqual("Failed", configuratorElement.getAttributeValue("ConfiguratorState"))
            testCase.TestCoordinator.deleteElement
        end

        function tLogParameters(testCase)
            
            configuratorElement = af.Element.findByTemplate("CCEConfigurator","Connector",testCase.DataConnector);

            if isempty(configuratorElement)
                configuratorElement = elementFolder.addElement("CCEConfigurator", "Template", 'CCEConfigurator');
                configuratorElement.createPiPoints;
                configuratorElement.applyAndCheckIn;

                testCase.DataConnector.refreshAFDbCache
            end

            logLevel = "All";
            logName = "test.log";
            configuratorElement.setAttributeValue(["LogParameters", "LogLevel"], logLevel)
            configuratorElement.setAttributeValue(["LogParameters", "LogName"], logName)
            testCase.DataConnector.refreshAFDbCache;

            configuratorObj = cce.Configurator;

            testCase.assertEqual(configuratorObj.LogLevel, LogMessageLevel(logLevel))
            testCase.assertEqual(configuratorObj.LogName, logName)

            testCase.deleteConfigurator
        end
    end

    methods
        function deleteConfigurator(obj)
            configuratorElement = af.Element.findByTemplate("CCEConfigurator","Connector",obj.DataConnector);

            if ~isempty(configuratorElement)
                configuratorElement.deleteElement()
            end

            obj.DataConnector.refreshAFDbCache
        end

        function createTestCoord(obj)
            coordFolder = af.Element.findByName('CCECoordinator', 'Connector', obj.DataConnector);
            coordFolder.refresh;
            coordName = "CCECoordinator250";
            obj.TestCoordinator = coordFolder.addElement(coordName, "Template", 'CCECoordinator');
            obj.TestCoordinator.createPiPoints;
            obj.TestCoordinator.setAttributeValue("ExecutionFrequency",0)
            obj.TestCoordinator.setAttributeValue("CoordinatorID", 250);
            obj.TestCoordinator.setAttributeValue("CoordinatorState", "Idle")
            obj.TestCoordinator.setAttributeValue("Lifetime",86400)
            obj.TestCoordinator.setAttributeValue("CalculationLoad",2)
            obj.TestCoordinator.setAttributeValue("ExecutionMode","Manual")
            obj.TestCoordinator.applyAndCheckIn;
        end
    end
end

