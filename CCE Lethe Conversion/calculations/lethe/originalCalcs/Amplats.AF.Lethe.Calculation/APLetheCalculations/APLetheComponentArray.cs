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
    public class APLetheComponentArray : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 CalculationPeriodOffset { get; set; }
        public Int32 CalulationPeriodsToRun { get; set; }
        public bool IsPercent { get; set; }

        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttNameCalculationPeriodOffset = "CalculationPeriodOffset";
        private string AttNameCalculationPeriodsToRun = "CalculationPeriodsToRun";
        private string AttNameComponentIsPercent = "ComponentIsPercent";
        private string AttNameRequireAllInputs = "RequireAllInputs";

        private string AttCalcEstimate = "Estimate";
        private string AttCalcAssay = "Assay";
        private string AttCalcDryMass = "DryMass";
        private string AttCalcComponent = "Component";
        private string AttCalcRollupAssay = "RollupAssay";
        private string AttCalcRollupDry = "RollupDry";

        private AFAttributeList DataRangeInputAttributes = new AFAttributeList();
        private AFAttributeList DataPointInputAttributes = new AFAttributeList();
        //private AFAttribute inAttEstimate;
        private AFAttribute outAttComponent;
        private AFAttribute outAttRollupAssay = null;
        private AFAttribute outAttRollupDry = null;

        //private bool calculateWithEstimates = false;
        private bool DoRollupAssay = false;
        private bool DoRollupDry = false;

        private bool RequireAllInputs = false;

        //get collated set of input attributes
        Dictionary<string, AFAttribute> dDry = new Dictionary<string, AFAttribute>();
        Dictionary<string, AFAttribute> dAssay = new Dictionary<string, AFAttribute>();
        Dictionary<string, AFAttribute> dEst = new Dictionary<string, AFAttribute>();

        /// <summary>
        /// 
        /// </summary>
        public APLetheComponentArray() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLetheComponentArray(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// </summary>
        public override void CalculationInitialize()
        {
            try
            {

                Log.Info("Calculation Component initialization starting for:'{0}'", Element.GetPath());

                //load calculation specific parameters
                AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriod, true);
                AddAttributeToList( ConfigurationAttributes, AttNameCalculateAtTime, true);
                AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriodOffset, true);
                AddAttributeToList( ConfigurationAttributes, AttNameCalculationPeriodsToRun, true);
                AddAttributeToList( ConfigurationAttributes, AttNameComponentIsPercent,true);
                AddAttributeToList(ConfigurationAttributes, AttNameRequireAllInputs, true);

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
                GetAfValueBolean(out tempBool, GetLatestAFttributeValue(configVals, AttNameComponentIsPercent), null, false);;
                IsPercent = tempBool;

                GetAfValueBolean(out tempBool, GetLatestAFttributeValue(configVals, AttNameRequireAllInputs), null, false); ;
                RequireAllInputs = tempBool;


                //get input attributes into dictionaries
                foreach (AFAttribute att in Element.Attributes)
                {
                    if (att.Name.ToLower().StartsWith(AttCalcAssay.ToLower())) 
                    {
                        dAssay.Add(att.Name.Remove(0, AttCalcAssay.Length), att);
                    }
                    else if (att.Name.ToLower().StartsWith(AttCalcDryMass.ToLower()))
                    {
                        dDry.Add(att.Name.Remove(0, AttCalcDryMass.Length), att);
                    }
                    else if (att.Name.ToLower().StartsWith(AttCalcEstimate.ToLower()))
                    {
                        dEst.Add(att.Name.Remove(0, AttCalcEstimate.Length), att);
                    }
                }

                //input attribute over range
                DataRangeInputAttributes.AddRange(dAssay.Values);
                DataRangeInputAttributes.AddRange(dDry.Values);

                //input attribute for value
                DataPointInputAttributes.AddRange(dEst.Values);

                //output attribute
                outAttComponent = GetAttribute(AttCalcComponent, true);

                outAttRollupAssay = GetAttribute(AttCalcRollupAssay, true);

                outAttRollupDry = GetAttribute(AttCalcRollupDry, true);

                //if attribute is a pi point then use calculate water
                DoRollupAssay = _APLeathAF.CheckPIDataReference(outAttRollupAssay);
                DoRollupDry = _APLeathAF.CheckPIDataReference(outAttRollupDry);

            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation Component Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation Component Initialization error", e.InnerException);

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

                // get input values - Estimates
                PIPagingConfiguration pageEst = new PIPagingConfiguration(PIPageType.EventCount, 1);
                List<AFValues> rawEstInputs = new List<AFValues>(DataPointInputAttributes.Data.RecordedValuesByCount(new AFTime(DateTime.Now), 1, false, AFBoundaryType.Inside, "BadVal('.') = 0", false, pageEst));

                //get raw data into attribute lists

                //Get Estimate Dictionaries aligned to Assays
                Dictionary<string, double?> dEstVals = new Dictionary<string, double?>();
                Dictionary<string, AFValues> dAssayVals = new Dictionary<string, AFValues>();
                Dictionary<string, AFValues> dDryMassVals = new Dictionary<string, AFValues>();


                foreach (string NameSuffix in dAssay.Keys )
                {
                    // add AFValues or null
                    dAssayVals.Add(NameSuffix, GetValuesFromList(NameSuffix, dAssay, rawInputs));
                    dDryMassVals.Add(NameSuffix, GetValuesFromList(NameSuffix, dDry, rawInputs));
                    //Estimate single values
                    dEstVals.Add(NameSuffix, GetValuefromListASDouble(GetValuesFromList(NameSuffix, dEst, rawEstInputs)));
                }

                rawInputs.Clear();
                rawEstInputs.Clear();

                // run calculation, substitute estimate and set to questionable if estimate can be used




                foreach (AFTime t in TimeList)
                {
                    // get inputs for time
                    // WetMass
                    AFValue Component = new AFValue();
                    Component.Timestamp = t;
                    Component.Attribute = outAttComponent;
                    bool missingAssay = true;


                    // calculate components for each Assay set
                    // used estimate, good

                    Dictionary<string, AFValue> timeComp = new Dictionary<string, AFValue>();

                    //Dictionary<string, AFValue> Inputs = new Dictionary<string, AFValue>();

                    double TotalDry = 0;
                    double TotalComp = 0;

                    //calculate each component
                    foreach (string NameSuffix in dAssay.Keys)
                    {

                        AFValue Dry = _APLetheTime.GetAFValuePeriodicorTime(dDryMassVals[NameSuffix], t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                        AFValue Assay = _APLetheTime.GetAFValuePeriodicorTime(dAssayVals[NameSuffix], t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);

                        //20201230 Add separate af value for input of each item, otherwise bad value carries through resulting in No data when some stream are missing
                        // ie conc to POLS but not to USML timeComp object is not used later
                        AFValue CompItem = new AFValue();
                        CompItem.Timestamp = t;
                        CompItem.Attribute = outAttComponent;

                        double? Est = dEstVals[NameSuffix];

                        timeComp.Add(NameSuffix, CalculateComponent(CompItem, Dry, Assay, Est, ref TotalComp,ref TotalDry, ref missingAssay));
                        
                        if (RequireAllInputs & missingAssay)
                        { break; } //some assays are missing and all are required before doing the roll-up
                    }

                    //get inputs to check, per item (name), dry, assay, estimate



                    //RequireAllInputs > 0, groupjoin on name suffix, then check inputs must = 2 where drymass > 0
                    //full list

                    //var Group = dAssay.Keys.GroupJoin()
                    if (RequireAllInputs & missingAssay)
                    {
                        _APLeathAF.ConvertToErrorValue(Component, AFSystemStateCode.NoLabData,null);
                    }
                    else
                    {
                        Component.Value = TotalComp;
                    }
                        

                    results.Add(Component);

                    AFValue RollupAssay = null;

                    if (DoRollupAssay)
                    {
                        RollupAssay = new AFValue();
                        RollupAssay.Timestamp = t;
                        RollupAssay.Attribute = outAttRollupAssay;

                        if (RequireAllInputs & missingAssay)
                        {
                            _APLeathAF.ConvertToErrorValue(RollupAssay, AFSystemStateCode.NoLabData, null);
                        }
                        else
                        {

                            if (TotalDry == 0 | TotalComp == 0)
                            {
                                _APLeathAF.ConvertToErrorValue(RollupAssay, AFSystemStateCode.NoData, null);
                                RollupAssay.Questionable = false;
                            }
                            else
                            {
                                if (IsPercent)
                                {
                                    RollupAssay.Value = TotalComp / TotalDry * 100;
                                }
                                else
                                {
                                    RollupAssay.Value = TotalComp / TotalDry;
                                }
                                RollupAssay.Questionable = Component.Questionable;
                            }

                        }
                        results.Add(RollupAssay);
                    }

                    AFValue RollupDry = null;

                    if (DoRollupDry)
                    {
                        RollupDry = new AFValue();
                        RollupDry.Timestamp = t;
                        RollupDry.Attribute = outAttRollupDry;

                        if (RequireAllInputs & missingAssay)
                        {
                            _APLeathAF.ConvertToErrorValue(RollupDry, AFSystemStateCode.NoLabData, null);
                        }
                        else
                        {
                            RollupDry.Value = TotalDry;

                            RollupDry.Questionable = Component.Questionable;
                        }
                        results.Add(RollupDry);
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
        /// performs the actual moisture calculation taking AFValues as inputs
        /// if component or dry mass is bad then the value is set to 0 with questionable
        /// </summary>
        /// <param name="Result"></param>
        /// <param name="DryMass"></param>
        /// <param name="Assay"></param>
        /// <param name="Estimate"></param>
        public AFValue CalculateComponent(AFValue Component, AFValue DryMass, AFValue Assay, double? Estimate,ref double ComponentTotal,ref double DryMassTotal, ref bool MissingAssay)
        {
            AFValue Result = Component;

            double DM = double.NaN;

            bool IsQuestionable = false;

            //if input drymas or component is questionable o if estimate is used the result is questionable


            if (GetAfValueDouble(out DM, DryMass, null, true))
            {
                if (DM != 0)
                {

                    double As = double.NaN;

                    if (!GetAfValueDouble(out As, Assay, null, true))
                    {
                        // no Assay check estimate
                        if (Estimate.HasValue)
                        {
                            if (!double.IsNaN(Estimate.Value))
                            {
                                //got estimate therefore item is an estimate
                                As = Estimate.Value;
                                IsQuestionable = true;

                                MissingAssay = false;
                            }
                            else { MissingAssay = true; }
                        }
                        else { MissingAssay = true; }
                    }
                    else { MissingAssay = false; }
                                        
                    if (!double.IsNaN(As))
                    {
                        double Comp = 0;
                        if (IsPercent)
                        {
                            Comp = DM * As / 100;
                        }
                        else
                        {
                            Comp = DM * As;
                        }
                        Result.Value = Comp;
                        Result.Questionable = IsQuestionable;

                        ComponentTotal += Comp;
                    }
                    else
                    {
                        //bad value or missing value from moisture mass use its error state if it has one
                        _APLeathAF.ConvertToErrorValue(Result, AFSystemStateCode.Bad, Assay);
                        Log.Debug(" Error on calc '{0}' Assay is missing or bad for attribute {1}", Element.GetPath(), Component.Attribute.Name);
                    }
                }
                else
                {
                    Result.Value = 0;
                    MissingAssay = false;
                }

                DryMassTotal += DM;
            }
            else
            {
                //bad value or missing value from wet mass use its error state if it has one
                _APLeathAF.ConvertToErrorValue(Result, AFSystemStateCode.Bad, DryMass);
                Log.Debug(" Error on calc '{0}' Dry Mass is missing or bad for attribute {1}", Element.GetPath(), Component.Attribute.Name);
            }


            return Result;

        }

        /// <summary>
        /// finds the list of afValues in the outputs based on the name suffex, or null
        /// </summary>
        /// <param name="SearchName"></param>
        /// <param name="AttributeListForInput"></param>
        /// <param name="Data"></param>
        /// <returns></returns>
        private AFValues GetValuesFromList(string SearchName, Dictionary<string, AFAttribute> AttributeListForInput, List<AFValues> Data)
        {
            
            //is there an estimate attribute
            if (AttributeListForInput.ContainsKey(SearchName))
            {
                //does AFValues contain values
                if (Data != null)
                {
                    if (Data.Count() > 0)
                    {

                        //return Data.Where(a => a.Attribute.Name == AttributeListForInput[SearchName].Name);
                        foreach (AFValues afVals in Data)
                        {
                            if (afVals.Attribute.Name == AttributeListForInput[SearchName].Name)
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
