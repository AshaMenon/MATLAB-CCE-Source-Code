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
    public class APLethePebblesAndSpillagesUG : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 CalculationPeriodOffset { get; set; }
        public Int32 CalulationPeriodsToRun { get; set; }

        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttNameCalculationPeriodOffset = "CalculationPeriodOffset";
        private string AttNameCalculationPeriodsToRun = "CalculationPeriodsToRun";

        private string AttCalcDryFeedUG2 = "DryFeedUG2";
        private string AttCalcDryFeedUG1 = "DryFeedUG1";
        private string AttCalcPebble = "Pebbles";
        private string AttCalcSpillages = "Spillages";
        private string AttCalcMilledUG2 = "MilledUG2";
        private string AttCalcMilledUG1 = "MilledUG1";
        private string AttCalcPebblesUG1 = "PebblesUG1";
        private string AttCalcPebblesUG2 = "PebblesUG2";
        private string AttCalcSpillagesUG1 = "SpillagesUG1";
        private string AttCalcSpillagesUG2 = "SpillagesUG2";
        private string AttRunAcc = "Run";

        private AFAttributeList DataRangeInputAttributes = new AFAttributeList();
        private AFAttribute outAttMilledUG1;
        private AFAttribute outAttMilledUG2;
        private AFAttribute outAttSpillagesUG1; 
        private AFAttribute outAttPebblesUG1;
        private AFAttribute outAttSpillagesUG2;
        private AFAttribute outAttPebblesUG2;
        private AFAttribute outAttRunAcc;
        
        bool outputRun = false;

        //private int CalcLoopLimit = 5;
        //private int CalcBackdays = -7;
        private int MaxPeriodsToGoForward = 30;


        /// <summary>
        /// 
        /// </summary>
        public APLethePebblesAndSpillagesUG() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLethePebblesAndSpillagesUG(AFElement CalculationElement) : base(CalculationElement) { }

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
                    AddAttributeToList( DataRangeInputAttributes, AttCalcDryFeedUG1, true);
                    AddAttributeToList( DataRangeInputAttributes, AttCalcDryFeedUG2, true);
                    AddAttributeToList(DataRangeInputAttributes, AttCalcPebble, true);
                    AddAttributeToList(DataRangeInputAttributes, AttCalcSpillages, true);

                    //output attribute
                    outAttMilledUG2 = GetAttribute(AttCalcMilledUG2, true);
                    outAttMilledUG1 = GetAttribute(AttCalcMilledUG1, true);
                    outAttPebblesUG1 = GetAttribute(AttCalcPebblesUG1, true);
                    outAttSpillagesUG1 = GetAttribute(AttCalcSpillagesUG1, true);
                    outAttPebblesUG2 = GetAttribute(AttCalcPebblesUG2, true);
                outAttSpillagesUG2 = GetAttribute(AttCalcSpillagesUG2, true);
            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation Pebbles and Spillages for UG1 and 2 Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation Pebbles and Spillages for UG1 and 2 Initialization error", e.InnerException);
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
                AFValues valsMilledUG1 = new AFValues();
                valsMilledUG1.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcDryFeedUG1));
                AFValues valsMilledUG2 = new AFValues();
                valsMilledUG2.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcDryFeedUG2));

                // Pebbles
                AFValues valsPebble = new AFValues();
                valsPebble.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcPebble));

                //Spillages
                AFValues valsSpillages = new AFValues();
                valsSpillages.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcSpillages));

                rawInputs.Clear();

                //must go backwards from start time
                foreach (AFTime t in TimeList.OrderByDescending(t => t.LocalTime))
                {
                    //Set values to null
                    AFValue Pebbles = new AFValue(null, t);
                    Pebbles.Value = Pebbles;

                    AFValue TotalMilledUG1 = new AFValue(null, t);
                    TotalMilledUG1.Attribute = outAttMilledUG1;
                    AFValue TotalPebblesUG1 = new AFValue(null, t);
                    TotalPebblesUG1.Attribute = outAttPebblesUG1;
                    AFValue TotalSpillagesUG1 = new AFValue(null, t);
                    TotalSpillagesUG1.Attribute = outAttSpillagesUG1;

                    AFValue TotalMilledUG2 = new AFValue(null, t);
                    TotalMilledUG2.Attribute = outAttMilledUG2;
                    AFValue TotalPebblesUG2 = new AFValue(null, t);
                    TotalPebblesUG2.Attribute = outAttPebblesUG2;
                    AFValue TotalSpillagesUG2 = new AFValue(null, t);
                    TotalSpillagesUG2.Attribute = outAttSpillagesUG2;

                    AFValue Pebble = _APLetheTime.GetAFValuePeriodicorTime(valsPebble, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                    AFValue Spillages = _APLetheTime.GetAFValuePeriodicorTime(valsSpillages, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                    AFValue MilledUG1 = _APLetheTime.GetAFValuePeriodicorTime(valsMilledUG1, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                    AFValue MilledUG2 = _APLetheTime.GetAFValuePeriodicorTime(valsMilledUG2, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);

                    double PebbleD = 0;
                    double SpillageD = 0;
                    double MilledDUG1 = 0;
                    double MilledDUG2 = 0;

                    if(Pebble.Value.ToString() != "NoData")
                    {
                        PebbleD = Pebble.ValueAsDouble();
                    }
                    if (Spillages.Value.ToString() != "NoData")
                    {
                        SpillageD = Spillages.ValueAsDouble();
                    }
                    if (MilledUG1.Value.ToString() != "NoData")
                    {
                        MilledDUG1 = MilledUG1.ValueAsDouble();
                    }
                    if (MilledUG2.Value.ToString() != "NoData")
                    {
                        MilledDUG2 = MilledUG2.ValueAsDouble();
                    }

                    if (PebbleD > 0 || SpillageD > 0)
                    {
                        var test = MilledUG1.ValueAsSingle();

                        foreach (AFTime d in TimeList.OrderByDescending(d => t.LocalTime))
                        {
                            if (test > 0)
                            {
                                PebblesnSpillagesCalc(MilledUG1, MilledUG2, Spillages, Pebble, TotalMilledUG1, TotalMilledUG2,
                                    TotalPebblesUG1, TotalPebblesUG2, TotalSpillagesUG1, TotalSpillagesUG2);

                                results.Add(TotalMilledUG1);
                                results.Add(TotalPebblesUG1);
                                results.Add(TotalSpillagesUG1);

                                results.Add(TotalMilledUG2);
                                results.Add(TotalPebblesUG2);
                                results.Add(TotalSpillagesUG2);

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
                        TotalMilledUG1.Value = MilledUG1.ValueAsDouble();
                        TotalPebblesUG1.Value = PebbleD;
                        TotalSpillagesUG1.Value = SpillageD;
                        outputRun = false;

                        results.Add(TotalMilledUG1);
                        results.Add(TotalPebblesUG1);
                        results.Add(TotalSpillagesUG1);

                        TotalMilledUG2.Value = MilledUG2.ValueAsDouble();
                        TotalPebblesUG2.Value = PebbleD;
                        TotalSpillagesUG2.Value = SpillageD;
                        outputRun = false;

                        results.Add(TotalMilledUG2);
                        results.Add(TotalPebblesUG2);
                        results.Add(TotalSpillagesUG2);
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
        private void PebblesnSpillagesCalc(AFValue MilledUG1, AFValue MilledUG2, AFValue Spillages, AFValue Pebbles, AFValue TotalMilledUG1, AFValue TotalMilledUG2,
                        AFValue TotalPebblesUG1, AFValue TotalPebblesUG2, AFValue TotalSpillagesUG1, AFValue TotalSpillagesUG2)
        {
            //set to questionable if any one item is questionable
            bool IsQuestionable = (new List<bool>() { MilledUG1.Questionable, MilledUG2.Questionable }).Max(); ;
            double valPebbles = 0;
            double valSpillages = 0;

            //double nT = 0;
            try
            {

                if (MilledUG1 != null | MilledUG2 != null)
                {

                    if (MilledUG1.IsGood | MilledUG2.IsGood)
                    {
                        double rawMilledUG1 = 0;
                        double rawMilledUG2 = 0;
                        if (MilledUG1.Value.ToString() != "NoData")
                        {
                            rawMilledUG1 = MilledUG1.ValueAsDouble();
                        }
                        if (MilledUG2.Value.ToString() != "NoData")
                        {
                            rawMilledUG2 = MilledUG2.ValueAsDouble();
                        }
                        
                        if (rawMilledUG1 > 0 && rawMilledUG2 > 0)
                        {
                            valPebbles = Pebbles.ValueAsDouble() / 2;
                            TotalPebblesUG1.Value = valPebbles;
                            TotalPebblesUG2.Value = valPebbles;

                            valSpillages = Spillages.ValueAsDouble() / 2;
                            TotalSpillagesUG1.Value = valSpillages;
                            TotalSpillagesUG2.Value = valSpillages;

                            TotalMilledUG1.Value = rawMilledUG1 - valPebbles - valSpillages;
                            TotalMilledUG2.Value = rawMilledUG2 - valPebbles - valSpillages;
                        }
                        else if (rawMilledUG1 > 0 && rawMilledUG2 <=0 )
                        {
                            valPebbles = Pebbles.ValueAsDouble();
                            valSpillages = Spillages.ValueAsDouble();
                            TotalPebblesUG1.Value = valPebbles;
                            TotalSpillagesUG1.Value = valSpillages;
                            TotalMilledUG1.Value = rawMilledUG1 - valPebbles - valSpillages;

                            TotalPebblesUG2.Value = 0;
                            TotalSpillagesUG2.Value = 0;
                            TotalMilledUG2.Value = 0;
                        }
                        else if (rawMilledUG1 <= 0 && rawMilledUG2 > 0)
                        {
                            valPebbles = Pebbles.ValueAsDouble();
                            valSpillages = Spillages.ValueAsDouble();
                            TotalPebblesUG2.Value = valPebbles;
                            TotalSpillagesUG2.Value = valSpillages;
                            TotalMilledUG2.Value = rawMilledUG2 - valPebbles - valSpillages;

                            TotalPebblesUG1.Value = 0;
                            TotalSpillagesUG1.Value = 0;
                            TotalMilledUG1.Value = 0;
                        }
                    }
                    else
                    {
                        //bad value or missing value from DryConcentrate mass use its error state if it has one
                        //_APLeathAF.ConvertToErrorValue(Pebbles, AFSystemStateCode.NoData, null);
                        Log.Debug(" Error on calc '{0}' UG1 or UG2 returned no values for '{1}", Element.GetPath(), Spillages.Timestamp.LocalTime.ToString());
                    }

                }
                else
                {
                    //bad value or missing value from DryConcentrate mass use its error state if it has one
                    //_APLeathAF.ConvertToErrorValue(Pebbles, AFSystemStateCode.Bad, null);
                    Log.Debug(" Error on calc '{0}' UG1 or UG2 returned null for '{1}", Element.GetPath(), Spillages.Timestamp.LocalTime.ToString());
                }
            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Pepples Error on value calculation'{0}' at '{1}'. Message: {2} ", Element.GetPath(),Spillages.Timestamp.LocalTime.ToString(), e.Message);

            }
        }
    }
}
