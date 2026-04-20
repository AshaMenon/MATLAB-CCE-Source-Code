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


namespace Amplats.AF.Lethe.Calculation.LetheCalculationMethods
{
    public class APLetheAF
    {

        /// <summary>
        /// checks if the passed attribute has a PIPoint data reference 
        /// </summary>
        /// <param name="AFAtt"></param>
        /// <returns></returns>
        public bool CheckPIDataReference(AFAttribute AFAtt)
        {
            if (AFAtt.DataReference == null)
            { return false; }

            if (AFAtt.DataReference.GetType().Name == "PIPointDR")
            { return true; }
            return false;
        }

        /// <summary>
        /// checks if the passed attribute has a Formula data reference 
        /// </summary>
        /// <param name="AFAtt"></param>
        /// <returns></returns>
        public bool CheckFormulaDataReference(AFAttribute AFAtt)
        {
            if (AFAtt.DataReference == null)
            { return false; }

            if (AFAtt.DataReference.GetType().Name == "FormulaDR")
            { return true; }
            return false;
        }
        /// <summary>
        /// method to set AFValue properties for errors
        /// </summary>
        /// <param name="Value"></param>
        /// <param name="Code"></param>
        /// <returns></returns>
        public void ConvertToErrorValue(AFValue Value, AFSystemStateCode Code, AFValue StateToUseIfBad = null)
        {
            Value.IsGood = false;

            //check if there is a referenced afvalue to supply the sate
            if (StateToUseIfBad != null)
            {
                if (!StateToUseIfBad.IsGood)
                {
                    AFSystemStateCode ErrCode = Code;
                    if (Enum.TryParse(StateToUseIfBad.Value.ToString(), out ErrCode))
                    {
                        Code = ErrCode;
                    }
                }
            }

            Value.Value = Code;
            Value.Questionable = false;
        }

        /// <summary>
        /// Get the input attributes to a list with a categorized by collection
        /// </summary>
        /// <param name="InputAFAttributes"></param>
        /// <returns></returns>
        public Dictionary<string, Tuple<string, AFAttribute>> GetInputAttributesWithNameFilter(AFAttributes InputAFAttributes, List<String> FilterList)
        {
            Dictionary<string, Tuple<string, AFAttribute>> InputAttributes = new Dictionary<string, Tuple<string, AFAttribute>>();

            foreach (AFAttribute att in InputAFAttributes)
            {

                if (att.CategoriesString.Contains(LetheCalculation.catAFInput)) // then load with the type of data collection
                {

                    if (FilterList.Contains(att.Name))
                    {
                        InputAttributes.Add(att.Name.ToLower(), CreateConfigFromAttribute(att));
                    }

                }
            }
            return InputAttributes;
        }


        /// <summary>
        /// Get the input attributes to a list with a categorized by collection
        /// </summary>
        /// <param name="InputAFAttributes"></param>
        /// <returns></returns>
        public Dictionary<string, Tuple<string, AFAttribute>> GetInputAttributes(AFAttributes InputAFAttributes)
        {
            Dictionary<string, Tuple<string, AFAttribute>> InputAttributes = new Dictionary<string, Tuple<string, AFAttribute>>();

            foreach (AFAttribute att in InputAFAttributes)
            {
                if (att.CategoriesString.Contains(LetheCalculation.catAFInput)) // then load with the type of data collection
                {
                    InputAttributes.Add(att.Name.ToLower(), CreateConfigFromAttribute(att));
                }

            }

            return InputAttributes;
        }


        /// <summary>
        /// creates the get data configuration from an attribute
        /// set the data extraction to compressed is the data reference is:
        /// PiPoint = compressed 
        /// PIPoint with configuration contains interpolated = Interpolated
        /// Formula = compressed
        /// Rest = Interpolated
        /// </summary>
        /// <param name="InputAFAttribute"></param>
        /// <param name="FilterList"></param>
        /// <returns></returns>
        public Tuple<string, AFAttribute> CreateConfigFromAttribute(AFAttribute InputAFAttribute)
        {
            //assume Compressed/ archive data unless the item is not a PIpoint, or the configuration string contain interpolated
            if (CheckPIDataReference(InputAFAttribute))
            {
                if (InputAFAttribute.CategoriesString.ToLower().Contains(LetheCalculation.catAFInterpolate.ToLower()))
                {
                    return new Tuple<string, AFAttribute>(LetheCalculation.catAFInterpolate, InputAFAttribute);
                }
                else
                {
                    return new Tuple<string, AFAttribute>(LetheCalculation.catAFCompressed, InputAFAttribute);
                }
            }
            else if (CheckFormulaDataReference(InputAFAttribute))
            {
                //default to compressed for formula DR
                if (InputAFAttribute.CategoriesString.ToLower().Contains(LetheCalculation.catAFInterpolate.ToLower()))
                {
                    return new Tuple<string, AFAttribute>(LetheCalculation.catAFInterpolate, InputAFAttribute);
                }
                else
                {
                    return new Tuple<string, AFAttribute>(LetheCalculation.catAFCompressed, InputAFAttribute);
                }

            }
            else
            {
                return new Tuple<string, AFAttribute>(LetheCalculation.catAFInterpolate, InputAFAttribute);
            }

        }




