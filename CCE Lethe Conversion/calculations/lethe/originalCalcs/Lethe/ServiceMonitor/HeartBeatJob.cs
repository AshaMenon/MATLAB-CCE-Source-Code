using Quartz;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Amplats.AF.Lethe.ServiceMonitor
{
    public class HeartBeatJob : IJob //20210823 change for version 3.3.3 Quartz, was 'public Void Execute'
    {
        private HeartBeat _ServiceMonitor;
        async Task IJob.Execute(IJobExecutionContext context)
        {
            JobDataMap dataMap = context.MergedJobDataMap;
            _ServiceMonitor = (HeartBeat)dataMap.Get("ServiceMonitor");

            _ServiceMonitor.UpdateHeartBeat();
            
        }
    }
}
