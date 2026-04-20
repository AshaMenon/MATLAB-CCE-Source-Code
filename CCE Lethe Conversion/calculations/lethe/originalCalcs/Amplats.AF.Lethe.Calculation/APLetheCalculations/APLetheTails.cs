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
    public class APLetheTails : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 CalculationPeriodOffset { get; set; }
        public Int32 CalulationPeriodsToRun { get; set; }

        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttNameCalculationPeriodOffset = "CalculationPeriodOffset";
        private string AttNameCalculationPeriodsToRun = "CalculationPeriodsToRun";

        private string AttCalcDryConcentrate = "DryConcentrate";
        private string AttCalcDryFeed = "DryFeed";
        private string AttCalcTails = "Tails";
        private string AttCalcnegTailsAcc = "negTailsAccumulator";

        private AFAttributeList DataRangeInputAttributes = new AFAttributeList();
        private AFAttribute outAttTails;
        private AFAttribute outAttnegTailsAcc;

        bool outputNegTailsAcc = false;

        private int CalcLoopLimit = 5;
        private int CalcBackdays = -7;
        private int MaxPeriodsToGoForward = 30;


        /// <summary>
        /// 
        /// </summary>
        public APLetheTails() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLetheTails(AFElement CalculationElement) : base(CalculationElement) { }

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
                    AddAttributeToList( DataRangeInputAttributes, AttCalcDryConcentrate, true);
                    AddAttributeToList( DataRangeInputAttributes, AttCalcDryFeed, true);

                    //output attribute
                    outAttTails = GetAttribute(AttCalcTails, true);
                    outAttnegTailsAcc = GetAttribute(AttCalcnegTailsAcc, true);
                    outputNegTailsAcc = _APLeathAF.CheckPIDataReference(outAttnegTailsAcc);



            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation Tails Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation Tails Initialization error", e.InnerException);

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

                //FeedBiggerthanConcForwardFactor
                //go forward to start or to x days large feed to ensure no negative tails adjustment

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
                
                bool endWhenTailsAccIsZero = false;

                double LastNegTailsAcc = 0;

                //if calc ends on a negative tails go back further
                for (int getItteration = 1; getItteration <= CalcLoopLimit; getItteration++)
                {
                    AFValues loopRes = new AFValues();

                    //calculate tails for range
                    loopRes.AddRange(CalcTailsForTimeRange(afCalcRange,ref LastNegTailsAcc, endWhenTailsAccIsZero));

                    //remove results for forward data - where time was moved forward this is done to make sure the start day should not need
                    // a negative adjustment from the future

                    loopRes.RemoveAll(r => r.Timestamp > Times.Max());
                    
                    //end the tails calculation as soon as the tails accumulator is zero - no adjustments for that day
                     endWhenTailsAccIsZero = true;
                    //output results
                    results.AddRange(loopRes);

                    if (LastNegTailsAcc < 0)
                    {
                        // tails ends on negative, reset range and loop through
                        //last day or last iteration
                        DateTime lastDate = loopRes.Select(r => r.Timestamp.LocalTime).Min();
                        //go back one period so that the last day is not double accounted
                        lastDate = lastDate - CalculationPeriod;
                        afCalcRange = _APLetheTime.CalulationTimes(lastDate, CalculationPeriod, CalculatAtTime, 0, CalcBackdays);


                    }
                    else
                    {
                       //last is no tails adjustment - end
                        break;
                    }

                    if (getItteration < CalcLoopLimit)
                    {
                        Log.Trace("Tails Calculation running for '{0} running loop {1}", Element.GetPath(), getItteration.ToString());
                    }
                    else
                    {
                        Log.Debug(" Error on calc '{0}' Tails calculation ended on negative tails at '{1}", Element.GetPath(), results.Select(r => r.Timestamp.LocalTime).Min().ToString());

                    }

                }

            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Tails Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
            }


            // the results are automatically written out to the AFAttribute set on the each AFValue 
            return results;

        }

        public override void RefreshElement()
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// loops through a time range to calculate the tails
        /// </summary>
        /// <param name="afRange"></param>
        /// <param name="LastNegTailsAcc"></param>
        /// <returns></returns>
        private AFValues CalcTailsForTimeRange(AFTimeRange afRange,ref double LastNegTailsAcc, bool endWhenTailsAccisZero)
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

                // DryConcentrate
                AFValues valsDryConcentrate = new AFValues();
                valsDryConcentrate.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcDryConcentrate));
                // DryFeed
                AFValues valsDryFeed = new AFValues();
                valsDryFeed.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcDryFeed));



                rawInputs.Clear();


                // run calculation, substitute estimate and set to questionable if estimate can be used


                //double LastNegTailsAcc = 0;

                //must go backwards from start time
                foreach (AFTime t in TimeList.OrderByDescending(t => t.LocalTime))
                {
                    AFValue Tails = new AFValue(null, t);
                    Tails.Attribute = outAttTails;

                    //if negative tails output
                    //AFValue negTailaf = new AFValue(null, t);
                    //negTailaf.Attribute = outAttnegTails;
                    double newNegTailAcc = 0;

                    AFValue DryFeed = _APLetheTime.GetAFValuePeriodicorTime(valsDryFeed, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                    AFValue DryConcentrate = _APLetheTime.GetAFValuePeriodicorTime(valsDryConcentrate, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);

                    TailsCalc(DryFeed, DryConcentrate, LastNegTailsAcc, Tails, ref newNegTailAcc);

                    //if write out negative tails
                    //negTailaf.Value = negTail
                    //negTailaf..Questionable = (new List<bool>() { DryFeed.Questionable, DryConcentrate.Questionable }).Max();
                    //results.Add(negTailaf);

                    Tails.Questionable = (new List<bool>() { DryFeed.Questionable, DryConcentrate.Questionable }).Max();
                    results.Add(Tails);
                    LastNegTailsAcc = newNegTailAcc;


                    if (outputNegTailsAcc)
                    {
                        AFValue negTails = new AFValue(null, t);
                        negTails.Attribute = outAttnegTailsAcc;
                        negTails.Questionable = Tails.Questionable;
                        negTails.Value = LastNegTailsAcc;
                        results.Add(negTails);
                    }


                    if (endWhenTailsAccisZero)
                    {
                        if (LastNegTailsAcc == 0) { break; }
                    }


                }
            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation Tails Error on upper time range loop '{0}'. Message: {1} ", Element.GetPath(), e.Message);

            }
            return results;
        }

        /// <summary>
        /// calculate individual tails. negative tails are made = 0, and the negative tails accumulator is removed from the last positive tails
        /// </summary>
        /// <param name="DryFeed"></param>
        /// <param name="DryConcentrate"></param>
        /// <returns></returns>
        private void TailsCalc(AFValue DryFeed, AFValue DryConcentrate, double LastNegTailsAcc, AFValue Tail,ref double newNegTailAcc)
        {
            //set to questionable if any one item is questionable
            bool IsQuestionable = (new List<bool>() { DryFeed.Questionable, DryConcentrate.Questionable }).Max(); ;

            //AFValue cTail = new AFValue();
            //cTail.Timestamp = DryFeed.Timestamp;

            double nT = 0;
            try
            {



                if (DryFeed != null & DryConcentrate != null)
                {

                    if (DryFeed.IsGood & DryConcentrate.IsGood)
                    {

                        //check conversion first
                        double rawTail = DryFeed.ValueAsDouble() - DryConcentrate.ValueAsDouble();

                        //adjust tails with negative value
                        if (rawTail + LastNegTailsAcc < 0)
                        {
                            Tail.Value = 0;
                        }
                        else
                        {
                            Tail.Value = rawTail + LastNegTailsAcc;
                        }

                        //new accumulate negative tails
                        if (rawTail + LastNegTailsAcc < 0)
                        {
                            nT = LastNegTailsAcc + rawTail;
                        }
                        else
                        {
                            nT = 0;
                        }

                    }
                    else
                    {
                        //bad value or missing value from DryConcentrate mass use its error state if it has one
                        _APLeathAF.ConvertToErrorValue(Tail, AFSystemStateCode.NoData, null);
                        Log.Debug(" Error on calc '{0}' DryConcentrate or DryFeed returned no values for '{1}", Element.GetPath(), Tail.Timestamp.LocalTime.ToString());

                        nT = LastNegTailsAcc;
                    }

                }
                else
                {
                    //bad value or missing value from DryConcentrate mass use its error state if it has one
                    _APLeathAF.ConvertToErrorValue(Tail, AFSystemStateCode.Bad, null);
                    Log.Debug(" Error on calc '{0}' DryConcentrate or DryFeed returned null for '{1}", Element.GetPath(), Tail.Timestamp.LocalTime.ToString());

                    nT = LastNegTailsAcc;
                }
            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Tails Error on value calculation'{0}' at '{1}'. Message: {2} ", Element.GetPath(),Tail.Timestamp.LocalTime.ToString(), e.Message);

            }

            Tail.Questionable = IsQuestionable;

            newNegTailAcc = nT;

        }
    }
}
