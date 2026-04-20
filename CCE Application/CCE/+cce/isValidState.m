function isValid = isValidState(val)
% checks if the state is a valid state or not. Invalid states either have a
% value of InvalidState or are empty.

isValid = ismember(val, "InvalidState") || isempty(val);

end