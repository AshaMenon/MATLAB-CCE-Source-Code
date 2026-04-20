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
    public class APLetheAggregate : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 CalculationPeriodOffset { get; set; }
        public Int32 CalulationPeriodsToRun { get; set; }

        public Int32 GoodDataPoints { get; set; }
        public string DataRange { get; set; }
        //bool ForwardDataRange { get; set; }

        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttCalculationRange = "DataRange";
        private string AttNameCalculationPeriodOffset = "CalculationPeriodOffset";
        private string AttNameCalculationPeriodsToRun = "CalculationPeriodsToRun";


        private string AttCalcAggregate = "Aggregate";
        private string AttCalcAssay = "Assay";
        private string AttCalcWeighting = "Weighting";

        private AFAttributeList DataRangeInputAttributes = new AFAttributeList();
        private AFAttribute inAssay;
        private AFAttribute inWeighting;
        private AFAttribute outAttAggregated;

        bool DoWeighting = true;
        bool useTimeRange = false;

        /// <summary>
        /// 
        /// </summary>
        public APLetheAggregate() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLetheAggregate(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// not completed or tested
        /// </summary>
        public override void CalculationInitialize()
        {
            try
            {
                throw new NotImplementedException();
                
                Log.Info("Calculation specific initialization starting for:'{0}'", Element.GetPath());

                //load calculation specific parameters
                AddAttributeToList(ConfigurationAttributes, AttNameCalculationPeriod, true);
                AddAttributeToList(ConfigurationAttributes, AttNameCalculateAtTime, true);
                AddAttributeToList(ConfigurationAttributes, AttNameCalculationPeriodOffset, true);
                AddAttributeToList(ConfigurationAttributes, AttNameCalculationPeriodsToRun, true);
                AddAttributeToList(ConfigurationAttributes, AttCalculationRange, true);

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

                //also set to MTD, YTD
                DataRange = GetLatestAFttributeValue(configVals, AttCalculationRange).Value.ToString();

                //get calculation attributes
                if (Int32.TryParse(DataRange, out tempInt32))
                {
                    GoodDataPoints = Math.Sign(tempInt32);
                    useTimeRange = false;
                    
                    //if (Math.Sign(GoodDataPoints) < 1)
                    //    ForwardDataRange = false; 
                    //else
                    //    ForwardDataRange = true; 

                }
                else
                {
                    useTimeRange = true;
                }

                //input range attributes
                inAssay = GetAttribute(AttCalcAssay, true);
                inWeighting = GetAttribute(AttCalcWeighting, true);

                //output attribute
                outAttAggregated = GetAttribute(AttCalcAggregate, true);

                DoWeighting = _APLeathAF.CheckPIDataReference(inWeighting);

                DataRangeInputAttributes.Add(inAssay);
                if (DoWeighting) { DataRangeInputAttributes.Add(inWeighting); }


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

                //set times an range of calculation period
                AFTimeRange afCalOutputRange = _APLetheTime.CalulationTimes(CalculationTime, CalculationPeriod, CalculatAtTime, CalculationPeriodOffset, CalulationPeriodsToRun);

                //Calculation times for output values
                List<AFTime> outputTimeList = _APLetheTime.TimeRangeToList(afCalOutputRange, CalculationPeriod);

                //timestamp, value, weighting
                List<Tuple<DateTime, Double, Double>> colVals = new List<Tuple<DateTime, Double, Double>>();

                #region get and collect data for calculation

                AFValues rawValsAssay = new AFValues();
                AFValues rawValsWeighting = new AFValues();

                AFTimeRange afDataRange;
                if (useTimeRange)
                {
                    //go back from last time

                    #region Get DataRange values
                    //set time range for data
                    afDataRange = _APLetheTime.GetDataRangefromCalculationRange(afCalOutputRange, DataRange, CalculationPeriod, CalculatAtTime);

                    // get inputs
                    PIPagingConfiguration page = new PIPagingConfiguration(PIPageType.EventCount, 1);

                    // Filter Expression
                    //A string containing a filter expression. Expression variables are relative to the attribute. Use '.' to reference the containing attribute.
                    List<AFValues> rawInputs = new List<AFValues>(DataRangeInputAttributes.Data.RecordedValues(afDataRange, AFBoundaryType.Outside, "BadVal('.') = 0", false, page));

                    // Assay
                    AFValues valsMoisture = new AFValues();
                    rawValsAssay.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcAssay));
                    // Weighting
                    AFValues valsWetMass = new AFValues();
                    rawValsWeighting.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcWeighting));

                    rawInputs.Clear();
                    #endregion Get DataRange values
                }
                else
                {
                    //go x values back from last time for Assay, then fill in the gap between last time and first time
                    // there is no way of knowing how many values to get for the range as raw values 
                    //then get weighting for range

                    //required values is periods in calculation range plus number of values to calculate over

                    Int32 NoValues = Math.Abs(GoodDataPoints) + outputTimeList.Count();

                    // loop until Assay values = lastGoodDataPoints - limit loop to x
                    int ValueLoopLimit = 5;

                    AFTime QueryTime;

                    QueryTime = afCalOutputRange.StartTime;

                    #region assay collection loop
                    for (int getItteration = 1; getItteration < ValueLoopLimit; getItteration++)
                    {



                        //get last x good Assay values
                        AFValues valsAssay = inAssay.Data.RecordedValuesByCount(QueryTime, NoValues,false, AFBoundaryType.Outside, null, "BadVal('.') = 0", false);

                        if (valsAssay != null)
                        {
                            //remove bad values
                            valsAssay.RemoveAll(v => !v.IsGood);

                            if (valsAssay.Count() > 0)
                            {
                                // get Assay times
                                List<AFTime> TimeList = valsAssay.Select(v => v.Timestamp).OrderByDescending(t => t.LocalTime).ToList();

                                rawValsAssay.AddRange(valsAssay);
                                //set query date to go back again if there are not enough values
                                QueryTime = TimeList.Min(); ;
                            }
                            else
                            {
                                Log.Error("Calculation Aggregate Error on '{0}'. Assay tag returned no good results from '{1}' ", Element.GetPath(), QueryTime.LocalTime.ToString());
                                break;
                            }
                        }
                        else
                        {
                            Log.Error("Calculation Aggregate Error on '{0}'. Assay tag returned a null result set from '{1}' ", Element.GetPath(), QueryTime.LocalTime.ToString());
                            break;
                        }

                        //exit loop if enough values are returned
                        if (valsAssay.Count() >= GoodDataPoints) { break; }

                    }
                    #endregion  assay collection loop
                    
                    #region get weightings
                    if (DoWeighting)
                    {
                        //add weighting range
                        AFTimeRange afweightRange = new AFTimeRange();
                        if (rawValsAssay.Count > 0)
                        {
                            afweightRange.EndTime = rawValsAssay.Select(v => v.Timestamp).Max();
                            
                            afweightRange.StartTime = rawValsAssay.Select(v => v.Timestamp).Min();
                            //rawValsAssay
                            AFValues valsWeight = inWeighting.Data.RecordedValues(afweightRange, AFBoundaryType.Outside, null, "BadVal('.') = 0 ", false);

                            valsWeight.RemoveAll(v => !v.IsGood);
                            if (valsWeight != null)
                            {
                                if (valsWeight.Count() > 0)
                                {
                                    // get Assay times
                                    List<AFTime> TimeList = valsWeight.Select(v => v.Timestamp).OrderByDescending(t => t.LocalTime).ToList();
                                    rawValsWeighting.AddRange(valsWeight);
                                }
                            }
                        }


                        



                    }
                    #endregion get weightings


                }

                #region Create list of collated inputs


                
                //get collated items based on Assays
                if (rawValsAssay.Count() > 0)
                {

                    //cleanse time range to only those were the time matches 
                    if (DoWeighting)
                    {

                        if (rawValsWeighting != null)
                        {
                            List<Tuple<DateTime, Double, AFValue>> TempEstVals = new List<Tuple<DateTime, Double, AFValue>>();

                            TempEstVals.AddRange(rawValsAssay.Select(v => new Tuple<DateTime, Double, AFValue>(v.Timestamp.LocalTime
                                , v.ValueAsDouble()
                                , _APLetheTime.GetAFValuePeriodicorTime(rawValsWeighting, v.Timestamp, OSIsoft.AF.Asset.AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod))).OrderByDescending(t => t.Item1));

                            //remove bad weighting values
                            //TempEstVals.RemoveAll(w => !w.Item3.IsGood);

                            //EstVals
                            colVals.AddRange(TempEstVals.Select(v => new Tuple<DateTime, Double, Double>(v.Item1, v.Item2, v.Item3.ValueAsDouble())).OrderByDescending(t => t.Item1));

                            TempEstVals.Clear();
                        }
                    }
                    else
                    {
                        //(v.Timestamp.LocalTime, , 1.0)
                        colVals.AddRange(rawValsAssay.Select(v => new Tuple<DateTime, Double, Double>(v.Timestamp.LocalTime, v.ValueAsDouble(), 1)).OrderByDescending(t => t.Item1));

                    }

                }

                rawValsAssay.Clear();
                rawValsWeighting.Clear();

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

                        if (useTimeRange)
                        {



                        }
                        else
                        {
                            int startindex = 0;
                            Tuple<DateTime, Double, Double> cloItem = new Tuple<DateTime,double,double>(DateTime.MinValue,double.NaN,double.NaN);

                            //if (ForwardDataRange)
                            //{
                            //    cloItem = colVals.DefaultIfEmpty(cloItem).FirstOrDefault(t => t.Item1 >= tim.LocalTime);
                            //}
                            //else
                            //{
                            cloItem = colVals.DefaultIfEmpty(cloItem).FirstOrDefault(t => t.Item1 <= tim.LocalTime);
                            //}

                            if (cloItem.Item1 != DateTime.MinValue)
                            {
                                startindex = colVals.IndexOf(cloItem);

                               // if(ForwardDataRange)
                                //{ startindex = startindex + Math.Abs(GoodDataPoints); }

                                if (startindex >= colVals.Count() - 1)
                                {
                                    //get item at time
                                    // number of last good
                                    runVals.AddRange(colVals.GetRange(startindex, GoodDataPoints));
                                }
                                else
                                {
                                    //not enough values
                                }
                            }
                            else 
                            { 
                                //no item found
                                _APLeathAF.ConvertToErrorValue(afResult, AFSystemStateCode.NoData, null);
                            }


                        }





                        if (runVals != null)
                        {

                            // order estimates and trim unneeded
                            runVals.OrderByDescending(t => t.Item1);
                            if (runVals.Count() > GoodDataPoints)
                            {
                                runVals.RemoveRange(GoodDataPoints, runVals.Count() - GoodDataPoints);

                            }

                            if (runVals.Count > 0)
                            {
                                if (runVals.Count < GoodDataPoints)
                                {
                                    _APLeathAF.ConvertToErrorValue(afResult, AFSystemStateCode.UnderRange);
                                    Log.Error("Calculation Aggregate Error on '{0}'. required number of values for estimate is not met results for '{1}'. only {2} of {3} values returned", Element.GetPath(), tim.LocalTime.ToString(), colVals.Count().ToString(), GoodDataPoints.ToString());

                                }
                                else
                                {
                                    //sum weighting
                                    double TotWeighting = runVals.Select(t => t.Item3).Sum();


                                    // do weighting
                                    List<Double> weightList = new List<double>(runVals.Select(t => t.Item2 * t.Item3));

                                    double weightAve = weightList.Sum() / TotWeighting;
                                    afResult.Value = weightAve;
                                }
                            }
                            else
                            {
                                _APLeathAF.ConvertToErrorValue(afResult, AFSystemStateCode.NoData);
                                Log.Error("Calculation Aggregate Error on '{0}'. no good results from '{1}' ", Element.GetPath(), tim.LocalTime.ToString());

                            }
                        }
                        else
                        {
                            _APLeathAF.ConvertToErrorValue(afResult, AFSystemStateCode.NoResult);
                            Log.Error("Calculation Aggregate Error on '{0}'. Estimates had a null result set from '{1}' ", Element.GetPath(), tim.LocalTime.ToString());

                        }


                    }
                    catch (Exception e)
                    {
                        Log.Fatal(e,"Calculation Aggregate loop Error on '{0}'. for calculation time '{1}' ", Element.GetPath(), tim.LocalTime.ToString());
                        _APLeathAF.ConvertToErrorValue(afResult, AFSystemStateCode.CalcFailed, null);
                    }

                        results.Add(afResult);
                }


            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Estimate Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
            }




            // the results are automatically written out to the AFAttribute set on each AFValue 
            return results;

        }

        public override void RefreshElement()
        {
            throw new NotImplementedException();
        }



    }
}
