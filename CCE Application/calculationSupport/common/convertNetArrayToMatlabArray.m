function mlArr = convertNetArrayToMatlabArray(netArr)
%CONVERTNETARRAYTOMATLABARRAY Converts .NET arrays to MATLAB arrays
%   Detailed explanation goes here
arrayType = class(netArr);
switch arrayType
    case {'System.Int32[]', 'System.Double[]', 'System.Single[]',...
            'System.Int64[]', 'System.Int16[]'}
        mlArr = double(netArr);
    case 'System.String[]'
        mlArr = string(netArr);
    case 'System.Boolean[]'
        mlArr = logical(netArr);
    case 'System.DateTime[]'
        mlArr = NaT(netArr.Length,1);
        for i = 1:netArr.Length
            mlArr(i,1) = datetime(parseNetDateTime(netArr(i)), 'Format', 'dd/MM/yyyy HH:mm:ss');
        end
end
end

