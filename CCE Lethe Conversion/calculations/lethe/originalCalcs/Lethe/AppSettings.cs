using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Amplats.AF.Lethe
{
    /// <summary>
    /// Holds the application configuration settings 
    /// loaded from the app.config file
    /// </summary>
    public class AppSettings
    {
        public string AFDatabaseURI { get; set; }
        public string BaseTemplateName { get; set; }

        public string PIServerName { get; set; }

        public string HBPIPointName { get; set; }

        /// <summary>
        /// The frequency at which AF Database changes are checked
        /// </summary>
        public double AFUpdateTimer { get; set; }

    }
}
