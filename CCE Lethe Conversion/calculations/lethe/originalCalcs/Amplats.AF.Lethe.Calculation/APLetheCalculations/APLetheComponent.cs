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
    public class APLetheComponent : LetheCalculation
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

        private string AttCalcEstimate = "Estimate";
        private string AttCalcAssay = "Assay";
        private string AttCalcDryMass = "DryMass";
        private string AttCalcComponent = "Component";
        //private string AttCalcRollupAssay = "RollupAssay";

       // private AFAttributeList DataRangeInputAttributes = new AFAttributeList();
        private AFAttribute inAttEstimate;
        private AFAttribute outAttComponent;
        //private AFAttribute outAttRollupAssay = null;

        //get collated set of input attributes keyed by name with data collection type and 
        Dictionary<string, Tuple<string, AFAttribute>> dSubstitutes = new Dictionary<string, Tuple<string, AFAttribute>>();

        private bool calculateWithEstimates = false;
        //private bool DoRollupAssay = false;

        /// <summary>
        /// 
        /// </summary>
        public APLetheComponent() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLetheComponent(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// </summary>
        /// <remarks>
        /// 2017-01-16 Changed input attribute collection to use _APLeathAF.GetInputAttributes, this allows using attribute values as well as recorded values 
        /// </remarks>
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

                    //get cal12culation attributes

                    //If there is an estimate attribute then estimated values are written out, otherwise only existing values are written out
                    inAttEstimate = GetAttribute(AttCalcEstimate, true);

                    //if attribute is a pi point then use estimates
                    calculateWithEstimates = _APLeathAF.CheckPIDataReference(inAttEstimate);

                    //input range attributes - old removed 13 January 2017
                    //AddAttributeToList( DataRangeInputAttributes, AttCalcAssay, true);
                    //AddAttributeToList( DataRangeInputAttributes, AttCalcDryMass, true);

                    dSubstitutes = _APLeathAF.GetInputAttributes(Element.Attributes);

                    //output attribute
                    outAttComponent = GetAttribute(AttCalcComponent, true);


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

                // Filter Expression-old removed 13 January 2017
                //A string containing a filter expression. Expression variables are relative to the attribute. Use '.' to reference the containing attribute.
                // get the attribute values where the values are good and the time has 1 second "BadVal('.') = 1 and Second('*') <> 1",
                //List<AFValues> rawInputs = new List<AFValues>(DataRangeInputAttributes.Data.RecordedValues(afRange, AFBoundaryType.Outside, "BadVal('.') = 0", false, page));
 
                Dictionary<string, AFValues> dSubstituteVals = _APLeathAF.GetInputAttributeValuesToDictionary(dSubstitutes, afRange, TimeList, CalculationPeriod);

                // Moisture
                AFValues valsAssay = new AFValues();
                valsAssay.AddRange(dSubstituteVals[AttCalcAssay.ToLower()]); //-old removed 13 January 2017 // rawInputs.Single(r => r.Attribute.Name == AttCalcAssay));
                // WetMass
                AFValues valsDryMass = new AFValues();
                valsDryMass.AddRange(dSubstituteVals[AttCalcDryMass.ToLower()]); //-old removed 13 January 2017 // rawInputs.Single(r => r.Attribute.Name == AttCalcDryMass));

                //rawInputs.Clear();
                //dSubstituteVals.Clear();

                double? Estimate = null;

                if (calculateWithEstimates)
                {
                    // need to not get bad values
                    AFValues est = new AFValues();
                    est.AddRange(dSubstituteVals[AttCalcEstimate.ToLower()]); //inAttEstimate.Data.RecordedValuesByCount(new AFTime(DateTime.Now), 1, false, AFBoundaryType.Inside, null, "BadVal('.') = 0", false));

                    //Estimate = GetAfValueInt32(SingleValueInputAttributes[AttCalcEstimate].GetValue(), null);

                    if (est.Count() > 0)
                    {

                        double afRes;
                        if (GetAfValueDouble(out afRes, est.OrderByDescending(v => v.Timestamp.LocalTime).First(), null, true))
                        {
                            Estimate = afRes;
                        }
                        else
                        {
                            Estimate = null;
                        }

                    }

                }

                // run calculation, substitute estimate and set to questionable if estimate can be used


                foreach (AFTime t in TimeList)
                {
                    // get inputs for time
                    // WetMass
                    AFValue Component = new AFValue();
                    Component.Timestamp = t;
                    Component.Attribute = outAttComponent;


                    AFValue Dry = _APLetheTime.GetAFValuePeriodicorTime(valsDryMass, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                    AFValue Assay = _APLetheTime.GetAFValuePeriodicorTime(valsAssay, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);

                    CalculateComponent(Component, Dry, Assay, Estimate);

                    results.Add(Component);

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
        /// </summary>
        /// <param name="Component"></param>
        /// <param name="DryMass"></param>
        /// <param name="Assay"></param>
        /// <param name="Estimate"></param>
        public void CalculateComponent( AFValue Component, AFValue DryMass, AFValue Assay, double? Estimate)
        {

            double DM = double.NaN;

            bool IsQuestionable = false;

            if (GetAfValueDouble(out DM, DryMass, null, true))
            {
                if (DM != 0)
                {
                    //moisture

                    double As = double.NaN;

                    if (!GetAfValueDouble(out As, Assay, null, true))
                    {
                        // no moisture check estimate
                        if (Estimate.HasValue)
                        {
                            //got estimate therefore item is an estimate
                            As = Estimate.Value;
                            IsQuestionable = true;
                        }
                    }

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
                        Component.Value = Comp;
                        Component.Questionable = IsQuestionable;

                    }
                    else
                    {
                        //bad value or missing value from moisture mass use its error state if it has one
                        _APLeathAF.ConvertToErrorValue(Component, AFSystemStateCode.Bad, Assay);
                        Log.Debug(" Error on calc '{0}' Assay is missing or bad", Element.GetPath());
                    }
                }
                else
                {
                    Component.Value = 0;
                    //if (RollupComponent != null) { RollupComponent.Value = 0; }
                }
            }
            else
            {
                //bad value or missing value from wet mass use its error state if it has one
                _APLeathAF.ConvertToErrorValue(Component, AFSystemStateCode.Bad, DryMass);
               // if (RollupComponent != null) { _APLeathAF.ConvertToErrorValue(RollupComponent, AFSystemStateCode.Bad, DryMass); }
                Log.Debug(" Error on calc '{0}' Dry Mass is missing or bad", Element.GetPath());
            }

        }

    }
}
