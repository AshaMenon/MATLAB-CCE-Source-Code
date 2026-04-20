function val = getValue(netAttr)
%getValue  Return the value of a PI AF Attribute

switch class(netAttr.DataReference)
    case "OSIsoft.AF.Asset.AFDataReferenceStub"
        val = string(netAttr.DataReference.ConfigString);
    case "OSIsoft.AF.Asset.DataReference.FormulaDR"
        val = string(netAttr.DataReference.ConfigString);
    case "OSIsoft.AF.Asset.DataReference.StringBuilderDR"
        val = string(netAttr.DataReference.ConfigString);
    case "OSIsoft.AF.Asset.DataReference.PIPointDR"
        val = string(netAttr.DataReference.ConfigString);
    otherwise
        val = netAttr.GetValue.Value;
        if isa(val, "System.String")
            val = string(val);
        end
end
end