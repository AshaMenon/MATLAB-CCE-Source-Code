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
    public class APLethePebblesAndSpillagesMer : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 CalculationPeriodOffset { get; set; }
        public Int32 CalulationPeriodsToRun { get; set; }

        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttNameCalculationPeriodOffset = "CalculationPeriodOffset";
        private string AttNameCalculationPeriodsToRun = "CalculationPeriodsToRun";

        private string AttCalcDryFeedMer = "DryFeedMer";
        private string AttCalcPebble = "Pebbles";
        private string AttCalcSpillages = "Spillages";
        private string AttCalcMilledMer = "MilledMer";
        private string AttCalcPebblesMer = "PebblesMer";
        private string AttCalcSpillagesMer = "SpillagesMer";
        private string AttRunAcc = "Run";

        private AFAttributeList DataRangeInputAttributes = new AFAttributeList();
        private AFAttribute outAttMilledMer;
        private AFAttribute outAttSpillagesMer; 
        private AFAttribute outAttPebblesMer;
        private AFAttribute outAttRunAcc;
        
        bool outputRun = false;

        //private int CalcLoopLimit = 5;
        //private int CalcBackdays = -7;
        private int MaxPeriodsToGoForward = 30;


        /// <summary>
        /// 
        /// </summary>
        public APLethePebblesAndSpillagesMer() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLethePebblesAndSpillagesMer(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// </summary>
        public override void CalculationInitialize()
        {
            try
            {
                    Log.Info("Calculation specific initialization starting for:'{0}'", Element.GetPath());

                    //load calculation specific parameters
                    AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriod, true);
                    AddAttributeToList( ConfigurationAttributes, AttNameCalculateAtTime, true);
                    AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriodOffset, true);
                    AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriodsToRun, true);

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

                    //input range attributes
                    AddAttributeToList( DataRangeInputAttributes, AttCalcDryFeedMer, true);
                    AddAttributeToList(DataRangeInputAttributes, AttCalcPebble, true);
                    AddAttributeToList(DataRangeInputAttributes, AttCalcSpillages, true);

                    //output attribute
                    outAttMilledMer = GetAttribute(AttCalcMilledMer, true);
                    outAttPebblesMer = GetAttribute(AttCalcPebblesMer, true);
                    outAttSpillagesMer = GetAttribute(AttCalcSpillagesMer, true); 
                    outAttRunAcc = GetAttribute(AttRunAcc, true);
                    outputRun = _APLeathAF.CheckPIDataReference(outAttRunAcc);
            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation Pebbles and Spillages for Mer and 2 Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation Pebbles and Spillages for Mer and 2 Initialization error", e.InnerException);
            }
        }


        public override AFValues Evaluate(DateTime CalculationTime)
        {
            AFValues results = new AFValues();

            try
            {
                 //set times and range
                AFTimeRange afResRange = _APLetheTime.CalulationTimes(CalculationTime, CalculationPeriod, CalculatAtTime, CalculationPeriodOffset, CalulationPeriodsToRun);

                AFTimeRange afCalcRange = afResRange;

                List<AFTime> Times = new List<AFTime> { afResRange.StartTime, afResRange.EndTime };

                if ((DateTime.Now - CalculationTime).TotalSeconds / CalculationPeriod.TotalSeconds <= MaxPeriodsToGoForward)
                {
                    
                    AFTime newEnd = _APLetheTime.LastCalculationPeriod(DateTime.Now,CalculationPeriod,CalculatAtTime );
                    afCalcRange.EndTime = newEnd;
                    afCalcRange.StartTime = Times.Min();
                }
                else
                {
                    AFTime newEnd = _APLetheTime.LastCalculationPeriod(CalculationTime + new TimeSpan(CalculationPeriod.Ticks*MaxPeriodsToGoForward), CalculationPeriod, CalculatAtTime);
                    afCalcRange.EndTime = newEnd;
                    afCalcRange.StartTime = Times.Min();
                }

                AFValues loopRes = new AFValues();

                loopRes.AddRange(CalcPebblesAndSpillagesForTimeRange(afCalcRange));
                    
                results.AddRange(loopRes);
            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Pebbles and Spillages Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
            }

            return results;

        }

        public override void RefreshElement()
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// loops through a time range to calculate the output
        /// </summary>
        /// <param name="afRange"></param>
        /// <param name="LastZeroPnSAcc"></param>
        /// <returns></returns>
        private AFValues CalcPebblesAndSpillagesForTimeRange(AFTimeRange afRange)
        {
            AFValues results = new AFValues();

            try
            {
                //Calculation times
                List<AFTime> TimeList = _APLetheTime.TimeRangeToList(afRange, CalculationPeriod);

                // get inputs
                PIPagingConfiguration page = new PIPagingConfiguration(PIPageType.EventCount, 1);

                // Filter Expression
                //A string containing a filter expression. Expression variables are relative to the attribute. Use '.' to reference the containing attribute.
                // get the attribute values where the values are good and the time has 1 second "BadVal('.') = 1 and Second('*') <> 1",
                List<AFValues> rawInputs = new List<AFValues>(DataRangeInputAttributes.Data.RecordedValues(afRange, AFBoundaryType.Outside, "BadVal('.') = 0", false, page));

                // Milled Values
                AFValues valsMilledMer = new AFValues();
                valsMilledMer.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcDryFeedMer));

                // Pebbles
                AFValues valsPebble = new AFValues();
                valsPebble.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcPebble));

                //Spillages
                AFValues valsSpillages = new AFValues();
                valsSpillages.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcSpillages));

                rawInputs.Clear();


                // run calculation, substitute estimate and set to questionable if estimate can be used
                //double LastZeroPnSAcc = 0;

                //must go backwards from start time
                foreach (AFTime t in TimeList.OrderByDescending(t => t.LocalTime))
                {
                    //Set values to null
                    AFValue Pebbles = new AFValue(null, t);
                    Pebbles.Value = Pebbles;

                    AFValue TotalMilledMer = new AFValue(null, t);
                    TotalMilledMer.Attribute = outAttMilledMer;
                    AFValue TotalPebblesMer = new AFValue(null, t);
                    TotalPebblesMer.Attribute = outAttPebblesMer;
                    AFValue TotalSpillagesMer = new AFValue(null, t);
                    TotalSpillagesMer.Attribute = outAttSpillagesMer;

                    AFValue Pebble = _APLetheTime.GetAFValuePeriodicorTime(valsPebble, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                    AFValue Spillages = _APLetheTime.GetAFValuePeriodicorTime(valsSpillages, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                    AFValue MilledMer = _APLetheTime.GetAFValuePeriodicorTime(valsMilledMer, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                    
                    double PebbleD = 0;
                    double SpillageD = 0;
                    double MilledD = 0;

                    if(Pebble.Value.ToString() != "NoData" && Pebble.Value != null)
                    {
                        PebbleD = Pebble.ValueAsDouble();
                    }
                    if (Spillages.Value.ToString() != "NoData" && Spillages.Value != null)
                    {
                        SpillageD = Spillages.ValueAsDouble();
                    }
                    if (MilledMer.Value.ToString() != "NoData" && MilledMer.Value != null)
                    {
                        MilledD = MilledMer.ValueAsDouble();
                    }

                    if (PebbleD > 0 || SpillageD > 0)
                    {
                        foreach (AFTime d in TimeList.OrderByDescending(d => t.LocalTime))
                        {
                            if (MilledD > 0)    
                            {
                                PebblesnSpillagesCalc(MilledMer, Spillages, Pebble, TotalMilledMer,
                                    TotalPebblesMer, TotalSpillagesMer);

                                results.Add(TotalMilledMer);
                                results.Add(TotalPebblesMer);
                                results.Add(TotalSpillagesMer);
                                outputRun = true;
                            }

                            else
                            {
                                outputRun = false;
                            }

                            if (outputRun)
                            {
                                { break; }
                            }
                        }
                    }
                    else
                    {
                        TotalMilledMer.Value = MilledMer.ValueAsDouble();
                        TotalPebblesMer.Value = PebbleD;
                        TotalSpillagesMer.Value = SpillageD;
                        outputRun = false;

                        results.Add(TotalMilledMer);
                        results.Add(TotalPebblesMer);
                        results.Add(TotalSpillagesMer);
                    }
                }
            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation Pebbles Error on upper time range loop '{0}'. Message: {1} ", Element.GetPath(), e.Message);

            }
            return results;
        }

        /// <summary>
        /// calculate individual tails. negative tails are made = 0, and the negative tails accumulator is removed from the last positive tails
        /// </summary>
        /// <param name="DryFeed"></param>
        /// <param name="DryConcentrate"></param>
        /// <returns></returns>
        private void PebblesnSpillagesCalc(AFValue MilledMer, AFValue Spillages, AFValue Pebbles, AFValue TotalMilledMer,
                        AFValue TotalPebblesMer, AFValue TotalSpillagesMer)
        {
            //set to questionable if any one item is questionable
            bool IsQuestionable = (new List<bool>() { MilledMer.Questionable }).Max(); ;
            double valPebbles = 0;
            double valSpillages = 0;

            try
            {

                if (MilledMer != null)
                {

                    if (MilledMer.IsGood)
                    {
                        double rawMilledMer = 0;
                        if (MilledMer.Value.ToString() != "null" || MilledMer.Value.ToString() != "NoData")
                        {
                            rawMilledMer = MilledMer.ValueAsDouble();
                        }

                        if (rawMilledMer > 0)
                        {
                            valPebbles = Pebbles.ValueAsDouble();
                            TotalPebblesMer.Value = valPebbles;

                            valSpillages = Spillages.ValueAsDouble();
                            TotalSpillagesMer.Value = valSpillages;

                            TotalMilledMer.Value = rawMilledMer - valPebbles - valSpillages;
                        }
                        
                    }
                    else
                    {
                        //bad value or missing value from DryConcentrate mass use its error state if it has one
                        Log.Debug(" Error on calc '{0}' Mer or UG2 returned no values for '{1}", Element.GetPath(), Spillages.Timestamp.LocalTime.ToString());
                    }

                }
                else
                {
                    //bad value or missing value from DryConcentrate mass use its error state if it has one
                    Log.Debug(" Error on calc '{0}' Mer or UG2 returned null for '{1}", Element.GetPath(), Spillages.Timestamp.LocalTime.ToString());
                }
            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Pepples Error on value calculation'{0}' at '{1}'. Message: {2} ", Element.GetPath(),Spillages.Timestamp.LocalTime.ToString(), e.Message);
            }
        }
    }
}
