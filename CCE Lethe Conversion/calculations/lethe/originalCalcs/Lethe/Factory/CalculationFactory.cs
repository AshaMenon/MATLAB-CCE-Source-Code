using OSIsoft.AF.Asset;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Amplats.AF.Lethe.Calculation;
using NLog;

namespace Amplats.AF.Lethe.Factory
{
    /// <summary>
    /// Factory pattern to handle the creation of the 
    /// calculation classes based on the Element Template type.
    /// </summary>
    public class CalculationFactory
    {
        #region Private Fields
        private const string _CalcNameSpace = "Amplats.AF.Lethe.Calculation.";
        private static Logger Log = LogManager.GetCurrentClassLogger();
        #endregion

        #region Public Methods
        public LetheCalculation Create(AFElement Element)
        {
            Type calcClass = GetClass(Element);

            object[] args = { Element };

            return (LetheCalculation)Activator.CreateInstance(calcClass, args);
        }
        #endregion

        #region Private Methods
        public Type GetClass(AFElement Element)
        {
            Type calcClass;
            if (Element.Template == null)
            {
                Log.Warn("The element ({0}) must have a template.", Element.Name);
                throw new ArgumentNullException("Element {0} does not have a template defined.");
            }

            string calcClassName;
            // Check if there is an extended property 
            var customClassName = Element.ExtendedProperties["Lethe.Class"];

            if ((customClassName != null) && customClassName.GetType() == typeof(string))
            {
                calcClassName = "Amplats.AF.Lethe.Calculation." + customClassName;
            }
            else
            {
                calcClassName = "Amplats.AF.Lethe.Calculation." + Element.Template.Name;
            }

            var asm = CalculationsLoader.Load();
            calcClass = asm.GetType(calcClassName);

            if (calcClass == null)
            {
                Log.Warn("Unabled to find an appropriate calculation for {0} with template {1}.", Element.Name, Element.Template.Name);
            }

            return calcClass;
        }

        #endregion
    }
}
