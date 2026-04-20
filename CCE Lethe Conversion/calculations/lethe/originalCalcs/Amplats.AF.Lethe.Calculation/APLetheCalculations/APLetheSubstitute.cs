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
    public class APLetheSubstitute : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 CalculationPeriodOffset { get; set; }
        public Int32 CalulationPeriodsToRun { get; set; }
        public bool IsPercent { get; set; }
        public double Min { get; set; }
        public double Max { get; set; }

        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttNameCalculationPeriodOffset = "CalculationPeriodOffset";
        private string AttNameCalculationPeriodsToRun = "CalculationPeriodsToRun";
        private string AttNameMin = "InputMin";
        private string AttNameMax = "InputMax";

        private string AttCalcInput = "Input";
        private string AttCalcFinal = "Output"; //output from substitutions
        private string AttCalcFinalLevelUsed = "LevelUsed"; //output from substitutions
        private char AttSplitCar = '.';
        private string catAFInputSynchronise = "Synchronise"; // if attribute is marked with this category then it becomes the master for the data from it's first data point back
        private string catAFInputUseLatest = "Use Latest"; // if attribute is marked with this category then the latest value must be used, even in the past. get current good value and use for all older items


        private AFAttributeList DataRangeInputAttributes = new AFAttributeList();
        private AFAttributeList DataUseLatestInputAttributes = new AFAttributeList();

        //private AFAttribute inAttEstimate;
        private AFAttribute outAttFinal;
        private AFAttribute outAttFinalLevelUsed;

        private bool outputLevelUsed = false;

        //get collated set of input attributes
        Dictionary<int, AFAttribute> dSubstitutes = new Dictionary<int, AFAttribute>();
        Dictionary<int, AFTime> dSubstitutesSynchronise = new Dictionary<int, AFTime>();
        Dictionary<int, AFValue> dSubstitutesUseLatest = new Dictionary<int, AFValue>();

        /// <summary>
        /// 
        /// </summary>
        public APLetheSubstitute() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLetheSubstitute(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// </summary>
        public override void CalculationInitialize()
        {
            try
            {

                Log.Info("Calculation Substitute initialization starting for:'{0}'", Element.GetPath());

                //load calculation specific parameters
                AddAttributeToList(ConfigurationAttributes, AttNameCalculationPeriod, true);
                AddAttributeToList(ConfigurationAttributes, AttNameCalculateAtTime, true);
                AddAttributeToList(ConfigurationAttributes, AttNameCalculationPeriodOffset, true);
                AddAttributeToList(ConfigurationAttributes, AttNameCalculationPeriodsToRun, true);
                AddAttributeToList(ConfigurationAttributes, AttNameMin, false);
                AddAttributeToList(ConfigurationAttributes, AttNameMax, false);

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

                double tempD;
                GetAfValueDouble(out tempD, GetLatestAFttributeValue(configVals, AttNameMin), double.NaN, true);
                Min = tempD;
                GetAfValueDouble(out tempD, GetLatestAFttributeValue(configVals, AttNameMax), double.NaN, true);
                Max = tempD;

                //get input attributes into dictionaries
                foreach (AFAttribute att in Element.Attributes)
                {
                    if (att.CategoriesString.Contains(catAFInput)) // item has input category
                    {
                        //if (att.Name.ToLower().StartsWith(AttCalcInput.ToLower()))
                        //{
                        //get input attribute number

                        string AttNo_str = att.Name.Split(AttSplitCar).Last();
                        int AttNo = 0;

                        if (int.TryParse(AttNo_str, out AttNo))
                        {
                            dSubstitutes.Add(AttNo, att);
                            if (att.CategoriesString.Contains(catAFInputSynchronise)) // item has input category
                            {
                                dSubstitutesSynchronise.Add(AttNo, AFTime.MinValue);
                            }

                            if (att.CategoriesString.Contains(catAFInputUseLatest))
                            {
                                dSubstitutesUseLatest.Add(AttNo, AFValue.CreateSystemNoDataFound(att, AFTime.Now));
                            }
                        }
                        else
                        {
                            throw new Exception("Input attribute does not end with an integer '" + att.Name + "'");
                        }

                        //}
                    }

                }

                //input attribute over range, only items not using latest.
                DataRangeInputAttributes.AddRange(dSubstitutes.Where(s => !dSubstitutesUseLatest.ContainsKey(s.Key)).Select(k => k.Value));
                DataUseLatestInputAttributes.AddRange(dSubstitutes.Where(s => dSubstitutesUseLatest.ContainsKey(s.Key)).Select(k => k.Value));

                //output attribute
                outAttFinal = GetAttribute(AttCalcFinal, true);

                //If there is an level used attribute configured then level values are written out, otherwise only the output
                outAttFinalLevelUsed = GetAttribute(AttCalcFinalLevelUsed, false);

                //if attribute is a pi point then write out
                outputLevelUsed = _APLeathAF.CheckPIDataReference(outAttFinalLevelUsed);



            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Substitute Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation Substitute Initialization error", e.InnerException);

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

                // get inputs
                PIPagingConfiguration page = new PIPagingConfiguration(PIPageType.EventCount, 1);
                List<AFValues> rawInputs = new List<AFValues>(DataRangeInputAttributes.Data.RecordedValues(afRange, AFBoundaryType.Outside, "BadVal('.') = 0", false, page));

                List<AFValues> rawUseLatest = new List<AFValues>();
                if (DataUseLatestInputAttributes.Count > 0)
                {
                    // use recorded to get last good value, otherwise a latest bad value could be returned
                    rawUseLatest.AddRange(DataUseLatestInputAttributes.Data.RecordedValuesByCount(AFTime.Now, 1, false, AFBoundaryType.Inside, "BadVal('.') = 0", false, page));
                }

                Dictionary<int, AFValues> dSubstituteVals = new Dictionary<int, AFValues>();


                foreach (int No in dSubstitutes.Keys.ToList())
                {
                    // add AFValues or null
                    dSubstituteVals.Add(No, GetValuesFromList(No, dSubstitutes, rawInputs));

                }

                foreach (int lNo in dSubstitutesUseLatest.Keys.ToList())
                {
                    // update with collected values value, use dSubstitutes as inputas it still has the complete set of inputs
                    dSubstitutesUseLatest[lNo] = GetValuesFromList(lNo, dSubstitutes, rawUseLatest).First();


                }


                foreach (int No in dSubstitutesSynchronise.Keys.ToList())
                {
                    // add latest date from input data to synchronise back from, if data is good or bad
                    // will synchronise back from newest value, anything before will be synchronised
                    if (dSubstituteVals[No] != null)
                    {
                        if (dSubstituteVals[No].Count() > 0)
                        {
                            // list of good times in data
                            List<AFTime> GoodTimes = dSubstituteVals[No].Where(v => v.IsGood).Select(t => t.Timestamp).ToList();
                            if (GoodTimes.Count > 0)
                            {
                                dSubstitutesSynchronise[No] = GoodTimes.Max();
                            }
                        }
                    }
                }

                rawInputs.Clear();



                foreach (AFTime t in TimeList)
                {
                    // get inputs for time
                    // WetMass
                    AFValue Output = new AFValue();
                    Output.Timestamp = t;
                    Output.Attribute = outAttFinal;
                    _APLeathAF.ConvertToErrorValue(Output, AFSystemStateCode.NoData);

                    AFValue OutputLevel = new AFValue();
                    OutputLevel.Timestamp = t;
                    _APLeathAF.ConvertToErrorValue(OutputLevel, AFSystemStateCode.NoData);

                    if (outputLevelUsed)
                    {
                        OutputLevel.Attribute = outAttFinalLevelUsed;

                    }

                    // calculate components for each Assay set
                    // used estimate, good

                    // run through substitutes from 1 onwards - reverse order and stop at first good or synchronise.
                    //reverse order starts at best and works down as this will result in less itterations as most calulations will be older and have all data.
                    // int ncount = 1;
                    foreach (int NameInt in dSubstitutes.Keys.OrderBy(k => k))
                    {
                        //synchronise from date
                        AFTime MinDateValue = AFTime.MinValue;
                        if (dSubstitutesSynchronise.ContainsKey(NameInt))
                        { MinDateValue = dSubstitutesSynchronise[NameInt]; }

                        AFValue Sub = new AFValue();
                        if (dSubstitutesUseLatest.ContainsKey(NameInt))
                        { Sub = dSubstitutesUseLatest[NameInt]; }
                        else
                        {
                            Sub = _APLetheTime.GetAFValuePeriodicorTime(dSubstituteVals[NameInt], t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                        }


                        if (Sub.IsGood || t <= MinDateValue) //if time is less than schyndate or good then do substitute
                        {
                            //only arttribute with synchronise category are checked, mindate = datetime.min for all others
                            //is good = substitute good only and not out of limits
                            // t <= mindate  = synchronise good or bad but not out of limits

                            bool inLimits = _APLetheGeneral.ChecktoLimits(Sub.Value.ToString(), Min, Max);
                            bool replace = false;

                            if (t <= MinDateValue)
                            {
                                // doing synchronise, check if synchronising with good value that it is in limits
                                if (Sub.IsGood & inLimits) { replace = true; }
                                else if (!Sub.IsGood) { replace = true; }
                            }
                            else if (Sub.IsGood & inLimits) { replace = true; }

                            // update for limit exclusion, can get overwittten if a lower value is okay
                            if (Sub.IsGood & !inLimits)
                            {
                                OutputLevel.IsGood = true;
                                OutputLevel.Value = 99;
                            }

                            if (replace)
                            {
                                Output.IsGood = Sub.IsGood;
                                Output.Value = Sub.Value;

                                //write out level
                                if (outputLevelUsed)
                                {
                                    OutputLevel.IsGood = true;
                                    OutputLevel.Value = NameInt;
                                }


                                // if (NameInt == 1 | NameInt == 2)
                                //{
                                // if first item then set to not questionable
                                //    Output.Questionable = false;
                                //}
                                //else
                                //{
                                Output.Questionable = false;
                                //}
                                break; //exit on first good item found
                            }
                        }


                        //ncount += 1;
                    }

                    if (!Output.IsGood)
                    {

                        StringBuilder Messagebuilder = new StringBuilder();
                        Messagebuilder.Append(String.Format(" No good Input values for time '{0}'", t.ToString()));
                        //got a bad or missing input
                        Log.Debug(Messagebuilder);


                    }

                    results.Add(Output);

                    if (outputLevelUsed)
                    {
                        results.Add(OutputLevel);
                    }


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
        /// finds the list of afValues in the outputs based on the name suffex, or null
        /// </summary>
        /// <param name="SearchName"></param>
        /// <param name="AttributeListForInput"></param>
        /// <param name="Data"></param>
        /// <returns></returns>
        private AFValues GetValuesFromList(int SearchNo, Dictionary<int, AFAttribute> AttributeListForInput, List<AFValues> Data)
        {

            //is there an estimate attribute
            if (AttributeListForInput.ContainsKey(SearchNo))
            {
                //does AFValues contain values
                if (Data != null)
                {
                    if (Data.Count() > 0)
                    {

                        //return Data.Where(a => a.Attribute.Name == AttributeListForInput[SearchName].Name);
                        foreach (AFValues afVals in Data)
                        {
                            if (afVals.Attribute.Name == AttributeListForInput[SearchNo].Name)
                            {
                                //look for an item that has a name match
                                return afVals;
                            }
                        }
                    }
                }
            }

            return null;

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
