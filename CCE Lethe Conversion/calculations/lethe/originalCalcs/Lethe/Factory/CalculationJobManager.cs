using NLog;
using OSIsoft.AF;
using OSIsoft.AF.Asset;
using Quartz;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Amplats.AF.Lethe.Factory
{
    /// <summary>
    /// Responsible for building the calculation scheduler job and
    /// updating them
    /// TODO: This should really be a singleton
    /// </summary>
    class CalculationJobManager
    {
        private AFDatabase _AFDatabase;
        private AFElementTemplate _BaseCalculationTemplate;
        private IScheduler _Scheduler;
        private CalculationFactory _CalcFactory;
        private static Logger Log = LogManager.GetCurrentClassLogger();

        private const int _DefaultScheduleFreq = 1800;
        private const string _JobGroup = "AFCalculations";
        private const string _EnabledAttributeName = "Enabled";

        public CalculationJobManager(AppSettings appSettings, IScheduler Scheduler)
        {
            _Scheduler = Scheduler;
            _CalcFactory = new CalculationFactory();
            _AFDatabase = AFConnection.Connect(appSettings.AFDatabaseURI);
            _BaseCalculationTemplate = _AFDatabase.ElementTemplates[appSettings.BaseTemplateName];
            if (_BaseCalculationTemplate == null)
            {
                Log.Error("The base template ({0}) is not specified or incorrect in the app.config file.", appSettings.BaseTemplateName);
                throw new ArgumentNullException("The base template is either not specified in the app.config or is incorrect");
            }            
        }

        #region Public Methods
        public void BuildCalculationSchedule()
        {
            var calcElements = GetAFCalculations();
            foreach (var e in calcElements)
            {
                AddEnabledJob(e);
            }
        }        

        public void RemoveCalculationJob(Guid JobID)
        {
            var jobKey = new JobKey(JobID.ToString(), _JobGroup);
            var jobDetails = _Scheduler.GetJobDetail(jobKey).Result;

            if (jobDetails != null)
            {
                Log.Info("Job {0} ({1}) removed", jobKey.Name, jobDetails.Description);
                _Scheduler.DeleteJob(jobKey);                
            }
        }

        /// <summary>
        /// Add a job to the schedule but first check it is enabled.
        /// </summary>
        /// <param name="Element"></param>
        public void AddJob(AFElement Element)
        {
            if (IsCalcEnabled(Element))
            {
                AddEnabledJob(Element);
            }
        }

        #endregion

        #region Private Methods
        private bool IsCalcEnabled(AFElement Element)
        {            
            var enabledAttrib = Element.Attributes[_EnabledAttributeName];
            bool enabled = false;
            if ((enabledAttrib != null) && (enabledAttrib.Type == typeof(bool)))
            {
                enabled = (bool)enabledAttrib.GetValue().Value;
            }
            return enabled;
        }

        /// <summary>
        /// Add jobs to the scheduler. However, it is assumed that they are enabled.
        /// Hence it is a private methods as the enabled check occur elsewhere.
        /// </summary>
        /// <param name="Element"></param>
        private void AddEnabledJob(AFElement Element)
        {
            string jobID = Element.ID.ToString();
            try
            {
                var calcClass = _CalcFactory.GetClass(Element);

                IJobDetail job = JobBuilder.Create(calcClass)
                    .WithDescription(Element.Description)
                    .WithIdentity(jobID, _JobGroup)
                    .Build();
                job.JobDataMap.Put("Element", Element);

                var schedFreq = GetCalculationSchedule(Element);

                ////every 5min from 6:45 for 10 runs
                //ITrigger triggerFast = TriggerBuilder.Create()
                //    .WithIdentity(jobID + "_Fast", _JobGroup)
                //    .WithDailyTimeIntervalSchedule(x => x
                //        .WithIntervalInSeconds(300)
                //        .StartingDailyAt(new TimeOfDay(6, 45))
                //        .WithRepeatCount(10))
                //    .ForJob(jobID)
                //    .Build();

                // 20210823 test 2 triggers, pre change
                ITrigger triggerSlow = TriggerBuilder.Create()
                    .WithIdentity(jobID, _JobGroup)
                    .WithSimpleSchedule(x => x
                        .WithIntervalInSeconds(schedFreq)
                        .RepeatForever()
                        .WithMisfireHandlingInstructionFireNow())
                   // .ForJob(jobID) //do not add, job does not run if added.
                    .Build();

                ////every 30min from 8:05 for 40 runs worked, trigger id must be unique
                //ITrigger triggerSlow = TriggerBuilder.Create()
                //    .WithIdentity(jobID + "_slow", _JobGroup)
                //    .WithDailyTimeIntervalSchedule(x => x
                //        .WithIntervalInSeconds(schedFreq)
                //        .StartingDailyAt(new TimeOfDay(1, 05))
                //        .WithRepeatCount(40))
                //    .ForJob(jobID)
                //    .Build();
                //// "0 45/5 6-8 * * ?" //start 6:45 run every 5 min until 8:00
                //// "0 0/5 8-0 * * ?" //start 8: run every frequ min until 8:00

                //_Scheduler.ScheduleJob(job, triggerFast);
                _Scheduler.ScheduleJob(job, triggerSlow);
                //_Scheduler.ScheduleJob(job, new List<ITrigger>() { triggerFast, triggerSlow },replace: false); //{triggerFast,triggerSlow},replace: false);'

                //_Scheduler.ScheduleJob(job, new List<ITrigger>() { triggerFast, triggerSlow },replace: false);
                Log.Info("{0} scheduled at a frequency of {1} with ID {2}.", Element.Name, schedFreq, jobID);
            }
            catch (Exception ex)
            {
                Log.Error(ex, "Calculation job {0} for {1} not loaded.", jobID, Element.Name);
            }
        }

        private AFNamedCollectionList<AFElement> GetAFCalculations()
        {

            AFNamedCollectionList<AFElement> calcElements = AFElement.FindElementsByTemplate(_AFDatabase, null, 
                _BaseCalculationTemplate, true, AFSortField.Name, 
                AFSortOrder.Ascending, int.MaxValue);

            AFAttributeList enabledAttribs = new AFAttributeList();
            foreach (var e in calcElements)
            {
                try
                {
                    var attrib = e.Attributes[_EnabledAttributeName];
                    if ((attrib != null) && (attrib.Type == typeof(bool)))
                    {
                        enabledAttribs.Add(attrib);
                    }
                }
                catch (Exception ex)
                {
                    Log.Warn(ex, "Error getting the Enabled attribute on element {0}. Calculation ignored."
                        , e.Name);
                }
            }
            var enabledVals = enabledAttribs.GetValue();
            
            var enabledCalcs = (from e in enabledVals
                               where (bool)e.Value == true
                               select e.Attribute.Element).ToList();
            AFNamedCollectionList<AFElement> calcs = new AFNamedCollectionList<AFElement>(enabledCalcs.Select(e => (AFElement)e));

            return calcs;            
        }

        private int GetCalculationSchedule(AFElement Element)
        {
            // Check if the element has a frequency specified as an extended property
            AFAttribute freqAttrib = Element.Attributes["CalculationFrequency"];

            int freq = _DefaultScheduleFreq;
            if ((freqAttrib != null) && (freqAttrib.Type == typeof(int)))
            {
                AFValue freqVal = freqAttrib.GetValue();
                if ((int)freqVal.Value > 0)
                {
                    freq = (int)freqVal.Value;
                }
                else
                {
                    Log.Warn("The CalculationFrequency attribute on {0} is incorrectly configured. It must be positive. Default schedule used", Element.Name);
                }
            }
            else
            {
                Log.Warn("The CalculationFrequency attribute is either missing or not configured as an integer on {0}. Default schedule used.", Element.Name);
            }
            
            return freq;
        }
        #endregion
    }
}
