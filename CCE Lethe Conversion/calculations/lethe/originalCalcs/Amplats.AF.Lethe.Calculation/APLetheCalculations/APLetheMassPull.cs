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
    public class APLetheMassPull : LetheCalculation
    {
        public TimeSpan CalculationPeriod { get; set; }
        public TimeSpan CalculatAtTime { get; set; }
        public Int32 CalculationPeriodOffset { get; set; }
        public Int32 CalulationPeriodsToRun { get; set; }

        private string AttNameCalculationPeriod = "CalculationPeriod";
        private string AttNameCalculateAtTime = "CalculateAtTime";
        private string AttNameCalculationPeriodOffset = "CalculationPeriodOffset";
        private string AttNameCalculationPeriodsToRun = "CalculationPeriodsToRun";

        private string AttCalcProduct = "Product";
        private string AttCalcFeed = "Feed";
        private string AttCalcMassPull = "MassPull";

        private AFAttributeList DataRangeInputAttributes = new AFAttributeList();

        private AFAttribute outAttMassPull;


        /// <summary>
        /// 
        /// </summary>
        public APLetheMassPull() : base() { }

        /// <summary>
        /// construct calc
        /// </summary>
        /// <param name="CalculationElement"></param>
        public APLetheMassPull(AFElement CalculationElement) : base(CalculationElement) { }

        /// <summary>
        /// initialize the calculation specific variables
        /// </summary>
        public override void CalculationInitialize()
        {
            try
            {

                Log.Info("Calculation APLetheMassPull initialization starting for:'{0}'", Element.GetPath());

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
                    AddAttributeToList( DataRangeInputAttributes, AttCalcProduct, true);
                    AddAttributeToList( DataRangeInputAttributes, AttCalcFeed, true);

                    //output attribute
                    outAttMassPull = GetAttribute(AttCalcMassPull, true);

            }
            catch(Exception e)
            {
                Log.Fatal(e, "Calculation MassPull Initialize Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
                throw new Exception("Calculation MassPull Initialization error", e.InnerException);

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

                // 
                AFValues valsProduct = new AFValues();
                valsProduct.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcProduct));
                // 
                AFValues valsFeed = new AFValues();
                valsFeed.AddRange(rawInputs.Single(r => r.Attribute.Name == AttCalcFeed));

                rawInputs.Clear();


                // run calculation, substitute estimate and set to questionable if estimate can be used

                foreach (AFTime t in TimeList)
                {
                    // get inputs for time
                    // WetMass
                    AFValue MassPull = new AFValue();
                    MassPull.Timestamp = t;
                    MassPull.Attribute = outAttMassPull;

                    AFValue Feed = _APLetheTime.GetAFValuePeriodicorTime(valsFeed, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);
                    AFValue Prod = _APLetheTime.GetAFValuePeriodicorTime(valsProduct, t, AFSystemStateCode.NoData, CalculatAtTime, CalculationPeriod);

                    CalculateMassPull(MassPull, Feed, Prod);

                    results.Add(MassPull);

                }

            }
            catch (Exception e)
            {
                Log.Fatal(e, "Calculation MassPull Error on '{0}'. Message: {1} ", Element.GetPath(), e.Message);
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
        /// <param name="MassPull"></param>
        /// <param name="inFeed"></param>
        /// <param name="inProduct"></param>
        /// <param name="Estimate"></param>
        public void CalculateMassPull( AFValue MassPull,  AFValue inFeed, AFValue inProduct)
        {

            double Fe = double.NaN;
            double Pr = double.NaN;
            bool IsQuestionable = false;

            //check inputs
            Dictionary<string, Tuple<bool,AFValue>> Validate = new Dictionary<string,Tuple<bool,AFValue>>();           
            Validate.Add(AttCalcFeed, new Tuple<bool,AFValue>(GetAfValueDouble(out Fe, inFeed, null, true), inFeed));
            Validate.Add(AttCalcProduct, new Tuple<bool,AFValue>(GetAfValueDouble(out Pr, inProduct, null, true), inProduct));

            if (!Validate.Values.Any(r => r.Item1 == false))
            {
                //roll up questionable from input - if one is based on estimate
                IsQuestionable = Validate.Values.Any(r => r.Item1 == true);

                if (Fe != 0)
                {
                    MassPull.Value = Pr/Fe * 100;
                    MassPull.Questionable = IsQuestionable;
                }
                else
                {
                    _APLeathAF.ConvertToErrorValue(MassPull, AFSystemStateCode.Bad, null);

                }

            }
            else
            {
                //got a bad or missing input
                //build output string from bad list
                StringBuilder Messagebuilder = new StringBuilder();
                // Append to StringBuilder.
                Messagebuilder.Append(String.Format(" Error on MassPull calc for '{0}' at '{1}': ", Element.GetPath(), MassPull.Timestamp.LocalTime.ToString()));

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

                _APLeathAF.ConvertToErrorValue(MassPull, AFSystemStateCode.Bad, inFeed);
                Log.Debug(Messagebuilder);
            }
        }


    }
}
