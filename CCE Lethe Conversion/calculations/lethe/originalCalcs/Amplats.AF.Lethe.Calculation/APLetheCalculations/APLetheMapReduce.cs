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
    public class APLetheMapReduce : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 CalculationPeriodOffset { get; set; }
        public Int32 CalulationPeriodsToRun { get; set; }
        public bool ForceToZero { get; set; }
        public bool TotaliserFilter { get; set; }
        public Int32 AllowedBadValuesPerPeriod { get; set; }

        public string DataRange { get; set; }

        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttCalculationRange = "DataRange";
        private string AttNameCalculationPeriodOffset = "CalculationPeriodOffset";
        private string AttNameCalculationPeriodsToRun = "CalculationPeriodsToRun";
        private string AttNameTotaliserFilter = "TotaliserFilter";
        private string AttNameAllowedBadValuesPerPeriod = "AllowedBadValuesPerPeriod";

        private string AttNameMean = "Mean"; //output from substitutions
        private string AttNameStdDev = "StdDev"; //output from substitutions
        private string AttNameCountPeriod = "CountPeriod"; //input from substitutions
        private string AttNameStdDevPeriod = "StdDevPeriod"; //input from substitutions
        private string AttNameMeanPeriod = "MeanPeriod"; //input from substitutions
        private string AttNameTimePeriod = "TimePeriod"; //input from substitutions

        private AFAttributeList DataRangeInputAttributes = new AFAttributeList();
        //private AFAttributeList DataRangeInterpolatedInputAttributes = new AFAttributeList();
        // private AFAttributeList DataPointInputAttributes = new AFAttributeList();
        //private AFAttribute inAttEstimate;
        private AFAttribute outAttMean;
        private AFAttribute outAttStdDev;

       Dictionary<string, Tuple<string, AFAttribute>> dSubstitutes = new Dictionary<string, Tuple<string, AFAttribute>>();

        /// <summary>
        /// 
        /// </summary>
        public APLetheMapReduce() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLetheMapReduce(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// </summary>
        public override void CalculationInitialize()
        {
            try
            {

                Log.Info("Calculation Map Reduce specific initialization starting for:'{0}'", Element.GetPath());

                //load calculation specific parameters
                AddAttributeToList(ConfigurationAttributes, AttNameCalculationPeriod, true);
                AddAttributeToList(ConfigurationAttributes, AttNameCalculateAtTime, true);
                AddAttributeToList(ConfigurationAttributes, AttNameCalculationPeriodOffset, true);
                AddAttributeToList(ConfigurationAttributes, AttNameCalculationPeriodsToRun, true);
                AddAttributeToList(ConfigurationAttributes, AttCalculationRange, true);
                AddAttributeToList(ConfigurationAttributes, AttNameTotaliserFilter, false);
                AddAttributeToList(ConfigurationAttributes, AttNameAllowedBadValuesPerPeriod, false);

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

                GetAfValueInt32(out tempInt32, GetLatestAFttributeValue(configVals, AttNameAllowedBadValuesPerPeriod), null, false);
                AllowedBadValuesPerPeriod = tempInt32;

                bool tempBool;

                //default to false
                GetAfValueBolean(out tempBool, GetLatestAFttributeValue(configVals, AttNameTotaliserFilter), false, false); ;
                TotaliserFilter = tempBool;

                //also set to MTD, YTD
                DataRange = GetLatestAFttributeValue(configVals, AttCalculationRange).Value.ToString();
                
                //input range attributes
                AddAttributeToList(DataRangeInputAttributes, AttNameCountPeriod, true);
                AddAttributeToList(DataRangeInputAttributes, AttNameMeanPeriod, true);
                AddAttributeToList(DataRangeInputAttributes, AttNameStdDevPeriod, true);
                AddAttributeToList(DataRangeInputAttributes, AttNameTimePeriod, true);

                //output attribute
                outAttMean = GetAttribute(AttNameMean, true);
                outAttStdDev = GetAttribute(AttNameStdDev, true);

                // test
                Log.Trace( "Calculation Map Reduce Initialized '{0}'. for calculation at time '{1}' ", Element.GetPath(), DateTime.Now.ToString());

            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Map Reduce Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation Map Reduce Initialization error",e.InnerException);

            }

        }


        public override AFValues Evaluate(DateTime CalculationTime)
        {
            AFValues results = new AFValues();

            try
            {

                // test
                Log.Trace("Calculation Map Reduce run start '{0}'. for calculation at time '{1}' ", Element.GetPath(), DateTime.Now.ToString());

                //set times an range of calculation period
                AFTimeRange afCalOutputRange = _APLetheTime.CalulationTimes(CalculationTime, CalculationPeriod, CalculatAtTime, CalculationPeriodOffset, CalulationPeriodsToRun);

                //Calculation times for output values
                List<AFTime> outputTimeList = _APLetheTime.TimeRangeToList(afCalOutputRange, CalculationPeriod);

                //timestamp, value, weighting
                //List<Tuple<DateTime, Double, Double>> colVals = new List<Tuple<DateTime, Double, Double>>();

                #region get and collect data for calculation

                //Delete Later
                //AFValues rawValsInput = new AFValues();

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

                PIPagingConfiguration page = new PIPagingConfiguration(PIPageType.EventCount, 1);

                // get inputs
                List<AFValues> rawInputs = new List<AFValues>(DataRangeInputAttributes.Data.RecordedValues(afDataRange, AFBoundaryType.Outside, Filter, false, page));

                // Count
                AFValues valsCount = new AFValues();
                valsCount.AddRange(rawInputs.Single(r => r.Attribute.Name == AttNameCountPeriod));
                // Mean
                AFValues valsMean = new AFValues();
                valsMean.AddRange(rawInputs.Single(r => r.Attribute.Name == AttNameMeanPeriod));
                // StdDev
                AFValues valsStdDev = new AFValues();
                valsStdDev.AddRange(rawInputs.Single(r => r.Attribute.Name == AttNameStdDevPeriod));
                //Time
                AFValues valsTime = new AFValues();
                valsTime.AddRange(rawInputs.Single(r => r.Attribute.Name == AttNameTimePeriod));

                rawInputs.Clear();
                            


                #endregion collect data for calculation



                //loop through each calculation output time
                foreach (AFTime tim in outputTimeList)
                {
                    AFValue OutputMean = new AFValue();
                    OutputMean.Timestamp = tim;
                    OutputMean.Attribute = outAttMean;
                    _APLeathAF.ConvertToErrorValue(OutputMean, AFSystemStateCode.NoData);

                    AFValue OutputStdDev = new AFValue();
                    OutputStdDev.Timestamp = tim;
                    OutputStdDev.Attribute = outAttStdDev;
                    _APLeathAF.ConvertToErrorValue(OutputStdDev, AFSystemStateCode.NoData);




                    //get data for specific result
                    try
                    {

                        //get calculation specific values for calculation time range
                        // List<Tuple<DateTime, Double, Double>> runVals = new List<Tuple<DateTime, Double, Double>>();


                        AFTime DataStartTime = _APLetheTime.GetPeriodStart(tim, DataRange, CalculationPeriod, CalculatAtTime);

                        AFTimeRange afMapReduceTimeRange = new AFTimeRange();
                        afMapReduceTimeRange.StartTime = DataStartTime;
                        afMapReduceTimeRange.EndTime = tim;

                        List<AFTime> MapReduceTimeList = _APLetheTime.TimeRangeToList(afMapReduceTimeRange, CalculationPeriod);
                        double mMeanCounter = double.NaN;
                        double nCountCounter = double.NaN;
                        double cVarianceCounter = double.NaN;
                        double tTimeCounter = double.NaN;
                        Boolean FirstRun = true;

                        int BadValCount = 0;

                        //Check Debug for Order, Must be oldest to newest
                        foreach (AFTime t in MapReduceTimeList)
                        { 
                             //Loop through each input time to calculate progressively for each period
                            //need data range here
                            AFValue Mean = _APLetheTime.GetAFValuePeriodicorTime(valsMean, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                            AFValue Count = _APLetheTime.GetAFValuePeriodicorTime(valsCount, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                            AFValue StdDev = _APLetheTime.GetAFValuePeriodicorTime(valsStdDev, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                            AFValue Time = _APLetheTime.GetAFValuePeriodicorTime(valsTime, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);

                            double _mMeanCounter = double.NaN;
                            double _nCountCounter = double.NaN;
                            double _cVarianceCounter = double.NaN;
                            double _tTimeCounter = double.NaN;
                            //runVals = colVals.Where(t => t.Item1 >= DataStartTime.LocalTime && t.Item1 <= tim.LocalTime).ToList();
                            Boolean AllGood = Mean.IsGood & Count.IsGood & StdDev.IsGood & Time.IsGood;
                            if (AllGood)
                            {
                                if (FirstRun)
                                {
                                    _mMeanCounter = (Count.ValueAsDouble() * Mean.ValueAsDouble()) / Count.ValueAsDouble();
                                    _nCountCounter = Count.ValueAsDouble();
                                    _cVarianceCounter = (StdDev.ValueAsDouble() * StdDev.ValueAsDouble());
                                    _tTimeCounter = Time.ValueAsDouble();

                                    FirstRun = false;
                                }
                                else
                                {
                                    _nCountCounter = nCountCounter + Count.ValueAsDouble();
                                    _tTimeCounter = tTimeCounter + Time.ValueAsDouble();
                                    if (Count.ValueAsDouble() > 0)
                                    {
                                        _mMeanCounter = (nCountCounter * mMeanCounter + Count.ValueAsDouble() * Mean.ValueAsDouble()) / _nCountCounter;
                                        _cVarianceCounter = (nCountCounter * cVarianceCounter + Count.ValueAsDouble() * StdDev.ValueAsDouble() + nCountCounter * (mMeanCounter - _mMeanCounter) * (mMeanCounter - _mMeanCounter) + Count.ValueAsDouble() * (Mean.ValueAsDouble() - _mMeanCounter)) / _nCountCounter;
                                    }
                                    else
                                    {
                                        _mMeanCounter = mMeanCounter;
                                        _cVarianceCounter = cVarianceCounter;
                                    }




                                }

                                cVarianceCounter = _cVarianceCounter;
                                mMeanCounter = _mMeanCounter;
                                nCountCounter = _nCountCounter;
                                tTimeCounter = _tTimeCounter;

                            }
                            else
                            {
                                //got bad data
                                BadValCount += 1;

                                if (AllowedBadValuesPerPeriod > -1) { //negative numbers no bad value period check
                                    if (BadValCount > AllowedBadValuesPerPeriod)
                                    {
                                        string Message = "Too many bad values for calculation; got " + BadValCount + " bad value periods";
                                        throw new InvalidOperationException(Message);
                                    }

                                }

                            }
                        } // end each time in period loop

                        if (!double.IsNaN(mMeanCounter) || !double.IsNaN(cVarianceCounter))
                        {
                              
                            OutputMean.Value = mMeanCounter;
                            OutputMean.Questionable = false;
                            OutputMean.IsGood = true;

                            OutputStdDev.Value = Math.Sqrt(cVarianceCounter);
                            OutputStdDev.Questionable = false;
                            OutputStdDev.IsGood = true;
                        }
                        else
                        {
                            _APLeathAF.ConvertToErrorValue(OutputMean, AFSystemStateCode.NoResult);
                            _APLeathAF.ConvertToErrorValue(OutputStdDev, AFSystemStateCode.NoResult);
                            Log.Debug("Calculation Map Reduce Error on '{0}'. Day had a Bad result set from '{1}' ", Element.GetPath(), tim.LocalTime.ToString());

                        }


                    }
                    catch (Exception e)
                    {
                        Log.Fatal(e, "Calculation Map Reduce loop Error on '{0}'. for calculation time '{1}' ", Element.GetPath(), tim.LocalTime.ToString());
                        _APLeathAF.ConvertToErrorValue(OutputMean, AFSystemStateCode.CalcFailed, null);
                        _APLeathAF.ConvertToErrorValue(OutputStdDev, AFSystemStateCode.CalcFailed, null);
                    }

                        results.Add(OutputMean);
                        results.Add(OutputStdDev);
                }


            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Map Reduce Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
            }


            // test
            Log.Trace("Calculation Map Reduce run end '{0}'. for calculation at time '{1}' ", Element.GetPath(), DateTime.Now.ToString());



            // the results are automatically written out to the AFAttribute set on the each AFValue 
            return results;

        }

        public override void RefreshElement()
        {
            throw new NotImplementedException();
        }



    }
}
