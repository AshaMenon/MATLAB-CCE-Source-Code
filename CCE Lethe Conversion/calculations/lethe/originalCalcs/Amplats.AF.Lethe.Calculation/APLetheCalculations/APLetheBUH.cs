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
    public class APLetheBUH : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 CalculationPeriodOffset { get; set; }
        public Int32 CalulationPeriodsToRun { get; set; }

        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttNameCalculationPeriodOffset = "CalculationPeriodOffset";
        private string AttNameCalculationPeriodsToRun = "CalculationPeriodsToRun";

        private string AttCalcProductComp = "ProductComp";
        private string AttCalcWasteComp = "WasteComp";
        private string AttCalcFeed = "Feed";
        private string AttCalcBUH = "BUH";



        private AFAttributeList DataRangeInputAttributes = new AFAttributeList();

        private AFAttribute outAttBUH;


        /// <summary>
        /// 
        /// </summary>
        public APLetheBUH() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLetheBUH(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// </summary>
        public override void CalculationInitialize()
        {
            try
            {

                Log.Info("Calculation APLetheBUH initialization starting for:'{0}'", Element.GetPath());

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

                    //input range attributes
                    AddAttributeToList( DataRangeInputAttributes, AttCalcProductComp, true);
                    AddAttributeToList( DataRangeInputAttributes, AttCalcWasteComp, true);
                    AddAttributeToList(DataRangeInputAttributes, AttCalcFeed, true);
                    //output attribute
                    outAttBUH = GetAttribute(AttCalcBUH, true);

            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation BUH Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation BUH Initialization error", e.InnerException);

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
                AFValues valsProductComp = new AFValues();
                valsProductComp.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcProductComp));
                // WetMass
                AFValues valsWasteComp = new AFValues();
                valsWasteComp.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcWasteComp));

                AFValues valsFeed = new AFValues();
                valsFeed.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcFeed));

                rawInputs.Clear();


                // run calculation, substitute estimate and set to questionable if estimate can be used

                foreach (AFTime t in TimeList)
                {
                    // get inputs for time
                    // WetMass
                    AFValue BUH = new AFValue();
                    BUH.Timestamp = t;
                    BUH.Attribute = outAttBUH;

                    AFValue WasteComp = _APLetheTime.GetAFValuePeriodicorTime(valsWasteComp, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                    AFValue Prod = _APLetheTime.GetAFValuePeriodicorTime(valsProductComp, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                    AFValue Feed = _APLetheTime.GetAFValuePeriodicorTime(valsFeed, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                    CalculateBUH(BUH, WasteComp, Prod, Feed);

                    results.Add(BUH);

                }

            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation BUH Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
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
        /// <param name="ProductComp"></param>
        /// <param name="inWasteComp"></param>
        /// <param name="inProductComp"></param>
        /// <param name="Estimate"></param>
        public void CalculateBUH( AFValue BUH,  AFValue inWasteComp, AFValue inProductComp, AFValue inFeed)
        {

            double Wa = double.NaN;
            double Pr = double.NaN;
            double Fe = double.NaN;
            bool IsQuestionable = false;

            //check inputs
            Dictionary<string, Tuple<bool,AFValue>> Validate = new Dictionary<string,Tuple<bool,AFValue>>();
            Validate.Add(AttCalcWasteComp, new Tuple<bool, AFValue>(GetAfValueDouble(out Wa, inWasteComp, null, true), inWasteComp));
            Validate.Add(AttCalcProductComp, new Tuple<bool, AFValue>(GetAfValueDouble(out Pr, inProductComp, null, true), inProductComp));
            Validate.Add(AttCalcFeed, new Tuple<bool, AFValue>(GetAfValueDouble(out Fe, inFeed, null, true), inFeed));

            if (!Validate.Values.Any(r => r.Item1 == false))
            {
                //roll up questionable from input - if one is based on estimate then true.
                IsQuestionable = Validate.Values.Any(r => r.Item1 == true);

                if (Fe != 0)
                {
                    BUH.Value = (Wa + Pr)/Fe;
                    BUH.Questionable = IsQuestionable;
                }
                else
                {
                    _APLeathAF.ConvertToErrorValue(BUH, AFSystemStateCode.Bad, null);
                }

            }
            else
            {
                //got a bad or missing input
                //build output string from bad list
                StringBuilder Messagebuilder = new StringBuilder();
                // Append to StringBuilder.
                Messagebuilder.Append(String.Format(" Error on BUH calc for '{0}' at '{1}': ", Element.GetPath(), BUH.Timestamp.LocalTime.ToString()));

                foreach (KeyValuePair<string, Tuple<bool,AFValue>> InPut in Validate)
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

                _APLeathAF.ConvertToErrorValue(BUH, AFSystemStateCode.Bad, inWasteComp);
                Log.Debug(Messagebuilder);
            }
        }


    }
}
