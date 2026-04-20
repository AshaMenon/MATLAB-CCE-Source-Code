function setup()
%SETUP Adds relevent folders to path in order to run all the functionality

addpath(genpath('src'))
addpath(genpath('data'))
addpath(genpath('deployment'))
addpath(genpath('examples'))
addpath(genpath('Shared'))
addpath(genpath('configs'))

setPreferences()

end