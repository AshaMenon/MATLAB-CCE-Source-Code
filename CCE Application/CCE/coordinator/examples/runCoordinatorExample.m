%% This is a script to run a Coordinator
%% Retrieve the Coordinator configuration
% The Coordinator ID is defined as 1. It will be used to retrieve the
% Coordinator properties from the CSV implemented database.
coordinatorId = 1;
coordinatorObj = cce.Coordinator.fetchFromDb(coordinatorId);

%% Setup the Coordinator by getting the calulations associated with it
% The setup function will call the loadCalculations function
% There is only one calculation in this case
% The calculation is defined in a CSV file (as a mocked value)
coordinatorObj.setup;
%% Run the main Coordinator loop to kick off the processing of calculations
% A timer will be created and the Coordinator Execution Frequency and
% Lifetime values will be used to set how frequently the executeCalcs
% function should run and when the timer should end respectively.
coordinatorObj.runMainLoop;
