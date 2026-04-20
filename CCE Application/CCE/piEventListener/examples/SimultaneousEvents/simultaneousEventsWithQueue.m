%% SIMULTANEOUSEVENTSWITHQUEUE
% Demonstrates how events are queued in MATLAB while the event listener Recursive property
% is set to true. MATLAB will continue to listen for and queue events while the last
% callback is being executed; when the pause command is called, the executing callback
% will be interupted and allow the next callback execution to begin.

timedEvents = SimultaneousEventsOnTimer();
% Attach MATLAB listeners
[elistener, stopEvListener] = timedEvents.attachListeners;

% Start Timer that invokes events
startTimer(timedEvents, 2);
% Pause for 5 seconds to allow a few events to be raised
pause(5)
% Stop the timer
stopTimer(timedEvents);