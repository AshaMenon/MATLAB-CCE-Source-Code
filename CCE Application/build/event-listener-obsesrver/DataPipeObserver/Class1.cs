using System;
using OSIsoft;
using OSIsoft.AF;
using OSIsoft.AF.Asset;
using OSIsoft.AF.Data;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DataPipeObserver
{
    public class EventObserver : IObserver<AFDataPipeEvent>
    {
        //EventObserver is an implementation of the IObserver .NET interface for an AFDataPipeEvent.
        //An EventObserver object will be subscribed to recieve data change events from the AFDataPipe.
        //On calls to the GetObserverUpdates method of the AFDataPipe (to which the observer has been subscribed),
        //if any data change events have occured since AFAttribute sign-up or since the last call, the AFDataPipe
        //will call the Observer's OnNext method which will retrieve the AFDataPipeEvents and raise and event for
        //which MATLAB can listen and recieve the event data.

        public AFListResults<AFAttribute, AFDataPipeEvent> Results = new AFListResults<AFAttribute, AFDataPipeEvent>();

        public void Flush()
        {
            Results = new AFListResults<AFAttribute, AFDataPipeEvent>();
        }

        public void OnCompleted()
        { 

        }
        public void OnError(Exception error)
        { 

        }

        public void OnNext(AFDataPipeEvent value)
        {
            //OnNext(AFDataPipeEvent value)
            //When the AFDataPipe GetObserverUpdates method is called, and update event(s) is (are) found,
            //the OnNext method will be called and the event data, AFDataPipeEvent will be passed to the OnNext method.
            //This method raises an event which can be listened for in MATLAB, passing the event data to MATLAB.

            Results.AddResult(value);
        }
    }
}
