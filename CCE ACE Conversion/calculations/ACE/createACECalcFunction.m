function createACECalcFunction(calcName)

functionName = strcat("cceACE", calcName);
deploymentFolder = fullfile(pwd, "Converted Calculations/", functionName);

% Read function template
fid = fopen('cceACETemplate.m','r');
tline = fgetl(fid);
tlines = cell(0,1);
while ischar(tline)
    tlines{end+1,1} = tline;
    tline = fgetl(fid);
end
fclose(fid);

% Make updates to template
tlines = strrep(tlines, 'cceACETemplate', functionName);
if ~exist(deploymentFolder, 'dir')
    mkdir(deploymentFolder)
end

mFunctionName = strcat(functionName, '.m');
copyfile("cceACETemplate.m", fullfile(deploymentFolder, mFunctionName));

% Write to new function
numOfLines = length(tlines);
fid = fopen(fullfile(deploymentFolder, mFunctionName),'w');
for i = 1:numOfLines
    fprintf(fid,'%s\n', tlines{i});
end
fclose(fid);