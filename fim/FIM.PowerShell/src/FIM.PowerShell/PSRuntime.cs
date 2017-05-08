using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Management.Automation.Runspaces;
using System.Management.Automation;
using System.Collections.ObjectModel;
using System.IO;
using System.Diagnostics;
using Microsoft.MetadirectoryServices;
using System.Configuration;
using System.Threading;

namespace FIM.PowerShell
{
    public abstract class PSRuntime : IDisposable
    {
        Runspace _runspace;
        PSCommand _commands;

        protected PSRuntime()
        {
            TraceSource = new PSTraceSource(this.GetType().FullName);
        }

        ~PSRuntime()
        {
            Dispose(false);
        }

        protected PSTraceSource TraceSource
        {
            get;
            private set;
        }

        protected void Initialize()
        {
            using (TraceSource.TraceMethod())
            {
                // Create a runspace that runs within the space thread
                //   FIM can get 'upset' over other threads running off to do things
                this._runspace = RunspaceFactory.CreateRunspace();
                this._runspace.ThreadOptions = PSThreadOptions.UseCurrentThread;

                this._runspace.Open();

                // Load the extension profile script FIM.PowerShell.ps1
                //   This will allow a central script to load helper functions used by all scripts
                foreach (var path in Profile)
                {
                    if (File.Exists(path))
                    {
                        AddScript(path);
                        Invoke();
                    }
                }
            }
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
            if (disposing)
            {
                using (TraceSource.TraceMethod())
                {
                    if (this._runspace != null)
                        this._runspace.Dispose();
                }
            }
        }

        protected PSCommand AddScript(string path, bool useLocalScope = false)
        {
            using (TraceSource.TraceMethod())
            {
                TraceSource.TraceParameter("path", path);
                TraceSource.TraceParameter("useLocalScope", useLocalScope);

                if (!File.Exists(path))
                    throw new FileNotFoundException("The PowerShell script could not be found.", path);

                var script = ReadAllText(path);
                
                TraceSource.TraceVerbose(script);

                if (this._commands == null)
                    this._commands = new PSCommand();

                this._commands.AddScript(script, useLocalScope);

                return this._commands;
            }
        }

        protected string FindMaScript(string maName, string name)
        {
            using (TraceSource.TraceMethod())
            {
                TraceSource.TraceParameter("maName", maName);
                TraceSource.TraceParameter("name", name);

                if (string.IsNullOrWhiteSpace(MAData))
                    return null;

                var path = FindScript(Path.Combine(MAData, maName), name);
                TraceSource.TraceObject(path);
                return path;
            }
        }

        string FindScript(string path, string fileName)
        {
            using (TraceSource.TraceMethod())
            {
                TraceSource.TraceParameter("path", path);
                TraceSource.TraceParameter("fileName", fileName);

                var scriptPath = Directory.GetFiles(path, fileName, SearchOption.AllDirectories).FirstOrDefault();
                TraceSource.TraceVerbose(scriptPath);
                return scriptPath;
            }
        }

        protected string MAFolder
        {
            get
            {
                try
                {
                    return MAUtils.MAFolder;
                }
                catch
                {
                    return null;
                }
            }
        }

        protected string ExtensionsDirectory
        {
            get
            {
                try
                {
                    return Utils.ExtensionsDirectory;
                }
                catch
                {
                    return null;
                }
            }
        }

        protected string MAData
        {
            get
            {
                try
                {
                    return Path.GetFullPath(Path.Combine(Utils.ExtensionsDirectory, @"..\MaData"));
                }
                catch
                {
                    return null;
                }
            }
        }

        IEnumerable<string> Profile
        {
            get
            {
                yield return Path.GetFullPath(Path.Combine(Environment.ExpandEnvironmentVariables(@"%SYSTEMROOT%\system32\WindowsPowerShell\v1.0"), "FIM.PowerShell.ps1"));
                
                if (!string.IsNullOrWhiteSpace(ExtensionsDirectory))
                    yield return Path.GetFullPath(Path.Combine(ExtensionsDirectory, "FIM.PowerShell.ps1"));

                if (!string.IsNullOrWhiteSpace(MAFolder))
                    yield return Path.GetFullPath(Path.Combine(MAFolder, "FIM.PowerShell.ps1"));
            }
        }

        static string ReadAllText(string path)
        {
            using (var stream = File.Open(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
            using (var reader = new StreamReader(stream))
                return reader.ReadToEnd();
        }

        protected Collection<PSObject> Invoke()
        {
            using (TraceSource.TraceMethod())
            {
                return Invoke(runtime => runtime.Invoke());
            }
        }
        
        protected Collection<T> Invoke<T>()
        {
            using (TraceSource.TraceMethod())
            {
                return Invoke<T>(runtime => runtime.Invoke<T>());
            }
        }

        protected Collection<T> Invoke<T>(params object[] input)
        {
            using (TraceSource.TraceMethod())
            {
                TraceSource.TraceParameter("input", input);

                return Invoke<T>(runtime => runtime.Invoke<T>(input));
            }
        }

        Collection<T> Invoke<T>(Func<System.Management.Automation.PowerShell, Collection<T>> invoker)
        {
            try
            {
                return Invoke(this._commands, invoker);
            }
            finally
            {
                this._commands = null;
            }
        }

        Collection<T> Invoke<T>(PSCommand commands, Func<System.Management.Automation.PowerShell, Collection<T>> invoker)
        {
            using (TraceSource.TraceMethod())
            {
                TraceSource.TraceParameter("commands", commands);
                TraceSource.TraceParameter("invoker", invoker);

                using (var runtime = System.Management.Automation.PowerShell.Create())
                {
                    runtime.Runspace = this._runspace;
                    runtime.Commands = commands;
                    return invoker(runtime);
                }
            }
        }

        protected EntryPointNotImplementedException EntryPointNotImplementedException(string maName, string scriptName)
        {
            return new EntryPointNotImplementedException(string.Format(Thread.CurrentThread.CurrentCulture, "Could not load the Management Agent '{0}' PowerShell Script '{1}'.", maName, scriptName));
        }
    }
}
