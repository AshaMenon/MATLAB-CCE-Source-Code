%% EVENTSWITHNOQUEUE
% Demonstrates how events can be missed while MATLAB executes a callback if the event
% listener Recursive property is set to false

timedEvents = SimultaneousEventsNoQueue();
% Attach MATLAB listeners
[elistener, stopEvListener] = timedEvents.attachListeners;

% Start Timer that invokes events
startTimer(timedEvents, 1);
% Pause for 10 seconds to allow a few events to be raised
pause(10)
% Stop the timer
stopTimer(timedEvents);