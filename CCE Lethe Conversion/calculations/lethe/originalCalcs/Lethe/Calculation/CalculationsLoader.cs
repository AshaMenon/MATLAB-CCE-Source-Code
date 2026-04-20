using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace Amplats.AF.Lethe.Calculation
{
    /// <summary>
    /// Load the calculations assembly into the executing program
    /// </summary>
    internal static class CalculationsLoader
    {
        internal static Assembly Load()
        {
            Assembly asm = Assembly.LoadFrom("Amplats.AF.Lethe.Calculation.dll");
            return asm;
        }
    }
}
