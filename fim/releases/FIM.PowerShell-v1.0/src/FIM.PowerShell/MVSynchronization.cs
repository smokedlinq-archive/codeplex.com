using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.MetadirectoryServices;
using System.IO;
using System.Management.Automation.Runspaces;
using System.Management.Automation;

namespace FIM.PowerShell
{
    public sealed class MVSynchronization : FIMPowerShell, IMVSynchronization
    {
        public void Provision(MVEntry mventry)
        {
            foreach (var maName in Utils.MAs)
            {
                var scriptPath = FIMUtils.GetMaScriptPath(maName, "Provision.ps1");

                if (File.Exists(scriptPath))
                {
                    this.Invoke(this.CreateRuntime(scriptPath)
                                    .AddParameter("mventry", mventry));
                }
            }
        }

        public bool ShouldDeleteFromMV(CSEntry csentry, MVEntry mventry)
        {
            string scriptPath = FIMUtils.GetMaScriptPath(csentry.MA.Name, "ShouldDeleteFromMV.ps1");

            if (!File.Exists(scriptPath))
            {
                throw new EntryPointNotImplementedException();
            }

            return this.Invoke<bool>(this.CreateRuntime(scriptPath)
                                    .AddParameter("csentry", csentry)
                                    .AddParameter("mventry", mventry))
                        .FirstOrDefault();
        }
    }
}
