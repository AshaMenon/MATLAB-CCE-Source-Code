using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Amplats.AF.Lethe.Calculation.LetheCalculationMethods
{
    public class APLetheGeneral
    {

      
        /// <summary>
        /// checks val to min max, returns fasle if out.
        /// if min = NaN, then val <= Max = true else false
        /// if max = NaN, then val >= Min = true else false
        /// if min and Max = NaN the true
        ///  else min <= val >= Max then true
        ///  converts input to double if this fails returns false
        ///  if input is NaN returns false
        /// </summary>
        /// <param name="Val"></param>
        /// <param name="Min"></param>
        /// <param name="Max"></param>
        /// <returns></returns>
        public bool ChecktoLimits(String Val, double Min, double Max)
        {
            //coerce test val to double for test
            double _testVal = double.NaN;
            bool inOkay = double.TryParse(Val, out _testVal);
            
            if (!inOkay) { return false; }

            if (double.IsNaN(Min) & double.IsNaN(Max)) { return true; }
            else if (double.IsNaN(Min) & !double.IsNaN(Max)) { return _testVal <= Max; }
            else if (double.IsNaN(Max) & !double.IsNaN(Min)) { return Min <= _testVal; }
            else if (!double.IsNaN(Max) & !double.IsNaN(Min)) { return Min <= _testVal & _testVal <= Max; }
            else { return false; }
        }
    }
}
