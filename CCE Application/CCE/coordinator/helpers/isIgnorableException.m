function bool = isIgnorableException(errMessage)
    persistent ignorableExceptionsTbl

    if isempty(ignorableExceptionsTbl)
        dataConnector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
        ignorableExceptionsTbl = dataConnector.getTable("CCEIgnorableExceptions");
    end

    bool = contains(errMessage, ignorableExceptionsTbl.ExceptionMessage,"IgnoreCase",true);
end