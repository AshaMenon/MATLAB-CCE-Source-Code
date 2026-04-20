function text = replaceTextPlaceHolders(text, placeHolderString, replacementString)
    %REPLACETEXTPLACEHOLDERS replaces the placeholder strings found in a text string with
    %permanent strings.
    % REPLACETEXTPLACEHOLDERS(TEXT, PLACEHOLDERSTRING, REPLACEMENTSTRING) searches for
    % each PLACEHOLDERSTRING in the TEXT and replaces it with REPLACEMENTSTRING.
    
    arguments
        text string
        placeHolderString (1, :) cell
        replacementString (1, :) cell
    end
    
    %REPLACEMENTSTRING must have the same number of items as PLACEHOLDERSTRING
    assert(isequal(numel(placeHolderString), numel(replacementString)), ...
        "There must be a replacement string for each place holder string in 'placeHolderString'");
    
    for c = 1:numel(placeHolderString)
        text = regexprep(text, placeHolderString{c}, replacementString{c});
    end
end