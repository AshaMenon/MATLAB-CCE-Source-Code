function typeStr = getAttributeType(netAttr)
%getAttributeType  Return the data type of a PI AF Attribute

switch class(netAttr.DataReference)
    case "OSIsoft.AF.Asset.AFDataReferenceStub"
        typeStr = string(netAttr.DataReference.Name);
    case "OSIsoft.AF.Asset.DataReference.FormulaDR"
        typeStr = "Formula";
    case "OSIsoft.AF.Asset.DataReference.StringBuilderDR"
        typeStr = "StringBuilder";
    case "OSIsoft.AF.Asset.DataReference.PIPointDR"
        typeStr = "PIPoint";
    otherwise
        thisType = class(netAttr.GetValue.Value);
        % Might be a system.string, so convert to string
        typeStr = strrep(thisType, "System.String","string");
end
end