function results = runLoggerTests(ifCi)
%RUNLOGGERTESTS runs the Logger's unit tests. If this is for GitLab CI the unit
%tests and coverage reports are in cobetura format
% INPUT:
%       ifCicd - true if GitLab CI format is required, default false

arguments
    ifCi = false %default human readable
end

import matlab.unittest.TestSuite
import matlab.unittest.TestRunner
import matlab.unittest.plugins.XMLPlugin
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoberturaFormat


%add folders to path so that the tests works for GitLab CI
rootPath = fileparts(mfilename("fullpath"));
rootPath = fullfile(rootPath, '../');

addpath(genpath(rootPath));

%use the /test folder for unit tests
testPath = fullfile(rootPath, "test");
suite = TestSuite.fromFolder(testPath, 'IncludingSubfolders', false);

runner = TestRunner.withTextOutput;


if ifCi % GitLab requires cobertura format
    reportFormat = CoberturaFormat('CodeCoverageResults.xml');
    runner.addPlugin(XMLPlugin.producingJUnitFormat('UnitTestResults.xml'));
else  % leave in default report format for readability
    reportFormat = matlab.unittest.plugins.codecoverage.CoverageReport;
end

p = CodeCoveragePlugin.forFolder(rootPath,  'IncludingSubfolders', false, ...
    'Producing', reportFormat);
runner.addPlugin(p);
results = runner.run(suite);

if ifCi
    %prints the coverage to the job log for GitLab to pickup
    disp(extractLineCoverage('CodeCoverageResults.xml'))
end

end

function coverageStr = extractLineCoverage(coberturaFileName)
%% EXTRACTLINECOVERAGE extract the line coverage from the specified cobertura script
% and return as a string eg "0.25%"

fid  = fopen(coberturaFileName);
text = fread(fid, inf, '*char')';
fclose(fid);

[startIndex,endIndex] = regexp(text, 'line-rate="\d*.\d*" lines');

coverageStr = text(startIndex(1):endIndex(1));

coverageStr(1:11) = [];
coverageStr(end-6:end) = [];
coverageStr = [num2str(str2double(coverageStr) * 100) '%'];

end