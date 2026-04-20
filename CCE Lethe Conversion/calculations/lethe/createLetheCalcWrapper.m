function wrapperName = createLetheCalcWrapper(functionName)
    
    commonFolder = fileparts(mfilename("fullpath"));
    calculationFolder = fullfile(commonFolder, '..', 'lethe', 'convertedCalculations');
    deploymentFolder = fullfile(calculationFolder, functionName);
    
    % Read wrapper template
    fid = fopen('netFunctionTemplate.m','r');
    tline = fgetl(fid);
    tlines = cell(0,1);
    while ischar(tline)
        tlines{end+1,1} = tline;
        tline = fgetl(fid);
    end
    fclose(fid);
    
    % Make updates to template
    wrapperName = [lower(functionName(1)), functionName(2:end)];
    tlines = strrep(tlines, 'netFunctionTemplate', wrapperName);
    tlines = strrep(tlines, 'calculationTemplate', functionName);
    tlines = strrep(tlines, 'Class1', [functionName, 'Class']);
    if ~exist(deploymentFolder, 'dir')
        mkdir(deploymentFolder)
    end
    mFunctionName = [wrapperName '.m'];
    % Write to new function
    numOfLines = length(tlines);
    fid = fopen([deploymentFolder,'\',mFunctionName],'w');
    for i = 1:numOfLines
        fprintf(fid,'%s\n', tlines{i});
    end
    fclose(fid);
end

