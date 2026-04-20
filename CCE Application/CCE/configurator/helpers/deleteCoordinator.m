function deleteCoordinator(coord)
    persistent dataConnector

    if isempty(dataConnector)
        dataConnector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
    end

    coordElem = af.Element.findByName(coord.ElementName,"Connector",dataConnector);
    coordElem.deleteElement();
end