%% TRIGGEREVENTSONTIMER
% Workflow for .NET events

timedEvents = EventTriggeredByTimerCount();
% Attach MATLAB listeners
[elistener, stopEvListener] = timedEvents.attachListeners;

% Start Timer that invokes events
startTimer(timedEvents, 2);
% Pause for 10 seconds to allow a few events to be raised
pause(10)
% Stop the timer
stopTimer(timedEvents);