%% Test Data Script
warning('off')

listing = dir(fullfile('..','..','..','data','controllerAnalysisMatFiles'));
fileNames = {listing.name};
addpath(fullfile('..','..','..','data', 'controllerAnalysisMatFiles'))
addpath(fullfile('..','..','..','calculationSupport', 'matlabAnalysis',...
'controllerPlotFcn', 'originalCalculation'))
for i = 1:length(fileNames)
    filename = fileNames{i};
    if length(filename) > 2
       createTestData(filename); 
    end
end
rmpath(fullfile('..','..','data','controllerAnalysisMatFiles'))
rmpath(fullfile('..','..','calculationSupport', 'matlabAnalysis',...
'controllerPlotFcn', 'originalCalculation'))
%filename = 'controllerPlotFcn_outputs_Mogn.NIcc.Hpgr.Crush.a406Bn002a.a406Lic405.mat';


