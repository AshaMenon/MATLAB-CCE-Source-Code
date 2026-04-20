using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using OSIsoft.AF.Asset;
using OSIsoft.AF.Data;
using OSIsoft.AF.Time;
using OSIsoft.AF.PI;
using Quartz;
using Amplats.AF.Lethe.Factory;

namespace Amplats.AF.Lethe.Calculation
{
    /// <summary>
    /// simple hearbeat that writes out current min at the calculation time
    /// </summary>
    public class APLetheHeartBeat: LetheCalculation
    {

        private string AttCalcHeartBeat = "HeartBeat";

        private AFAttribute outAttHeartBeat;


        /// <summary>
        /// 
        /// </summary>
        public APLetheHeartBeat() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLetheHeartBeat(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// </summary>
        public override void CalculationInitialize()
        {
            try
            {

                Log.Info("Calculation APLetheHeartBeat initialization starting for:'{0}'", Element.GetPath());

                //output attribute
                outAttHeartBeat = GetAttribute(AttCalcHeartBeat, true);

            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation HeartBeat Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation HeartBeat Initialization error", e.InnerException);

            }

        }


        public override AFValues Evaluate(DateTime CalculationTime)
        {
            AFValues results = new AFValues();

            try
            {

                AFTime CalTime = new AFTime(DateTime.Now);

                AFValue HeartBeat = new AFValue();
                HeartBeat.Timestamp = CalTime;
                HeartBeat.Attribute = outAttHeartBeat;
                HeartBeat.Value = CalTime.LocalTime.TimeOfDay.TotalMinutes;
                HeartBeat.Questionable = false;
                HeartBeat.IsGood = true;
 
                results.Add(HeartBeat);


            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation HeartBeat Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
            }


            // the results are automatically written out to the AFAttribute set on the each AFValue 
            return results;

        }

        public override void RefreshElement()
        {
            throw new NotImplementedException();
        }


    }
}
