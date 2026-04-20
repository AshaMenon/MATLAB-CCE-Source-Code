function piPoint = getAttributePiPointReference(attributeReference)
    % We don't want this function to ever fail, just return an empty reference
    try
        dataReference = attributeReference.DataReference;
        [dataReference] = cce.resolveDataReference(dataReference);

        if isempty(dataReference)
            piPoint = [];
        elseif isa(dataReference, 'OSIsoft.AF.Asset.DataReference.PIPointDR')
            % Super-defensive: If the reference is a relative one, we might fail in getting this
            try
                piPoint = dataReference.PIPoint;
            catch
                piPoint = [];
            end
        else % Might be a reference that does not exist.
            piPoint = []; %dataReference.ConfigString;
        end
    catch
        piPoint = [];
    end
end