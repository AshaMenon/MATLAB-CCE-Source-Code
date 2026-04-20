using System;
using System.Threading;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TimerEventsWithEventData
{
    public class TimerEvents
    {

        public event System.EventHandler TimerTriggered;
        public event System.EventHandler TimerStopped;
        private Timer _timer;
        public int CountEvents = 0;

        public TimerEvents()
        {

        }

        public void StartTimer(TimeSpan period)
        {
            if (_timer == null)
                _timer = new Timer(TimerTicked, null, 0, (int)period.TotalMilliseconds);
        }

        public void TimerTicked(object o)
        {

            Console.WriteLine("Count Time Called Triggered");
            CountEvents++;
            CountTimerCalledEventArgs args = new CountTimerCalledEventArgs
            {
                CountTimerTicks = CountEvents
            };

            TimerTriggered(this, args);
        }

        public void StopTimer()
        {
            if (_timer != null)
                _timer.Dispose();
            TimerStopped(this, EventArgs.Empty);
        }

        public void OnCountTimerCalled()
        {
            Console.WriteLine("Event Triggered");
        }

        public void OnCountingStopped()
        {
            Console.WriteLine("Timer Stopped");
        }

    }
    public class CountTimerCalledEventArgs : EventArgs
    {
        public int CountTimerTicks { get; set; }
    }
}
