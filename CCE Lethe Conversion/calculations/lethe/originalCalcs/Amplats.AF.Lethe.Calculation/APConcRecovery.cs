using OSIsoft.AF.Asset;
using Quartz;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Amplats.AF.Lethe.Calculation
{
    public class APConcRecovery : Calculation
    {        
        public APConcRecovery()
        {
        }

        public override void Execute(IJobExecutionContext context)
        {
            base.Execute(context);

            Console.WriteLine("Executed {0} for element {1} at {2}", context.JobDetail.Key, Element.Name, context.FireTimeUtc);
        }

        public override void Initialize()
        {
            throw new NotImplementedException();
        }

        public override void Refresh()
        {
            throw new NotImplementedException();
        }
    }

}
