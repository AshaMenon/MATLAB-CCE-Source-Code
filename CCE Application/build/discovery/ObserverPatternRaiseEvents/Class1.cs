using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ObserverPatternRaiseEvents
{
    public struct Location
    {
        double lat, lon;

        public Location(double latitude, double longitude)
        {
            this.lat = latitude;
            this.lon = longitude;
        }

        public double Latitude
        { get { return this.lat; } }

        public double Longitude
        { get { return this.lon; } }
    }

    public class LocationReporter : IObserver<Location>
    {
        private IDisposable unsubscriber;
        public event System.EventHandler LocationTrackerUpdate;
        private string instName;

        public LocationReporter(string name)
        {
            this.instName = name;
        }

        public string Name
        { get { return this.instName; } }

        public virtual void Subscribe(IObservable<Location> provider)
        {
            if (provider != null)
                unsubscriber = provider.Subscribe(this);
        }

        public virtual void OnCompleted()
        {
            Console.WriteLine("The Location Tracker has completed transmitting data to {0}.", this.Name);
            this.Unsubscribe();
        }

        public virtual void OnError(Exception e)
        {
            Console.WriteLine("{0}: The location cannot be determined.", this.Name);
        }

        public virtual void OnNext(Location value)
        {
            Console.WriteLine("{2}: The current location is {0}, {1}", value.Latitude, value.Longitude, this.Name);
            LocationTrackerUpdateEventArgs args = new LocationTrackerUpdateEventArgs
            {
                lat = value.Latitude,
                lon = value.Longitude
            };
            LocationTrackerUpdate(this, args);
        }

        public virtual void Unsubscribe()
        {
            unsubscriber.Dispose();
        }
    }
    public class LocationTrackerUpdateEventArgs : EventArgs
    {
        public double lat { get; set; }
        public double lon { get; set; }
    }

    public class LocationTracker : IObservable<Location>
    {
        public LocationTracker()
        {
            observers = new List<IObserver<Location>>();
        }

        private List<IObserver<Location>> observers;

        public IDisposable Subscribe(IObserver<Location> observer)
        {
            if (!observers.Contains(observer))
                observers.Add(observer);
            return new Unsubscriber(observers, observer);
        }

        private class Unsubscriber : IDisposable
        {
            private List<IObserver<Location>> _observers;
            private IObserver<Location> _observer;

            public Unsubscriber(List<IObserver<Location>> observers, IObserver<Location> observer)
            {
                this._observers = observers;
                this._observer = observer;
            }

            public void Dispose()
            {
                if (_observer != null && _observers.Contains(_observer))
                    _observers.Remove(_observer);
            }
        }

        public void TrackLocation(Nullable<Location> loc)
        {
            foreach (var observer in observers)
            {
                if (!loc.HasValue)
                    observer.OnError(new LocationUnknownException());
                else
                    observer.OnNext(loc.Value);
            }
        }

        public void EndTransmission()
        {
            foreach (var observer in observers.ToArray())
                if (observers.Contains(observer))
                    observer.OnCompleted();

            observers.Clear();
        }
    }
    public class LocationUnknownException : Exception
    {
        internal LocationUnknownException()
        { }
    }

}
