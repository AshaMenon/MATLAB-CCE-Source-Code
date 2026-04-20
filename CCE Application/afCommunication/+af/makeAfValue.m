function afValue = makeAfValue(val)
%makeValue  Convert MATLAB data into OSI PI AFValue object
%   AFVal = makeAFValue(val) converts the MATLAB data val into an AFValue object with timestamp
%       given by the current time, a status of GOOD, and default UOM.

arguments
    val (1,:)
end

% Convert the value
if isa(val, 'datetime')
    val = OSIsoft.AF.Time.AFTime(datestr(val, 'dd-mmm-yyyy HH:MM:SS'));
elseif isenum(val)
    val = string(val);
end
afValue = OSIsoft.AF.Asset.AFValue(val);
