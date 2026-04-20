using Amplats.AF.Lethe.Factory;
using Amplats.AF.Lethe.ServiceMonitor;
using NLog;
using Quartz;
using Quartz.Impl;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Timers;
using System.Threading.Tasks;
//https://www.quartz-scheduler.net/documentation/quartz-3.x/tutorial/using-quartz.html

namespace Amplats.AF.Lethe
{
    class CalculationService
    {
        private StdSchedulerFactory _SchedFactory = new StdSchedulerFactory();
        private IScheduler _Scheduler;
        private CalculationJobManager _CalcJobManager;
        private AFDatabaseChanges _AFDBMonitor;
        private static Logger Log = LogManager.GetCurrentClassLogger();
        /// <summary>
        /// An external timer is being used to monitor changes on the AF Database
        /// as this will alter the Scheduler. It is probably better to alter the 
        /// scheduler from outside of a scheduler job.
        /// </summary>
        private Timer _AFChangeTimer; 

        public AppSettings Settings { get; private set; }

        public CalculationService(AppSettings Settings)
        {
            this.Settings = Settings;
            _Scheduler = _SchedFactory.GetScheduler().Result; // StdSchedulerFactory.GetDefaultScheduler();
            _CalcJobManager = new CalculationJobManager(Settings, _Scheduler);
            _AFChangeTimer = new Timer(Settings.AFUpdateTimer);

            _AFDBMonitor = new AFDatabaseChanges(Settings, _CalcJobManager);

            // Wire up the timer events - look at the MSDN documentation to use async (https://msdn.microsoft.com/en-us/library/system.timers.timer%28v=vs.110%29.aspx?f=255&MSPPError=-2147217396) 
            _AFChangeTimer.Elapsed += AFChangeTimer_Elapsed;
            _AFChangeTimer.AutoReset = true;
            _AFChangeTimer.Enabled = true;            
        }

        public bool Start()
        {
            bool started = true;

            _AFChangeTimer.Start();
            _Scheduler.Start();

            try
            {
                var serviceMonitor = new HeartBeat(Settings);

                IJobDetail smJob = JobBuilder.Create<HeartBeatJob>()
                    .WithDescription("Service monitor")
                    .WithIdentity("Heartbeat", "ServiceMonitor")
                    .Build();
                smJob.JobDataMap.Put("ServiceMonitor", serviceMonitor);

                ITrigger smTrigger = TriggerBuilder.Create()
                    .WithIdentity("Heartbeat", "ServiceMonitor")
                    .WithSimpleSchedule(x => x
                        .WithIntervalInSeconds(10)
                        .RepeatForever()
                        .WithMisfireHandlingInstructionFireNow())
                    .Build();
                _Scheduler.ScheduleJob(smJob, smTrigger);
            }
            catch (SchedulerException se)
            {
                Log.Fatal(se, "Scheduler Exception initializing service monitor");
                started = false;
            }
            catch (Exception ex)
            {
                Log.Fatal(ex, "General exception initialzing the service monitor.");
                started = false;
            }

            try
            {
                _CalcJobManager.BuildCalculationSchedule();
            }
            catch (SchedulerException se)
            {
                Log.Fatal(se, "Scheduler Exception initializing Calculation Jobs");
                started = false;
            }
            catch (Exception ex)
            {
                Log.Fatal(ex, "General Exception initializing Calculation Jobs");
                started = false;
            }

            return started;
        }

        public void Stop()
        {
            _AFChangeTimer.Stop();
            _Scheduler.Shutdown();
        }

        private void AFChangeTimer_Elapsed(Object source, ElapsedEventArgs e)
        {
            _AFDBMonitor.CheckUpdates();
        }
    }
}
