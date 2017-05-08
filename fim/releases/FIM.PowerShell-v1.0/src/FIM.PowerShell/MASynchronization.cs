using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.MetadirectoryServices;
using System.IO;

namespace FIM.PowerShell
{
    public sealed class MASynchronization : FIMPowerShell, IMASynchronization
    {
        public DeprovisionAction Deprovision(CSEntry csentry)
        {
            string scriptPath = FIMUtils.GetMaScriptPath(csentry.MA.Name, "Deprovision.ps1");

            if (!File.Exists(scriptPath))
            {
                throw new EntryPointNotImplementedException();
            }

            var obj = this.Invoke(this.CreateRuntime(scriptPath)
                                        .AddParameter("csentry", csentry))
                        .FirstOrDefault();

            if (obj != null)
            {
                if (obj.BaseObject is DeprovisionAction)
                {
                    return (DeprovisionAction)obj.BaseObject;
                }

                if (obj.BaseObject is string)
                {
                    return (DeprovisionAction)Enum.Parse(typeof(DeprovisionAction), (string)obj.BaseObject, true);
                }
            }

            throw new EntryPointNotImplementedException();
        }

        public bool FilterForDisconnection(CSEntry csentry)
        {
            string scriptPath = FIMUtils.GetMaScriptPath(csentry.MA.Name, "FilterForDisconnection.ps1");

            if (!File.Exists(scriptPath))
            {
                throw new EntryPointNotImplementedException();
            }

            return this.Invoke<bool>(this.CreateRuntime(scriptPath)
                                            .AddParameter("csentry", csentry))
                    .FirstOrDefault();
        }

        public void MapAttributesForExport(string FlowRuleName, MVEntry mventry, CSEntry csentry)
        {
            string scriptPath = FIMUtils.GetMaScriptPath(csentry.MA.Name, "MapAttributesForExport.ps1");

            if (!File.Exists(scriptPath))
            {
                throw new EntryPointNotImplementedException();
            }

            this.Invoke(this.CreateRuntime(scriptPath)
                                .AddParameter("FlowRuleName", FlowRuleName)
                                .AddParameter("mventry", mventry)
                                .AddParameter("csentry", csentry));
        }

        public void MapAttributesForImport(string FlowRuleName, CSEntry csentry, MVEntry mventry)
        {
            string scriptPath = FIMUtils.GetMaScriptPath(csentry.MA.Name, "MapAttributesForImport.ps1");

            if (!File.Exists(scriptPath))
            {
                throw new EntryPointNotImplementedException();
            }

            this.Invoke(this.CreateRuntime(scriptPath)
                                .AddParameter("FlowRuleName", FlowRuleName)
                                .AddParameter("mventry", mventry)
                                .AddParameter("csentry", csentry));
        }

        public void MapAttributesForJoin(string FlowRuleName, CSEntry csentry, ref ValueCollection values)
        {
            string scriptPath = FIMUtils.GetMaScriptPath(csentry.MA.Name, "MapAttributesForJoin.ps1");

            if (!File.Exists(scriptPath))
            {
                throw new EntryPointNotImplementedException();
            }

            this.Invoke(this.CreateRuntime(scriptPath)
                                .AddParameter("FlowRuleName", FlowRuleName)
                                .AddParameter("csentry", csentry)
                                .AddParameter("values", values));
        }

        public bool ResolveJoinSearch(string joinCriteriaName, CSEntry csentry, MVEntry[] rgmventry, out int imventry, ref string MVObjectType)
        {
            string scriptPath = FIMUtils.GetMaScriptPath(csentry.MA.Name, "ResolveJoinSearch.ps1");

            if (!File.Exists(scriptPath))
            {
                throw new EntryPointNotImplementedException();
            }

            var obj = this.Invoke(this.CreateRuntime(scriptPath)
                                        .AddParameter("joinCriteriaName", joinCriteriaName)
                                        .AddParameter("csentry", csentry)
                                        .AddParameter("rgmventry", rgmventry)
                                        .AddParameter("MVObjectType", MVObjectType))
                        .FirstOrDefault();

            if (obj == null)
            {
                imventry = -1;
                return false;
            }
            else
            {
                imventry = obj.GetProperty<int>("imventry", -1);
                MVObjectType = obj.GetProperty<string>("MVObjectType", MVObjectType);

                return obj.GetProperty<bool>("Result", false);
            }
        }

        public bool ShouldProjectToMV(CSEntry csentry, out string MVObjectType)
        {
            string scriptPath = FIMUtils.GetMaScriptPath(csentry.MA.Name, "ShouldProjectToMV.ps1");

            if (!File.Exists(scriptPath))
            {
                throw new EntryPointNotImplementedException();
            }

            var obj = this.Invoke(this.CreateRuntime(scriptPath)
                                        .AddParameter("csentry", csentry))
                        .FirstOrDefault();

            if (obj == null)
            {
                throw new EntryPointNotImplementedException();
            }

            MVObjectType = obj.GetProperty<string>("MVObjectType", null);
            return obj.GetProperty<bool>("Result", false);
        }
    }
}
