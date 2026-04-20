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
    public class APLetheAssay : LetheCalculation
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

        private string AttCalcComponent = "Component";
        private string AttCalcDryMass = "DryMass";
        private string AttCalcAssay = "Assay";

        private AFAttributeList DataRangeInputAttributes = new AFAttributeList();
        private AFAttribute outAttAssay;


        /// <summary>
        /// 
        /// </summary>
        public APLetheAssay() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLetheAssay(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// </summary>
        public override void CalculationInitialize()
        {
            try
            {

                    Log.Info("Calculation Assay initialization starting for:'{0}'", Element.GetPath());

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

                    //input range attributes
                    AddAttributeToList( DataRangeInputAttributes, AttCalcComponent, true);
                    AddAttributeToList( DataRangeInputAttributes, AttCalcDryMass, true);

                    //output attribute
                    outAttAssay = GetAttribute(AttCalcAssay, true);

                    //outAttRollupAssay = GetAttribute(AttCalcRollupAssay, true);

                    //if attribute is a pi point then use calculate water
                    //DoRollupAssay = _APLeathAF.CheckPIDataReference(outAttRollupAssay);

                    //WetMass
                    //Drymass
                    //moisture
                    //estimate
                    //conversion
            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation Assay Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation Assay Initialization error", e.InnerException);

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
                AFValues valsComponent = new AFValues();
                valsComponent.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcComponent));
                // WetMass
                AFValues valsDryMass = new AFValues();
                valsDryMass.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcDryMass));

                rawInputs.Clear();

                // run calculation, substitute estimate and set to questionable if estimate can be used


                foreach (AFTime t in TimeList)
                {
                    // get inputs for time
                    // WetMass
                    AFValue Assay = new AFValue();
                    Assay.Timestamp = t;
                    Assay.Attribute = outAttAssay;

                    AFValue Dry = _APLetheTime.GetAFValuePeriodicorTime(valsDryMass, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                    AFValue Component = _APLetheTime.GetAFValuePeriodicorTime(valsComponent, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);

                    CalculateAssay(Assay, Dry, Component);

                    results.Add(Assay);

                }

            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation Assay Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
            }


            // the results are automatically written out to the AFAttribute set on the each AFValue 
            return results;

        }

        public override void RefreshElement()
        {
            throw new NotImplementedException();
        }



        public void CalculateAssay(AFValue Assay, AFValue inDryMass, AFValue inComponent)
        {

            double DM = double.NaN;
            double Comp = double.NaN;
            bool IsQuestionable = false;

            //check inputs
            Dictionary<string, Tuple<bool, AFValue>> Validate = new Dictionary<string, Tuple<bool, AFValue>>();
            Validate.Add(AttCalcDryMass, new Tuple<bool, AFValue>(GetAfValueDouble(out DM, inDryMass, null, true), inDryMass));
            Validate.Add(AttCalcComponent, new Tuple<bool, AFValue>(GetAfValueDouble(out Comp, inComponent, null, true), inComponent));

            if (!Validate.Values.Any(r => r.Item1 == false))
            {
                //roll up questionable from input - if one is based on estimate then true.
                IsQuestionable = Validate.Values.Any(r => r.Item1 == true);

                if (DM != 0)
                {
                    if (IsPercent)
                    {
                        Assay.Value = Comp / DM * 100;
                    }
                    else
                    {
                        Assay.Value = Comp / DM;
                    }

                    Assay.Questionable = IsQuestionable;
                }
                else
                {
                    _APLeathAF.ConvertToErrorValue(Assay, AFSystemStateCode.Bad, null);
                }

            }
            else
            {
                //got a bad or missing input
                //build output string from bad list
                StringBuilder Messagebuilder = new StringBuilder();
                // Append to StringBuilder.
                Messagebuilder.Append(String.Format(" Error on Error calc for '{0}' at '{1}': ", Element.GetPath(), Assay.Timestamp.LocalTime.ToString()));

                foreach (KeyValuePair<string, Tuple<bool, AFValue>> InPut in Validate)
                {
                    if (InPut.Value.Item1 == false)
                    {
                        if (InPut.Value.Item2.Value != null)
                        {
                            Messagebuilder.Append(String.Format("; Attribute '{0}' has data of '{1}'", InPut.Key, InPut.Value.Item2.Value.ToString()));
                        }
                        else
                        {
                            Messagebuilder.Append(String.Format("; Attribute '{0}' value is null", InPut.Key));
                        }
                    }
                }

                _APLeathAF.ConvertToErrorValue(Assay, AFSystemStateCode.Bad, inDryMass);
                Log.Debug(Messagebuilder);
            }
        }



    }
}
