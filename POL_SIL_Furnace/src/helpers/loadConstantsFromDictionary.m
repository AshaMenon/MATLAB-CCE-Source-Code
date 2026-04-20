function constants = loadConstantsFromDictionary(fullPath)
    %LOADCONSTANTSFROMDICTIONARY Loads design data from a Simulink data dictionary.
    %
    % Inputs:
    %   fullPath - Full path to the Simulink data dictionary (string).
    %
    % Outputs:
    %   constants - Structure containing all design data from the data dictionary.
    %
    % Example usage:
    %   constants = loadConstantsFromDictionary('myDictionary.sldd');
        
    % Check if the data dictionary file exists

    if ~isfile(fullPath)
        error('Data dictionary file not found: %s', fullPath);
    end
    
    % Load the data dictionary
    dataDictionary = Simulink.data.dictionary.open(fullPath);
    try
        % Access the design data section
        designDataSection = getSection(dataDictionary, 'Design Data');
        
        % Get all entries from the design data section
        entries = find(designDataSection, '-value');
        
        % Create the output structure
        constants = struct();
        for i = 1:numel(entries)
            entryName = entries(i).Name;
            entryValue = getValue(entries(i));
            constants.(entryName) = entryValue;
        end
    catch ME
        % Close the data dictionary and rethrow the error
        dataDictionary.close();
        rethrow(ME);
    end
    
    % Close the data dictionary
    dataDictionary.close();
end
