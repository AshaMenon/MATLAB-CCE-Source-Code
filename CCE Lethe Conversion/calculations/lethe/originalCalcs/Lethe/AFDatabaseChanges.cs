using Amplats.AF.Lethe.Factory;
using OSIsoft.AF;
using OSIsoft.AF.Asset;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Amplats.AF.Lethe
{
    class AFDatabaseChanges
    {
        #region Fields
        private Object _Cookie;         // AF change detection token
        private AFDatabase _AFDatabase;
        private CalculationJobManager _CalcJobManager;
        private AFElementTemplate _AFCalcTemplate;
        #endregion

        public AFDatabaseChanges(AppSettings Settings, CalculationJobManager CalcJobManager)
        {
            _CalcJobManager = CalcJobManager;
            _AFDatabase = AFConnection.Connect(Settings.AFDatabaseURI);
            _AFCalcTemplate = _AFDatabase.ElementTemplates[Settings.BaseTemplateName];
            // Generate a baseline cookie
            var changes = _AFDatabase.FindChangedItems(false, int.MaxValue, DateTime.Now, out _Cookie);
        }

        public void CheckUpdates()
        {
            //TODO: investigate what would happen if a large number of changes occurred.
            var changes = _AFDatabase.FindChangedItems(false, int.MaxValue, _Cookie, out _Cookie);

            if (changes.Count > 0)
            {
                ApplyUpdates(changes);
            }
        }

        private void ApplyUpdates(IList<AFChangeInfo> Changes)
        {
            // Get a list of all the derived templates
            var derivedTemplates = _AFCalcTemplate.FindDerivedTemplates(true, AFSortField.Name, AFSortOrder.Ascending, int.MaxValue);

            var changedElements = (from c in Changes
                                   where c.Identity == AFIdentity.Element
                                   && (c.Action == AFChangeInfoAction.Added
                                   || c.Action == AFChangeInfoAction.Updated)
                                   select c).ToList();
            var removedElements = (from c in Changes
                                   where c.Identity == AFIdentity.Element
                                   && c.Action == AFChangeInfoAction.Removed
                                   select c).ToList();

            foreach (var e in removedElements)
            {
                _CalcJobManager.RemoveCalculationJob(e.ID);
            }

            foreach (var e in changedElements)
            {
                AFElement element = AFElement.FindElement(_AFDatabase.PISystem, e.ID);
                element.Refresh();  // ensure that the element has been reloaded to the cache
                _CalcJobManager.RemoveCalculationJob(e.ID);     // in the event that the template was changed
                if (IsCalcElement(element, derivedTemplates))
                {
                    _CalcJobManager.AddJob(element);
                }
            }
        }

        private bool IsCalcElement(AFElement Element, AFNamedCollectionList<AFElementTemplate> DerivedTemplates)
        {
            if (Element == null)
            {
                return false;
            }

            AFElementTemplate template = Element.Template;
            if (template == null)
            {
                return false;
            }

            bool isDerived = DerivedTemplates.Any(t => t.Name == template.Name);

            if (isDerived)
            {
                return true;
            }
            else
            {
                return false;
            }            
        }
    }
}
