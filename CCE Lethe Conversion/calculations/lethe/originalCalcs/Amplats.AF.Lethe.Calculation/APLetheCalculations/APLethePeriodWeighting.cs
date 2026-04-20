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
    public class APLethePeriodWeighting : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 CalculationPeriodOffset { get; set; }
        public Int32 CalulationPeriodsToRun { get; set; }
        public bool ForceToZero { get; set; }

        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttNameCalculationPeriodOffset = "CalculationPeriodOffset";
        private string AttNameCalculationPeriodsToRun = "CalculationPeriodsToRun";
        private string AttNameForceToZero = "ForceToZero";

        private string AttCalcFinal = "Weighted"; //output from substitutions
        private string AttCalcInput = "Input";
        private string AttCalcWeight = "Weight";


        private AFAttribute outAttFinal;


        //get collated set of input attributes keyed by name with data collection type and 
        Dictionary<string, Tuple<string, AFAttribute>> dSubstitutes = new Dictionary<string, Tuple<string, AFAttribute>>();

        /// <summary>
        /// 
        /// </summary>
        public APLethePeriodWeighting() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLethePeriodWeighting(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// </summary>
        public override void CalculationInitialize()
        {
            try
            {

                Log.Info("Calculation Period Weighting initialization starting for:'{0}'", Element.GetPath());

                //load calculation specific parameters
                AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriod, true);
                AddAttributeToList( ConfigurationAttributes, AttNameCalculateAtTime, true);
                AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriodOffset, true);
                AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriodsToRun, true);
                AddAttributeToList(ConfigurationAttributes, AttNameForceToZero, true);

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

                ///// add Lethe heartbeat monitor to AF

                dSubstitutes = _APLeathAF.GetInputAttributes(Element.Attributes);
                
                //output attribute
                outAttFinal = GetAttribute(AttCalcFinal, true);

            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation Period Weighting Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation Period Weighting Initialization error", e.InnerException);

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

                
                //data must be to end of period, largest day + 1 period
                // get inputs into a dictionary of name and values
                Dictionary<string, AFValues> dSubstituteVals = _APLeathAF.GetInputAttributeValuesToDictionary(dSubstitutes, _APLetheTime.RangeAddPeriodToEndofBiggest(afRange, CalculationPeriod), TimeList, CalculationPeriod);

                //bool setWeightingTo1 = false;
                //if (dSubstituteVals[AttCalcWeight.ToLower()].Count == 1)
                //{
                //    //got single weighting value - could be no weighting
                //    if (dSubstituteVals[AttCalcWeight.ToLower()][0].Value.ToString() == "1")
                //    {
                //        setWeightingTo1 = true;
                //    }

                //}




                foreach (AFTime t in TimeList)
                {
                    // get inputs for time
                    AFValue Output = new AFValue();
                    Output.Timestamp = t;
                    Output.Attribute = outAttFinal;
                    _APLeathAF.ConvertToErrorValue(Output, AFSystemStateCode.NoData);


                    List<Tuple<double, AFTime, string>> GoodInputsInPeriod = _APLeathAF.GetGoodItemsInPeriod(dSubstitutes.Keys.ToList(), dSubstituteVals, t, CalculatAtTime, CalculationPeriod, false); //new List<double>();

                    // calculate components for each Assay set

                    Output.IsGood = true;
                    Output.Questionable = false;

                    // group data on assay times - only use were there two of each
                    List<List<double>> GroupRes = new List<List<double>>();

                    if (GoodInputsInPeriod.Count > 0)
                    {


                        // Select times of input to group o, then group back on main list by time
                        GroupRes = GoodInputsInPeriod.Where(tu => tu.Item3.ToLower() == AttCalcInput.ToLower()).Select(tu => tu.Item2).ToList()
                            .GroupJoin(GoodInputsInPeriod,
                            t1 => t1,
                            t2 => t2.Item2,
                            (t1, res) => res.Select(r => r.Item1).ToList()//new List<double>(res.Select(r => r.Value))
                            ).ToList();

                        // remove all items in grouping where value count is not 2
                        GroupRes.RemoveAll(g => g.Count() != 2);
                        // weight.count = 1 and val =1, then update all item2 values to 1
                        // not used below get compressed data id Data reference is a formula
                        ////if (setWeightingTo1)
                        ////{
                        ////    GroupRes.ForEach(i => i[1] = 1);
                        ////}

                        
                    }


                        //select type of aggregate
                    if (GroupRes.Count > 0)
                    {
                            double WeightSum = GroupRes.Select(r => r.Aggregate((a, b) => b * a)).Sum();

                            double totWeight = GoodInputsInPeriod.Where(tu => tu.Item3.ToLower() == AttCalcWeight.ToLower()).Select(w => w.Item1).Sum();

                            //weighting total
                            Output.Value = WeightSum / totWeight;
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
