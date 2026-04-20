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
    public class APLetheDryMass : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 CalculationPeriodOffset { get; set; }
        public Int32 CalulationPeriodsToRun { get; set; }

        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttNameCalculationPeriodOffset = "CalculationPeriodOffset";
        private string AttNameCalculationPeriodsToRun = "CalculationPeriodsToRun";

        private string AttCalcEstimate = "Estimate";
        private string AttCalcMoisture = "Moisture";
        private string AttCalcWetMass = "WetMass";
        private string AttCalcDryMass = "DryMass";
        private string AttCalcWater = "Water";

        private AFAttributeList DataRangeInputAttributes = new AFAttributeList();
        private AFAttribute inAttEstimate;
        private AFAttribute outAttDryMass;
        private AFAttribute outAttWater = null;

        private bool calculateWithEstimates = false;
        private bool DoWater = false;

        /// <summary>
        /// 
        /// </summary>
        public APLetheDryMass() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLetheDryMass(AFElement CalculationElement) : base(CalculationElement) { }

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


                    //get cal12culation attributes

                    //If there is an estimate attribute then estimated values are written out, otherwise only existing values are written out
                    inAttEstimate = GetAttribute(AttCalcEstimate, true);

                    //if attribute is a pi point then use estimates
                    calculateWithEstimates = _APLeathAF.CheckPIDataReference(inAttEstimate);

                    //input range attributes
                    AddAttributeToList( DataRangeInputAttributes, AttCalcMoisture, true);
                    AddAttributeToList( DataRangeInputAttributes, AttCalcWetMass, true);

                    //output attribute
                    outAttDryMass = GetAttribute(AttCalcDryMass, true);

                    outAttWater = GetAttribute(AttCalcWater, true);

                    //if attribute is a pi point then use calculate water
                    DoWater = _APLeathAF.CheckPIDataReference(outAttWater);

                    //WetMass
                    //Drymass
                    //moisture
                    //estimate
                    //conversion
            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation DryMass Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation DryMass Initialization error", e.InnerException);

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

                // Filter Expression
                //A string containing a filter expression. Expression variables are relative to the attribute. Use '.' to reference the containing attribute.
                // get the attribute values where the values are good and the time has 1 second "BadVal('.') = 1 and Second('*') <> 1",

                List<AFValues> rawInputs = new List<AFValues>(DataRangeInputAttributes.Data.RecordedValues(afRange, AFBoundaryType.Outside, "BadVal('.') = 0", false, page));

                // Moisture
                AFValues valsMoisture = new AFValues();
                valsMoisture.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcMoisture));
                // WetMass
                AFValues valsWetMass = new AFValues();
                valsWetMass.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcWetMass));

                rawInputs.Clear();

                double? Estimate = null;

                if (calculateWithEstimates)
                {
                    // need to not get bad values
                    AFValues est = new AFValues();
                    est.AddRange(inAttEstimate.Data.RecordedValuesByCount(new AFTime(DateTime.Now), 1, false, AFBoundaryType.Inside, null, "BadVal('.') = 0", false));

                    if (est.Count() == 0) // if no good last value try next good value
                    {
                        est.AddRange(inAttEstimate.Data.RecordedValuesByCount(new AFTime(DateTime.Now), 1, true, AFBoundaryType.Inside, null, "BadVal('.') = 0", false));
                    }

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
                    AFValue DryMass = new AFValue();
                    DryMass.Timestamp = t;
                    DryMass.Attribute = outAttDryMass;

                    AFValue Water = null;


                    if (DoWater)
                    {
                        Water = new AFValue();
                        Water.Timestamp = t;
                        Water.Attribute = outAttWater;
                    }


                    AFValue Wet = _APLetheTime.GetAFValuePeriodicorTime(valsWetMass, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                    AFValue Moisture = _APLetheTime.GetAFValuePeriodicorTime(valsMoisture, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);

                    CalculateDryMass(DryMass, Water, Wet, Moisture, Estimate);

                    results.Add(DryMass);

                    if (DoWater)
                    {
                        results.Add(Water);
                    }

                }

            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
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
        /// <param name="DryMass"></param>
        /// <param name="WetMass"></param>
        /// <param name="Moisture"></param>
        /// <param name="Estimate"></param>
        public void CalculateDryMass( AFValue DryMass, AFValue Water, AFValue WetMass, AFValue Moisture, double? Estimate)
        {

            double WM = double.NaN;

            bool IsQuestionable = false;

            if (GetAfValueDouble(out WM, WetMass, null, true))
            {
                if (WM != 0)
                {
                    //moisture

                    double Mo = double.NaN;

                    if (!GetAfValueDouble(out Mo, Moisture, null, true))
                    {
                        // no moisture check estimate
                        if (Estimate.HasValue)
                        {
                            //got estimate therefore item is an estimate
                            Mo = Estimate.Value;
                            IsQuestionable = true;
                        }
                    }

                    if (!double.IsNaN(Mo))
                    {
                        DryMass.Value = WM * (1 - Mo / 100);
                        DryMass.Questionable = IsQuestionable;
                        if (Water != null)
                        {
                            Water.Value = WM - DryMass.ValueAsDouble();
                            Water.Questionable = IsQuestionable;
                        }
                    }
                    else
                    {
                        //bad value or missing value from moisture mass use its error state if it has one
                        _APLeathAF.ConvertToErrorValue(DryMass, AFSystemStateCode.Bad, Moisture);
                        if (Water != null) { _APLeathAF.ConvertToErrorValue(Water, AFSystemStateCode.Bad, Moisture); }
                        Log.Debug(" Error on calc '{0}' moisture is missing or bad", Element.GetPath());
                    }
                }
                else
                {
                    DryMass.Value = 0;
                    if (Water != null) { Water.Value = 0; }
                }
            }
            else
            {
                //bad value or missing value from wet mass use its error state if it has one
                _APLeathAF.ConvertToErrorValue(DryMass, AFSystemStateCode.Bad, WetMass);
                if (Water != null) { _APLeathAF.ConvertToErrorValue(Water, AFSystemStateCode.Bad, WetMass); }
                Log.Debug(" Error on calc '{0}' Wet Mass is missing or bad", Element.GetPath());
            }

        }

    }
}