        /// <summary>
        /// get the values for the input attributes, Compressed or Interpolated for the time values
        /// and converts them to a dictionary of AF values keyed by attribute name
        /// </summary>
        /// <param name="InputAttributes"></param>
        /// <param name="CalcRange"></param>
        /// <param name="CalcTimeList"></param>
        /// <param name="CalculationStep"></param>
        /// <returns></returns>
        public Dictionary<string, AFValues> GetInputAttributeValuesToDictionary(Dictionary<string, Tuple<string, AFAttribute>> InputAttributes, AFTimeRange CalcRange, List<AFTime> CalcTimeList, TimeSpan CalculationStep)
        {

            Dictionary<string, AFValues> AttributeValueToName = new Dictionary<string, AFValues>();


            List<AFValues> rawInputs = new List<AFValues>();
           //split input attribute over range in Interpolated and Compressed data extraction
           AFAttributeList DataRangeCompressedInputAttributes = new AFAttributeList();
           AFAttributeList DataRangeInterpolatedInputAttributes = new AFAttributeList();

            DataRangeCompressedInputAttributes.AddRange(InputAttributes.Where(r => r.Value.Item1.Equals(LetheCalculation.catAFCompressed)).Select(r => r.Value.Item2)); //need type
            DataRangeInterpolatedInputAttributes.AddRange(InputAttributes.Where(r => r.Value.Item1.Equals(LetheCalculation.catAFInterpolate)).Select(r => r.Value.Item2));

            if (DataRangeCompressedInputAttributes.Count > 0)
            {

                PIPagingConfiguration pageC = new PIPagingConfiguration(PIPageType.EventCount, 1);
                rawInputs.AddRange(DataRangeCompressedInputAttributes.Data.RecordedValues(CalcRange, AFBoundaryType.Outside, null, false, pageC));// "BadVal('.') = 0", false, pageC));

            }

            if (DataRangeInterpolatedInputAttributes.Count > 0)
            {

                PIPagingConfiguration pageI = new PIPagingConfiguration(PIPageType.EventCount, 1);
                rawInputs.AddRange(DataRangeInterpolatedInputAttributes.Data.InterpolatedValuesAtTimes(CalcTimeList, null, true, pageI)); // "BadVal('.') = 0", false, pageI));
                
                //rawInputs.AddRange(DataRangeInterpolatedInputAttributes.Data.InterpolatedValues(CalcRange, new AFTimeSpan(CalculationStep), null, false, pageI)); // "BadVal('.') = 0", false, pageI));
                                                                                                                                                                  //rawInputs.AddRange(DataRangeInterpolatedInputAttributes.Data.RecordedValuesAtTimes(TimeList, AFRetrievalMode.Before, pageI));
                //rawInputs.AddRange(DataRangeInterpolatedInputAttributes.Data.RecordedValuesAtTimes(CalcTimeList, AFRetrievalMode.Exact, pageC));// "BadVal('.') = 0", false, pageC));

                //run get values per attribute
                //AFAttribute atts = new AFAttribute();

            }


            //produce a keyed Dictionary of input attribute values, keyed on name
            foreach (String AttName in InputAttributes.Keys)
            {
                // add AFValues or null
                AttributeValueToName.Add(AttName, GetAFValuesFromList(AttName, InputAttributes, rawInputs));

            }

            return AttributeValueToName;




        }



        /// <summary>
        /// finds the list of afValues in the outputs based on the name
        /// </summary>
        /// <param name="SearchName"></param>
        /// <param name="AttributeListForInput"></param>
        /// <param name="Data"></param>
        /// <returns></returns>
        private AFValues GetAFValuesFromList(String SearchName, Dictionary<String, Tuple<string, AFAttribute>> AttributeListForInput, List<AFValues> Data)
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
                            if (afVals.Attribute.Name == AttributeListForInput[SearchName].Item2.Name)
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
        /// gets a list of the good inputs (value, time and attribute name) for an attribute in the period based on the calculation time, the time interval.
        /// If force time collation is true, then all input values for the different attributes must have matching times, otherwise no values are returned
        /// </summary>
        /// <param name="AttributeNames"></param>
        /// <param name="dSubstituteVals"></param>
        /// <param name="CurrentCalcTime"></param>
        /// <param name="CalculatTimeDailyOffset"></param>
        /// <param name="CalculationPeriod"></param>
        /// <param name="ForceTimeCollation"></param>
        /// <returns></returns>
        public List<Tuple<double, AFTime, string>> GetGoodItemsInPeriod(List<string> AttributeNames, Dictionary<string, AFValues> dSubstituteVals, AFTime CurrentCalcTime, TimeSpan CalculatTimeDailyOffset, TimeSpan CalculationPeriod, Boolean ForceTimeCollation = false)
        {

            List<Tuple<double, AFTime, string>> GoodInputsInPeriod = new List<Tuple<double, AFTime, string>>();

            List<AFTime> InputTimeList = null;
            foreach (String NameString in AttributeNames.OrderBy(k => k))
            {
                //get input values for 
                List<Tuple<double, AFTime, string>> GoodInputs = APLetheTime.GetValuesInPeriod(dSubstituteVals[NameString], CurrentCalcTime, CalculatTimeDailyOffset, CalculationPeriod);


                if (ForceTimeCollation)
                {
                    if (InputTimeList == null)
                    {
                        //first run
                        InputTimeList = GoodInputs.Select(tu => tu.Item2).ToList();
                        if (InputTimeList.Count() == 0)
                        {
                            //no values and collated times are required therefor no data for time period
                            break;
                        }
                    }
                    else
                    {
                        if (!APLetheTime.DoTimesCollate(InputTimeList, GoodInputs.Select(tu => tu.Item2).ToList()))
                        {
                            // time do not match - missing or bad items, clear all data to force to zero or bad then exit.
                            GoodInputsInPeriod.Clear();
                            break;
                        }

                    }

                }

                //add good items to total list of good items
                GoodInputsInPeriod.AddRange(GoodInputs); //.Select(tu => tu.Item1));
            }

            return GoodInputsInPeriod;
        }

    }
}
