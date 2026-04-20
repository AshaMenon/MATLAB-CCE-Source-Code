function [sourceDataReference] = resolveDataReference(dataReference)
    %RESOLVEDATAREFERENCE resolves the input DATAREFERENCE to the source dataReference
    % RESOLVEDATAREFERENCE(RESOLVEDATAREFERENCE) finds the source PIPoint or AFAttribute
    % for the input attribute DATAREFERENCE. If the source is not a PIPoint, the data
    % reference is resolved to the last AFAttribute before the source data reference.
    
    if ~isempty(dataReference) && ~isa(dataReference, 'OSIsoft.AF.Asset.DataReference.PIPointDR')
        % If the data reference is not empty and the data reference is not a PIPoint
        % continue to resolve the data reference until the data reference no longer
        % references another AFAttribute.
        
        % Read the data
        configString = deblank(string(dataReference.ConfigString));
        configString = regexprep(configString, ';', '');
        configString = regexprep(configString, '''', '');
        refAttribute = OSIsoft.AF.Asset.AFAttribute.FindAttribute(configString, dataReference.Attribute);
        % If the data reference references another attribute, resolve that attribute's
        % data reference further.
        if ~isempty(refAttribute)
            % If the referenced attribute has a non-empty data reference, resolve the data
            % reference further, otherwise, this attribute is the source.
            if ~isempty(refAttribute.DataReference)
                dataReference = refAttribute.DataReference;
                dataReference = cce.resolveDataReference(dataReference);
            else
                dataReference = refAttribute;
            end
        % If the data reference does not reference another attribute and the data
        % reference itself is not an attribute (i.e. some other OSIsoft AF DataReference
        % object), set the source reference to be the last attribute before this data
        % reference
        elseif isempty(refAttribute) && ~isa(dataReference, 'OSIsoft.AF.Asset.AFAttribute')
            dataReference = dataReference.Attribute;
        end
    end
    
    sourceDataReference = dataReference;
end