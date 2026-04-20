%% EXAMPLEIOBSERVER
this = EventsFromObserver;
% Instantiate the observable and subscribe the observer with the observable 
this.subscribeObserver("GPS");
% Add listener
r = this.attachListener;
% Update location which will result in a call to the OnNext method
updateLocation(this, 47.6456, -122.1312)
updateLocation(this, -26.1233, 28.0353)