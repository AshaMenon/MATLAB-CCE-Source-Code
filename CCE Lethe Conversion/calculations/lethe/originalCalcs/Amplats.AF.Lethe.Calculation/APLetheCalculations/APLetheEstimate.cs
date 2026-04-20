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
    public class APLetheEstimate : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 LastGoodDataPoints { get; set; }

        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttLastGoodDataPoints = "LastGoodDataPoints";


        private string AttCalcEstimate = "Estimate";
        private string AttCalcAssay = "Assay";
        private string AttCalcWeighting = "Weighting";

        //private AFAttributeList DataRangeInputAttributes = new AFAttributeList();
        private AFAttribute inAssay;
        private AFAttribute inWeighting;
        private AFAttribute outAttEstimate;

        bool DoWeighting = true;

        /// <summary>
        /// 
        /// </summary>
        public APLetheEstimate() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLetheEstimate(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// </summary>
        public override void CalculationInitialize()
        {
            try
            {

                Log.Info("Calculation specific initialization starting for:'{0}'", Element.GetPath());

                //load calculation specific parameters
                AddAttributeToList(ConfigurationAttributes, AttNameCalculationPeriod, true);
                AddAttributeToList(ConfigurationAttributes, AttNameCalculateAtTime, true);
                AddAttributeToList(ConfigurationAttributes, AttLastGoodDataPoints, true);

                AFValues configVals = ConfigurationAttributes.GetValue();

                Int32 tempInt32;
                GetAfValueInt32(out tempInt32, GetLatestAFttributeValue(configVals, AttNameCalculationPeriod), null, false);
                CalculationPeriod = new TimeSpan(0, 0, 0, tempInt32);

                GetAfValueInt32(out tempInt32, GetLatestAFttributeValue(configVals, AttNameCalculateAtTime), null, false);
                CalculatAtTime = new TimeSpan(0, 0, 0, tempInt32);

                GetAfValueInt32(out tempInt32, GetLatestAFttributeValue(configVals, AttLastGoodDataPoints), null, false);
                LastGoodDataPoints = tempInt32;

                //get calculation attributes


                //input range attributes
                //AddAttributeToList( DataRangeInputAttributes, AttCalcAssay, true);
                //AddAttributeToList( DataRangeInputAttributes, AttCalcWeighting, false);
                inAssay = GetAttribute(AttCalcAssay, true);
                inWeighting = GetAttribute(AttCalcWeighting, true);

                //output attribute
                outAttEstimate = GetAttribute(AttCalcEstimate, true);

                DoWeighting = _APLeathAF.CheckPIDataReference(inWeighting);

            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation Estimate Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation Estimate Initialization error",e.InnerException);

            }

        }


        public override AFValues Evaluate(DateTime CalculationTime)
        {
            AFValues results = new AFValues();

            try
            {
                //output time
                AFTime lastTime = _APLetheTime.LastCalculationPeriod(CalculationTime, CalculationPeriod, CalculatAtTime);


                // loop until Assay values = lastGoodDataPoints - limit loop to x
                List<Tuple<DateTime, Double, Double>> EstVals = new List<Tuple<DateTime, Double, Double>>();

                int ValueLoopLimit = 5;

                //ensure there are sufficient values for the summary

                AFTime QueryTime = lastTime;

                for (int getItteration = 1; getItteration < ValueLoopLimit; getItteration++)
                {


                    //get last x good Assay values
                    AFValues valsAssay = inAssay.Data.RecordedValuesByCount(QueryTime, LastGoodDataPoints, false, AFBoundaryType.Outside,null, "BadVal('.') = 0", false);

                    if (valsAssay != null)
                    {
                        //remove bad values
                        valsAssay.RemoveAll(v => !v.IsGood);

                        if (valsAssay.Count() > 0)
                        {
                            // get Assay times
                            List<AFTime> TimeList = valsAssay.Select(v => v.Timestamp).OrderByDescending(t => t.LocalTime).ToList();

                            //cleanse time range to only those were the time matches 
                            if (DoWeighting)
                            {
                                //set times and range for the weighting values 
                                AFTimeRange afRange = new AFTimeRange();
                                afRange.StartTime = TimeList.Min();
                                afRange.EndTime = TimeList.Max();

                                // weighting, use the time range of the assays to get the weighting values as the weighting values might have 2 points per day
                                AFValues valsWeighting = inWeighting.Data.RecordedValues(afRange, AFBoundaryType.Outside, null, "BadVal('.') = 0 ", false);
                                List<Tuple<DateTime, Double, AFValue>> TempEstVals = new List<Tuple<DateTime, Double, AFValue>>();

                                if (valsWeighting != null)
                                {
                                    TempEstVals.AddRange(valsAssay.Select(v => new Tuple<DateTime, Double, AFValue>(v.Timestamp.LocalTime
                                        , v.ValueAsDouble()
                                        , _APLetheTime.GetAFValuePeriodicorTime(valsWeighting, v.Timestamp, OSIsoft.AF.Asset.AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod))));


                                    //remove bad weighting values
                                    TempEstVals.RemoveAll(w => !w.Item3.IsGood);

                                    //EstVals
                                    EstVals.AddRange(TempEstVals.Select(v => new Tuple<DateTime, Double, Double>(v.Item1,v.Item2,v.Item3.ValueAsDouble())));
                                }
                           }
                            else 
                            {
                                //(v.Timestamp.LocalTime, , 1.0)
                                EstVals.AddRange(valsAssay.Select(v => new Tuple<DateTime, Double, Double>(v.Timestamp.LocalTime,v.ValueAsDouble(),1)));

                            }
                            
                            //set query date to go back again if there are not enough values
                            QueryTime = TimeList.Min(); ; 
                        }
                        else 
                        {
                            Log.Error("Calculation Estimate Error on '{0}'. Assay tag returned no good results from '{1}' ", Element.GetPath(), QueryTime.LocalTime.ToString());
                            break;

                        }
                    }
                    else
                    {
                        Log.Error("Calculation Estimate Error on '{0}'. Assay tag returned a null result set from '{1}' ", Element.GetPath(), QueryTime.LocalTime.ToString());
                        break;
                    }

                    if (EstVals.Count() >= LastGoodDataPoints) { break; }
                }


                AFValue Estimate = new AFValue();
                Estimate.Timestamp = lastTime;
                Estimate.Attribute = outAttEstimate;

                if (EstVals != null)
                {
                    
                    // order estimates and trim unneeded
                    EstVals.OrderByDescending(t => t.Item1);
                    if (EstVals.Count() > LastGoodDataPoints)
                    {
                        EstVals.RemoveRange(LastGoodDataPoints, EstVals.Count() - LastGoodDataPoints);

                    }
           
                    if (EstVals.Count > 0)
                    {
                        if (EstVals.Count < LastGoodDataPoints)
                        {
                            _APLeathAF.ConvertToErrorValue(Estimate, AFSystemStateCode.UnderRange);
                            Log.Error("Calculation Estimate Error on '{0}'. required number of values for estimate is not met, results for '{1}'. only {2} of {3} values returned", Element.GetPath(), QueryTime.LocalTime.ToString(),EstVals.Count().ToString(), LastGoodDataPoints.ToString());

                        }
                        else
                        {
                            //sum weighting
                            double TotWeighting = EstVals.Select(t => t.Item3).Sum();


                            // do weighting
                            List<Double> weightList = new List<double>(EstVals.Select(t => t.Item2 * t.Item3));

                            double weightAve = weightList.Sum() / TotWeighting;
                            Estimate.Value = weightAve;
                        }
                    }
                    else
                    {
                        _APLeathAF.ConvertToErrorValue(Estimate, AFSystemStateCode.NoData);
                        Log.Error("Calculation Estimate Error on '{0}'. no good results from '{1}' ", Element.GetPath(), QueryTime.LocalTime.ToString());


                    }
                }
                else
                {
                    _APLeathAF.ConvertToErrorValue(Estimate, AFSystemStateCode.NoResult);
                    Log.Error("Calculation Estimate Error on '{0}'. Estimates had a null result set from '{1}' ", Element.GetPath(), QueryTime.LocalTime.ToString());

                }

                results.Add(Estimate);
            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Estimate Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
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
