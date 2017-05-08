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
    public sealed class MVSynchronization : PSRuntime, IMVSynchronization
    {
        public void Provision(MVEntry mventry)
        {
            using (TraceSource.TraceMethod())
            {
                TraceSource.TraceParameter("mventry", mventry);

                foreach (var maName in Utils.MAs)
                {
                    var scriptPath = FindMaScript(maName, "Provision.ps1");

                    if (File.Exists(scriptPath))
                    {
                        AddScript(scriptPath)
                            .AddParameter("mventry", mventry);

                        Invoke();
                    }
                }
            }
        }

        public bool ShouldDeleteFromMV(CSEntry csentry, MVEntry mventry)
        {
            using (TraceSource.TraceMethod())
            {
                TraceSource.TraceParameter("csentry", csentry);
                TraceSource.TraceParameter("mventry", mventry);

                var scriptPath = FindMaScript(csentry.MA.Name, "ShouldDeleteFromMV.ps1");

                if (!File.Exists(scriptPath))
                    throw EntryPointNotImplementedException(csentry.MA.Name, "ShouldDeleteFromMV.ps1");

                AddScript(scriptPath)
                    .AddParameter("csentry", csentry)
                    .AddParameter("mventry", mventry);

                var shouldDelete = Invoke<bool>().FirstOrDefault();

                TraceSource.TraceObject(shouldDelete);

                return shouldDelete;
            }
        }

        void IMVSynchronization.Initialize()
        {
            base.Initialize();
        }

        void IMVSynchronization.Terminate()
        {
            base.Dispose();
        }
    }
}
