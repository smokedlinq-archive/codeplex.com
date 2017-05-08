using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.MetadirectoryServices;
using System.IO;
using System.Diagnostics;
using System.Collections;

namespace FIM.PowerShell
{
    public sealed class MASynchronization : PSRuntime, IMASynchronization
    {
        public DeprovisionAction Deprovision(CSEntry csentry)
        {
            using (TraceSource.TraceMethod())
            {
                TraceSource.TraceParameter("csentry", csentry);

                var scriptPath = FindMaScript(csentry.MA.Name, "Deprovision.ps1");

                if (!File.Exists(scriptPath))
                    throw EntryPointNotImplementedException(csentry.MA.Name, "Deprovision.ps1");

                AddScript(scriptPath)
                    .AddParameter("csentry", csentry);

                var action = Invoke<DeprovisionAction>().First();

                TraceSource.TraceObject(action);

                return action;
            }
        }

        public bool FilterForDisconnection(CSEntry csentry)
        {
            using (TraceSource.TraceMethod())
            {
                TraceSource.TraceParameter("csentry", csentry);

                var scriptPath = FindMaScript(csentry.MA.Name, "FilterForDisconnection.ps1");

                if (!File.Exists(scriptPath))
                    throw EntryPointNotImplementedException(csentry.MA.Name, "Deprovision.ps1");

                AddScript(scriptPath)
                    .AddParameter("csentry", csentry);

                var filtered = Invoke<bool>().FirstOrDefault();

                TraceSource.TraceObject(filtered);

                return filtered;
            }
        }

        public void MapAttributesForExport(string flowRuleName, MVEntry mventry, CSEntry csentry)
        {
            using (TraceSource.TraceMethod())
            {
                TraceSource.TraceParameter("flowRuleName", flowRuleName);
                TraceSource.TraceParameter("mventry", mventry);
                TraceSource.TraceParameter("csentry", csentry);
                
                var scriptPath = FindMaScript(csentry.MA.Name, "MapAttributesForExport.ps1");

                if (!File.Exists(scriptPath))
                    throw EntryPointNotImplementedException(csentry.MA.Name, "MapAttributesForExport.ps1");

                AddScript(scriptPath)
                    .AddParameter("FlowRuleName", flowRuleName)
                    .AddParameter("mventry", mventry)
                    .AddParameter("csentry", csentry);

                Invoke();
            }
        }

        public void MapAttributesForImport(string flowRuleName, CSEntry csentry, MVEntry mventry)
        {
            using (TraceSource.TraceMethod())
            {
                TraceSource.TraceParameter("flowRuleName", flowRuleName);
                TraceSource.TraceParameter("mventry", mventry);
                TraceSource.TraceParameter("csentry", csentry);

                var scriptPath = FindMaScript(csentry.MA.Name, "MapAttributesForImport.ps1");

                if (!File.Exists(scriptPath))
                    throw EntryPointNotImplementedException(csentry.MA.Name, "Deprovision.ps1");

                AddScript(scriptPath)
                    .AddParameter("FlowRuleName", flowRuleName)
                    .AddParameter("mventry", mventry)
                    .AddParameter("csentry", csentry);

                Invoke();
            }
        }

        public void MapAttributesForJoin(string flowRuleName, CSEntry csentry, ref ValueCollection values)
        {
            using (TraceSource.TraceMethod())
            {
                TraceSource.TraceParameter("flowRuleName", flowRuleName);
                TraceSource.TraceParameter("csentry", csentry);
                TraceSource.TraceParameter("values", values);

                var scriptPath = FindMaScript(csentry.MA.Name, "MapAttributesForJoin.ps1");

                if (!File.Exists(scriptPath))
                    throw EntryPointNotImplementedException(csentry.MA.Name, "Deprovision.ps1");

                AddScript(scriptPath)
                    .AddParameter("FlowRuleName", flowRuleName)
                    .AddParameter("csentry", csentry)
                    .AddParameter("values", values);

                Invoke();
            }
        }

        public bool ResolveJoinSearch(string joinCriteriaName, CSEntry csentry, MVEntry[] rgmventry, out int imventry, ref string MVObjectType)
        {
            using (TraceSource.TraceMethod())
            {
                TraceSource.TraceParameter("joinCriteriaName", joinCriteriaName);
                TraceSource.TraceParameter("csentry", csentry);
                TraceSource.TraceParameter("rgmventry", rgmventry);

                var scriptPath = FindMaScript(csentry.MA.Name, "ResolveJoinSearch.ps1");

                if (!File.Exists(scriptPath))
                    throw EntryPointNotImplementedException(csentry.MA.Name, "Deprovision.ps1");

                AddScript(scriptPath)
                    .AddParameter("JoinCriteriaName", joinCriteriaName)
                    .AddParameter("csentry", csentry)
                    .AddParameter("rgmventry", rgmventry)
                    .AddParameter("MVObjectType", MVObjectType);

                imventry = Invoke<int>().First();

                TraceSource.TraceObject(imventry);

                return imventry >= 0;
            }
        }

        public bool ShouldProjectToMV(CSEntry csentry, out string MVObjectType)
        {
            using (TraceSource.TraceMethod())
            {
                TraceSource.TraceParameter("csentry", csentry);

                var scriptPath = FindMaScript(csentry.MA.Name, "ShouldProjectToMV.ps1");

                if (!File.Exists(scriptPath))
                    throw EntryPointNotImplementedException(csentry.MA.Name, "Deprovision.ps1");

                AddScript(scriptPath)
                    .AddParameter("csentry", csentry);

                MVObjectType = Invoke<string>().Where(s => !string.IsNullOrWhiteSpace(s)).FirstOrDefault();

                TraceSource.TraceObject(MVObjectType);

                return !string.IsNullOrWhiteSpace(MVObjectType);
            }
        }

        void IMASynchronization.Initialize()
        {
            base.Initialize();
        }

        void IMASynchronization.Terminate()
        {
            base.Dispose();
        }
    }
}
