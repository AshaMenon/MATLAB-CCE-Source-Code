function [status, sysOut] = runRcode(Rpath, RscriptFileName)
%RUNRCODE calls R externally to run an R script (.R).

%   Rpath: R.exe installation path. 
%   RscriptFileName: The R script fullname. 

% Example: 
% >> Rpath = 'C:\Program Files\R\R-4.3.1\bin';
% >> RscriptFileName = 'D:/ConvertorLeakDetectionAnalytics/Data_Preparation.R';
% >> runRcode(RscriptFileName, Rpath);

sep=filesep;
%commandline=['"' Rpath sep 'R.exe" CMD BATCH "' RscriptFileName '"'];
commandline=['"' Rpath sep 'Rscript.exe" ' RscriptFileName];
[status, sysOut] = system(commandline);

end