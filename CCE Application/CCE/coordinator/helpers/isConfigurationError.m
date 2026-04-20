function isConfigErr = isConfigurationError(errMsg)
    persistent configErrorsTbl

    if isempty(configErrorsTbl)
        dataConnector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
        configErrorsTbl = dataConnector.getTable("CCEConfigErrors");
    end

    isConfigErr = contains(errMsg, configErrorsTbl.ExceptionMessage,"IgnoreCase",true);
end