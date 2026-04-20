function createLetheTemplateInstance(calcName)
    letheRootFolder = fileparts(mfilename("fullpath"));
    templateFolder = fullfile(letheRootFolder, 'convertedCalculations', 'calculationTemplate');
    calculationFolder = fullfile(letheRootFolder, 'convertedCalculations');
    
    oldStr = 'calculationTemplate';
    newStr = calcName;
    className = [calcName 'Class.cs'];
    
    %% Replace filenames
    %Copy template folder with all its sub files
    copyfile(templateFolder, fullfile(calculationFolder, calcName));
    
    %Rename project folder
    movefile(fullfile(calculationFolder, calcName, oldStr),...
        fullfile(calculationFolder, calcName, calcName));
    
    %Rename Class 1
    classFolderName = fullfile(calculationFolder, calcName, calcName, className);
    movefile(fullfile(calculationFolder, calcName, calcName, 'Class1.cs'),...
        classFolderName);
    
    %Rename .sln
    slnName = fullfile(calculationFolder, calcName, [calcName '.sln']);
    movefile(fullfile(calculationFolder, calcName, 'calculationTemplate.sln'),...
        slnName);
    
    %Rename csproj
    projName = fullfile(calculationFolder, calcName, calcName, [calcName '.csproj']);
    movefile(fullfile(calculationFolder, calcName, calcName, 'calculationTemplate.csproj'),...
        projName);
    
    
    %% Replace strings in file
    % Class file
    stringList = {oldStr, newStr;
        'Class1', [calcName 'Class']};
    replaceStringsInfile(classFolderName, stringList)
    
    %Rename .sln and text within it
    stringList = {oldStr, newStr};
    replaceStringsInfile(slnName, stringList)
    
    %Replace cs proj strings
    stringList = {oldStr, newStr;
        'Class1.cs', className};
    replaceStringsInfile(projName, stringList)
    
    %Edit AssemblyInfo file
    stringList = {oldStr, newStr};
    assemblyName = fullfile(calculationFolder, calcName, calcName, 'Properties', 'AssemblyInfo.cs');
    replaceStringsInfile(assemblyName, stringList)
end

function tlines = getStringFromFid(fid)
    tline = fgetl(fid);
    tlines = cell(0,1);
    while ischar(tline)
        tlines{end+1,1} = tline; %#ok<AGROW>
        tline = fgetl(fid);
    end
end

function writeToFid(tlines, fid)
    % Write to new function
    numOfLines = length(tlines);
    for i = 1:numOfLines
        fprintf(fid,'%s\n', tlines{i});
    end
end

function replaceStringsInfile(fileName, stringList)
    fid = fopen(fileName, 'r');
    tlines = getStringFromFid(fid);
    fclose(fid);
    for iStr = 1:numel(stringList(:, 1))
        tlines = strrep(tlines, stringList{iStr, 1}, stringList{iStr, 2});
    end
    fid = fopen(fileName, 'w');
    writeToFid(tlines, fid);
    fclose(fid);
end