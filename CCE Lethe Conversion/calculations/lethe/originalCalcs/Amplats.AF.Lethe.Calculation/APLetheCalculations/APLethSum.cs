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
    public class APLetheSum : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 CalculationPeriodOffset { get; set; }
        public Int32 CalulationPeriodsToRun { get; set; }
        public bool ForceToZero { get; set; }
        public bool TotaliserFilter { get; set; }

        public string DataRange { get; set; }

        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttCalculationRange = "DataRange";
        private string AttNameCalculationPeriodOffset = "CalculationPeriodOffset";
        private string AttNameCalculationPeriodsToRun = "CalculationPeriodsToRun";
        private string AttNameForceToZero = "ForceToZero";
        private string AttNameTotaliserFilter = "TotaliserFilter";

        private string AttCalcAggregate = "Aggregate";
        private string AttCalcInput = "Input";

        private AFAttribute inInput;
        private AFAttribute outAttAggregated;


        /// <summary>
        /// 
        /// </summary>
        public APLetheSum() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLetheSum(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// </summary>
        public override void CalculationInitialize()
        {
            try
            {

                Log.Info("Calculation Sum specific initialization starting for:'{0}'", Element.GetPath());

                //load calculation specific parameters
                AddAttributeToList(ConfigurationAttributes, AttNameCalculationPeriod, true);
                AddAttributeToList(ConfigurationAttributes, AttNameCalculateAtTime, true);
                AddAttributeToList(ConfigurationAttributes, AttNameCalculationPeriodOffset, true);
                AddAttributeToList(ConfigurationAttributes, AttNameCalculationPeriodsToRun, true);
                AddAttributeToList(ConfigurationAttributes, AttCalculationRange, true);
                AddAttributeToList(ConfigurationAttributes, AttNameForceToZero, true);
                AddAttributeToList(ConfigurationAttributes, AttNameTotaliserFilter, false);
                

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
                GetAfValueBolean(out tempBool, GetLatestAFttributeValue(configVals, AttNameForceToZero), null, false); ;
                ForceToZero = tempBool;

                //default to false
                GetAfValueBolean(out tempBool, GetLatestAFttributeValue(configVals, AttNameTotaliserFilter), false, false); ;
                TotaliserFilter = tempBool;

                //also set to MTD, YTD
                DataRange = GetLatestAFttributeValue(configVals, AttCalculationRange).Value.ToString();

                inInput = GetAttribute(AttCalcInput, true);

                //output attribute
                outAttAggregated = GetAttribute(AttCalcAggregate, true);

            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation Sum Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation Sum Initialization error",e.InnerException);

            }

        }


        public override AFValues Evaluate(DateTime CalculationTime)
        {
            AFValues results = new AFValues();

            try
            {

                //set times an range of calculation period
                AFTimeRange afCalOutputRange = _APLetheTime.CalulationTimes(CalculationTime, CalculationPeriod, CalculatAtTime, CalculationPeriodOffset, CalulationPeriodsToRun);

                //Calculation times for output values
                List<AFTime> outputTimeList = _APLetheTime.TimeRangeToList(afCalOutputRange, CalculationPeriod);

                //timestamp, value, weighting
                List<Tuple<DateTime, Double, Double>> colVals = new List<Tuple<DateTime, Double, Double>>();

                #region get and collect data for calculation

                AFValues rawValsInput = new AFValues();

                AFTimeRange afDataRange;


                //set time range for data
                afDataRange = _APLetheTime.GetDataRangefromCalculationRange(afCalOutputRange, DataRange, CalculationPeriod, CalculatAtTime);

                //filter = true to include values , Badval('.') = 0 is value is good and Second('*') = 1 - only include items whose time has 1 second 5:00:01 - start of period
                string Filter = "BadVal('.') = 0";
                if (TotaliserFilter)
                {
                    //exclude values where the seconds = 0, for totaliser tags
                    Filter += " and Second('*') = 1";
                }

                    // get inputs
                   rawValsInput = inInput.Data.RecordedValues(afDataRange, AFBoundaryType.Outside, null,  Filter, false);


                #region Create list of collated inputs

                colVals.AddRange(rawValsInput.Select(v => new Tuple<DateTime, Double, Double>(v.Timestamp.LocalTime, v.ValueAsDouble(), 1)).OrderByDescending(t => t.Item1));


                rawValsInput.Clear();
                //rawValsWeighting.Clear();

                #endregion Create list of collated inputs


                #endregion collect data for calculation



                //loop through each calculation output time
                foreach (AFTime tim in outputTimeList)
                {
                    
                    AFValue afResult = new AFValue();
                    afResult.Timestamp = tim;
                    afResult.Attribute = outAttAggregated;                    
                    
                    //get data for specific result
                    try
                    {
                        //get calculation specific values for calculation time range
                        List<Tuple<DateTime, Double, Double>> runVals = new List<Tuple<DateTime, Double, Double>>();

                        AFTime DataStartTime = _APLetheTime.GetPeriodStart(tim, DataRange, CalculationPeriod, CalculatAtTime);
                        //need data range here

                        //List<AFTime> SearchTimes = new List<AFTime>();
                       // SearchTimes.Add(DataStartTime.LocalTime);
                        //SearchTimes.Add(tim.LocalTime);
                        //to account for sums ahead i.e daterange is negative, check date and use a min max date.
                        //AFTime MaxDay = Math.Max()
                        //AFTime MinDay =
                        
                        runVals = colVals.Where(t => t.Item1 >= DataStartTime.LocalTime && t.Item1 <= tim.LocalTime).ToList();

                       // runVals = colVals.Where(t => t.Item1 >= (SearchTimes.Min()).LocalTime && t.Item1 <= (SearchTimes.Max()).LocalTime).ToList();

                        if (runVals != null)
                        {

                            if (runVals.Count > 0)
                            {

                                double Total = runVals.Select(t => t.Item2).Sum();

                                afResult.Value = Total;

                            }
                            else
                            {

                                if (ForceToZero)
                                {
                                    afResult.Value = 0;
                                }
                                else
                                {

                                    _APLeathAF.ConvertToErrorValue(afResult, AFSystemStateCode.NoData);
                                    Log.Error("Calculation Sum Error on '{0}'. no good results from '{1}' ", Element.GetPath(), tim.LocalTime.ToString());
                                }


                            }
                        }
                        else
                        {
                            _APLeathAF.ConvertToErrorValue(afResult, AFSystemStateCode.NoResult);
                            Log.Error("Calculation Sum Error on '{0}'. Estimates had a null result set from '{1}' ", Element.GetPath(), tim.LocalTime.ToString());

                        }


                    }
                    catch (Exception e)
                    {
                        Log.Fatal(e, "Calculation Sum loop Error on '{0}'. for calculation time '{1}' ", Element.GetPath(), tim.LocalTime.ToString());
                        _APLeathAF.ConvertToErrorValue(afResult, AFSystemStateCode.CalcFailed, null);
                    }

                        results.Add(afResult);
                }


            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Sum Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
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
