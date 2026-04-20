classdef Configurator < handle
    % cce.Configurator class that is used to link to the AF configurator
    % element for purposes of writing and reading from the element

    properties
        DataConnector af.AFDataConnector
        ConfiguratorElement af.Element
        ConfiguratorState cce.ConfiguratorState
        LogLevel LogMessageLevel
        LogName string
    end

    methods 
        function obj = Configurator()
            %Creates new data connector from cce.System variables and loads
            %in the configurator element
            
            obj.DataConnector = af.AFDataConnector(cce.System.CalculationServerName, ...
                cce.System.CalculationDBName);

            obj.loadConfigurator()
        end
    end

    methods
        function loadConfigurator(obj)
            % load configurator element, if it doesn't exist then create a
            % new one

            obj.ConfiguratorElement = af.Element.findByTemplate("CCEConfigurator","Connector",obj.DataConnector);

            if isempty(obj.ConfiguratorElement)
                obj.createElement()
            end

            obj.LogLevel = LogMessageLevel(obj.ConfiguratorElement.getAttributeValue(["LogParameters", "LogLevel"]));
            obj.LogName = obj.ConfiguratorElement.getAttributeValue(["LogParameters", "LogName"]);
        end

        function createElement(obj)
            % create a new configurator element in the CCEConfigurator root
            % folder

            elementFolder = af.Element.findByName('CCEConfigurator', 'Connector', obj.DataConnector);

            if isempty(elementFolder)
                elementFolder = af.Element.addElementToRoot("CCEConfigurator","Connector",obj.DataConnector);
            end

            obj.ConfiguratorElement = elementFolder.addElement("CCEConfigurator", "Template", 'CCEConfigurator');
            obj.ConfiguratorElement.createPiPoints;
            obj.ConfiguratorElement.applyAndCheckIn;

            obj.DataConnector.refreshAFDbCache
        end

        function comit(obj)
            % comits changes to the ConfiguratorState to the AF element

            obj.ConfiguratorElement.setAttributeValue("ConfiguratorState", obj.ConfiguratorState)
            obj.DataConnector.refreshAFDbCache
        end
    end

    methods % setters and getters
        function set.ConfiguratorState(obj, val)
            % update value of the ConfiguratorState if val is invalid then
            % default to NotRunning

            if isnan(val) || isempty(val)
                val = cce.ConfiguratorState.NotRunning;
            end

            obj.ConfiguratorState = val;
            obj.comit()
        end
    end
end