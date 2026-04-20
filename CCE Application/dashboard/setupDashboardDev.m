rootFolder = fileparts(mfilename("fullpath"));
addpath(rootFolder);
addpath(genpath(fullfile(rootFolder, 'source')));
addpath(fullfile(rootFolder, 'examples'));
addpath(fullfile(rootFolder, '..'));
addpath(genpath(fullfile(rootFolder, 'build')));
cceSetup;
