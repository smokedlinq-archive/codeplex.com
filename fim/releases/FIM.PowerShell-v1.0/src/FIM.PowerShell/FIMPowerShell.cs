using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Management.Automation.Runspaces;
using System.Management.Automation;
using System.Collections.ObjectModel;
using System.IO;

namespace FIM.PowerShell
{
    public abstract class FIMPowerShell
    {
        Runspace _runspace;
        FIMPowerShellScriptCache _cache;

        protected System.Management.Automation.PowerShell CreateRuntime(string scriptPath)
        {
            var posh = System.Management.Automation.PowerShell.Create();

            posh.Runspace = this._runspace;

            posh.AddScript(this._cache[scriptPath]);

            return posh;
        }

        public virtual void Initialize()
        {
            this._cache = new FIMPowerShellScriptCache();

            // Create a runspace that runs within the space thread
            //   FIM can get 'upset' over other threads running off to do things
            this._runspace = RunspaceFactory.CreateRunspace(new FIMPowerShellHost());
            this._runspace.ThreadOptions = PSThreadOptions.UseCurrentThread;

            this._runspace.Open();
            
            // Load the extension profile script FIM.PowerShell.ps1
            //   This will allow a central script to load helper functions used by all scripts
            var profilePath = FIMUtils.GetExtensionProfilePath();

            if (File.Exists(profilePath))
            {
                Invoke(this.CreateRuntime(profilePath));
            }
        }

        public virtual void Terminate()
        {
            if (this._runspace != null)
            {
                this._runspace.Dispose();
            }

            if (this._cache != null)
            {
                this._cache.Dispose();
            }
        }

        protected Collection<PSObject> Invoke(System.Management.Automation.PowerShell powershell)
        {
            try
            {
                return powershell.Invoke();
            }
            catch (RuntimeException ex)
            {
                throw new FIMPowerShellRuntimeException(ex);
            }
        }

        protected Collection<T> Invoke<T>(System.Management.Automation.PowerShell powershell)
        {
            try
            {
                return powershell.Invoke<T>();
            }
            catch (RuntimeException ex)
            {
                throw new FIMPowerShellRuntimeException(ex);
            }
        }
    }
}
