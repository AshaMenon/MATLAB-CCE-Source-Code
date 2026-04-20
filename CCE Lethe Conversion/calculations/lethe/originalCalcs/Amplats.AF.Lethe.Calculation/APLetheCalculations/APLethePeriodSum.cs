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
    public class APLethePeriodSum : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 CalculationPeriodOffset { get; set; }
        public Int32 CalulationPeriodsToRun { get; set; }
        public bool ForceToZero { get; set; }
        public bool ForceTimeCollation { get; set; }

        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttNameCalculationPeriodOffset = "CalculationPeriodOffset";
        private string AttNameCalculationPeriodsToRun = "CalculationPeriodsToRun";
        private string AttNameForceToZero = "ForceToZero";
        private string AttNameForceTimeCollation = "ForceTimeCollation";

        private string AttCalcFinal = "Aggregate"; //output from substitutions

        //private AFAttributeList DataRangeCompressedInputAttributes = new AFAttributeList();
        //private AFAttributeList DataRangeInterpolatedInputAttributes = new AFAttributeList();
       // private AFAttributeList DataPointInputAttributes = new AFAttributeList();
        //private AFAttribute inAttEstimate;
        private AFAttribute outAttFinal;


        //get collated set of input attributes keyed by name with data collection type and 
        Dictionary<string, Tuple<string, AFAttribute>> dSubstitutes = new Dictionary<string, Tuple<string, AFAttribute>>();

        /// <summary>
        /// 
        /// </summary>
        public APLethePeriodSum() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLethePeriodSum(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// </summary>
        public override void CalculationInitialize()
        {
            try
            {

                Log.Info("Calculation Period Aggregate initialization starting for:'{0}'", Element.GetPath());

                //load calculation specific parameters
                AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriod, true);
                AddAttributeToList( ConfigurationAttributes, AttNameCalculateAtTime, true);
                AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriodOffset, true);
                AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriodsToRun, true);
                AddAttributeToList(ConfigurationAttributes, AttNameForceToZero, true);
                AddAttributeToList(ConfigurationAttributes, AttNameForceTimeCollation, true);

                AFValues configVals = ConfigurationAttributes.GetValue();

                Int32 tempInt32;
                GetAfValueInt32(out tempInt32, GetLatestAFttributeValue(configVals, AttNameCalculationPeriod), null, false);
                CalculationPeriod = new TimeSpan(0, 0, 0, tempInt32);

                GetAfValueInt32(out tempInt32, GetLatestAFttributeValue(configVals, AttNameCalculateAtTime), null, false);
                CalculatAtTime = new TimeSpan(0, 0, 0, tempInt32);

                GetAfValueInt32(out tempInt32, GetLatestAFttributeValue(configVals, AttNameCalculationPeriodOffset), null, false);
                CalculationPeriodOffset = tempInt32;

                GetAfValueInt32(out tempInt32, GetLatestAFttributeValue(configVals, AttNameCalculationPeriodsToRun), null, false);
                CalulationPeriodsToRun = tempInt32;

                bool tempBool;
                GetAfValueBolean(out tempBool, GetLatestAFttributeValue(configVals, AttNameForceToZero), null, false);
                ForceToZero = tempBool;

                GetAfValueBolean(out tempBool, GetLatestAFttributeValue(configVals, AttNameForceTimeCollation), null, false);
                ForceTimeCollation = tempBool;

                ///// add Lethe heartbeat monitor to AF

                dSubstitutes = _APLeathAF.GetInputAttributes(Element.Attributes);
                
                //output attribute
                outAttFinal = GetAttribute(AttCalcFinal, true);

            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation Period Aggregate Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation Period Aggregate Initialization error", e.InnerException);

            }

        }


        public override AFValues Evaluate(DateTime CalculationTime)
        {
            AFValues results = new AFValues();

            try
            {


                //set times an range
                AFTimeRange afRange = _APLetheTime.CalulationTimes(CalculationTime, CalculationPeriod, CalculatAtTime, CalculationPeriodOffset, CalulationPeriodsToRun);

                //Calculation times
                List<AFTime> TimeList = _APLetheTime.TimeRangeToList(afRange, CalculationPeriod);

                // get inputs into a dictionary of name and values
                Dictionary<string, AFValues> dSubstituteVals = _APLeathAF.GetInputAttributeValuesToDictionary(dSubstitutes, afRange, TimeList, CalculationPeriod);




                foreach (AFTime t in TimeList)
                {
                    // get inputs for time
                    // WetMass
                    AFValue Output = new AFValue();
                    Output.Timestamp = t;
                    Output.Attribute = outAttFinal;
                    _APLeathAF.ConvertToErrorValue(Output, AFSystemStateCode.NoData);


                    List<double> GoodInputsInPeriod = _APLeathAF.GetGoodItemsInPeriod(dSubstitutes.Keys.ToList(), dSubstituteVals, t, CalculatAtTime, CalculationPeriod, ForceTimeCollation).Select(tu => tu.Item1).ToList(); //new List<double>();

                    // calculate components for each Assay set
                    // used estimate, good


                    Output.IsGood = true;
                    Output.Questionable = false;

                    //for CountAttributeswithValues 

                    //select type of aggregate
                    if (GoodInputsInPeriod.Count > 0)
                    {
                        Output.Value = GoodInputsInPeriod.Sum();
                    }
                    else
                    {

                        if (ForceToZero)
                        {
                            Output.Value = 0;
                        }
                        else
                        {
                            
                            _APLeathAF.ConvertToErrorValue(Output, AFSystemStateCode.NoData, null);
                        }
                    }


                    if (!Output.IsGood)
                    {

                        StringBuilder Messagebuilder = new StringBuilder();
                        Messagebuilder.Append(String.Format(" No good Input values for time '{0}'", t.ToString()));
                        //got a bad or missing input
                        Log.Debug(Messagebuilder);


                    }

                    results.Add(Output);

                }

            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Component Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
            }


            // the results are automatically written out to the AFAttribute set on the each AFValue 
            return results;

        }

        public override void RefreshElement()
        {
            throw new NotImplementedException();
        }


    

        /// <summary>
        /// get the first item from the AF list and returns the value as double or null
        /// </summary>
        /// <param name="afVals"></param>
        /// <returns></returns>
        private double? GetValuefromListASDouble(AFValues afVals)
        {
            if (afVals != null)
            {
                if (afVals.Count > 0)
                {
                    double tempDouble;
                    if (GetAfValueDouble(out tempDouble, afVals.First(), double.NaN, true))
                    {
                        return tempDouble;
                    }

                }
            }
            return null;
        }

    }
}
