using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Workflow.ComponentModel;
using System.Management.Automation.Runspaces;
using Microsoft.ResourceManagement.Workflow.Activities;
using Microsoft.ResourceManagement.WebServices.WSResourceManagement;
using System.Workflow.Runtime;
using System.Threading;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.IO;
using System.Security.Principal;
using System.Runtime.InteropServices;
using System.Collections;
using System.Diagnostics;
using System.Web.Script.Serialization;

namespace FIM.PowerShell.Workflow.Activities
{
    public class PowerShellActivity : Activity
    {
        static readonly DependencyProperty ScriptProperty = DependencyProperty.Register("Script", typeof(string), typeof(PowerShellActivity));
        static readonly DependencyProperty RunAsProperty = DependencyProperty.Register("RunAs", typeof(PowerShellRunAs), typeof(PowerShellActivity));

        public PowerShellActivity()
        {
            this.Name = "PowerShellActivity";
        }

        public string Script
        {
            get { return (string)GetValue(ScriptProperty); }
            set { SetValue(ScriptProperty, value); }
        }

        public PowerShellRunAs RunAs
        {
            get { return (PowerShellRunAs)GetValue(RunAsProperty); }
            set { SetValue(RunAsProperty, value); }
        }

        protected override ActivityExecutionStatus Execute(ActivityExecutionContext executionContext)
        {
            SequentialWorkflow containingWorkflow;

            if (!SequentialWorkflow.TryGetContainingWorkflow(this, out containingWorkflow))
            {
                throw new FIMPowerShellActivityException("Could not retrieve the containing workflow.");
            }

            var isolatedSetup = new AppDomainSetup
                {
                    ApplicationBase = AppDomain.CurrentDomain.SetupInformation.ApplicationBase,
                    ApplicationName = "PowerShellActivity " + containingWorkflow.RequestId.ToString(),
                    ConfigurationFile = Path.Combine(Directory.GetParent(AppDomain.CurrentDomain.SetupInformation.ConfigurationFile).FullName, "FIM.PowerShell.config"),
                    PrivateBinPath = AppDomain.CurrentDomain.SetupInformation.PrivateBinPath,
                    PrivateBinPathProbe = AppDomain.CurrentDomain.SetupInformation.PrivateBinPathProbe
                };

            var isolatedDomain = AppDomain.CreateDomain("PowerShellActivity " + containingWorkflow.RequestId.ToString(), null, isolatedSetup);
            var unhandledException = new UnhandledExceptionHandler();

            isolatedDomain.UnhandledException += new UnhandledExceptionEventHandler(unhandledException.OnUnhandledException);

            try
            {
                var activity = (IsolatedAppDomainActivity)isolatedDomain.CreateInstance(typeof(IsolatedAppDomainActivity).Assembly.FullName, typeof(IsolatedAppDomainActivity).FullName).Unwrap();
                var workflowData = containingWorkflow.WorkflowDictionary;

                this.RunAs.Invoke(() => activity.Execute(containingWorkflow.WorkflowDefinitionId, containingWorkflow.RequestId, containingWorkflow.ActorId, containingWorkflow.TargetId, ref workflowData, this.Script));

                containingWorkflow.WorkflowDictionary = workflowData;
            }
            catch (Exception ex)
            {
                if (unhandledException.IsSet())
                {
                    throw new FIMPowerShellActivityException("FIM PowerShell Workflow Activity failed, check the Application event log or inner exception for more inforamtion.", ex);
                }

                throw new FIMPowerShellActivityException(ex.Message, ex);
            }
            finally
            {
                try
                {
                    AppDomain.Unload(isolatedDomain);
                }
                catch
                {
                    // NOOP
                }
            }

            return base.Execute(executionContext);
        }

        class UnhandledExceptionHandler : MarshalByRefObject
        {
            private bool _set = false;

            public bool IsSet()
            {
                return _set;
            }

            public void Reset()
            {
                _set = false;
            }

            public void OnUnhandledException(object sender, UnhandledExceptionEventArgs e)
            {
                var ex = e.ExceptionObject as Exception;

                if (ex != null)
                {
                    if (EventLog.SourceExists("FIM.PowerShell"))
                    {
                        EventLog.WriteEntry("FIM.PowerShell", string.Format("{0}\n   IsTerminating: {1}\n\n{2}", ex.Message, e.IsTerminating, ex.ToString()), EventLogEntryType.Error, 102);
                    }
                }

                _set = true;
            }
        }

        class IsolatedAppDomainActivity : MarshalByRefObject
        {
            public void Execute(Guid workflowDefinitionId, Guid requestId, Guid actorId, Guid targetId, ref Dictionary<string, object> workflowData, string script)
            {
                try
                {
                    using (var runspace = RunspaceFactory.CreateRunspace())
                    {
                        runspace.ThreadOptions = PSThreadOptions.UseCurrentThread;
                        runspace.Open();

                        runspace.SessionStateProxy.SetVariable("ErrorActionPreference", ActionPreference.Stop);

                        using (var powershell = System.Management.Automation.PowerShell.Create())
                        {
                            powershell.Runspace = runspace;
                            powershell.AddScript(script);
                            powershell.AddParameter("WorkflowDefinitionId", workflowDefinitionId);
                            powershell.AddParameter("RequestId", requestId);
                            powershell.AddParameter("ActorId", actorId);
                            powershell.AddParameter("TargetId", targetId);
                            powershell.AddParameter("WorkflowData", workflowData);

                            foreach (var item in workflowData)
                                powershell.AddParameter(item.Key, item.Value);

                            try
                            {
                                powershell.Invoke();
                            }
                            catch (Exception ex)
                            {
                                if (EventLog.SourceExists("FIM.PowerShell"))
                                {
                                    var message = new StringBuilder();

                                    message.AppendFormat("{0}\n\n", ex.Message);
                                    message.AppendFormat("WorkflowDefinitionId: {0}\n", workflowDefinitionId);
                                    message.AppendFormat("RequestId: {0}\n", requestId);
                                    message.AppendFormat("ActorId: {0}\n", actorId);
                                    message.AppendFormat("TargetId: {0}\n\n", targetId);

                                    if (workflowData.Count > 0)
                                    {
                                        message.AppendFormat("WorkflowData: {0}\n\n", new JavaScriptSerializer().Serialize(workflowData));
                                    }

                                    message.AppendFormat("Script:\n{0}\n\n", script);

                                    if (ex is RuntimeException)
                                    {
                                        var rex = (RuntimeException)ex;
                                        message.AppendFormat("Error: {0}\n", rex.ErrorRecord.ToString());
                                        message.AppendFormat("  at line {0:#,##0}, column {1:#,##0}: {2}\n\n", rex.ErrorRecord.InvocationInfo.ScriptLineNumber, rex.ErrorRecord.InvocationInfo.OffsetInLine, rex.ErrorRecord.InvocationInfo.Line.Trim());
                                    }

                                    try
                                    {
                                        var error = powershell.Streams.Error.ReadAll();

                                        if (error.Count > 0)
                                        {
                                            message.AppendFormat("Error Records:\n{0}\n\n", new JavaScriptSerializer().Serialize(error));
                                        }
                                    }
                                    catch
                                    {
                                        // NOOP
                                    }

                                    message.AppendFormat("Exception Type: {0}\n\n", ex.GetType().FullName);
                                    message.AppendFormat("Stack Trace:\n{0}\n", ex.StackTrace.ToString());

                                    EventLog.WriteEntry("FIM.PowerShell", message.ToString(), EventLogEntryType.Error, 100);
                                }

                                if (ex is RuntimeException)
                                {
                                    throw new FIMPowerShellActivityException((RuntimeException)ex);
                                }
                                else
                                {
                                    throw new FIMPowerShellActivityException(ex.Message, ex);
                                }
                            }
                        }
                    }
                }
                catch (FIMPowerShellActivityException)
                {
                    throw;
                }
                catch (Exception ex)
                {
                    if (EventLog.SourceExists("FIM.PowerShell"))
                    {
                        var message = new StringBuilder();

                        message.AppendFormat("{0}\n\n", ex.Message);
                        message.AppendFormat("WorkflowDefinitionId: {0}\n", workflowDefinitionId);
                        message.AppendFormat("RequestId: {0}\n", requestId);
                        message.AppendFormat("ActorId: {0}\n", actorId);
                        message.AppendFormat("TargetId: {0}\n\n", targetId);

                        if (workflowData.Count > 0)
                        {
                            message.AppendFormat("WorkflowData: {0}\n\n", new JavaScriptSerializer().Serialize(workflowData));
                        }

                        message.AppendFormat("Script:\n{0}\n\n", script);

                        if (ex is RuntimeException)
                        {
                            var rex = (RuntimeException)ex;
                            message.AppendFormat("Error: {0}\n", rex.ErrorRecord.ToString());
                            message.AppendFormat("  at line {0:#,##0}, column {1:#,##0}: {2}\n\n", rex.ErrorRecord.InvocationInfo.ScriptLineNumber, rex.ErrorRecord.InvocationInfo.OffsetInLine, rex.ErrorRecord.InvocationInfo.Line.Trim());
                        }

                        message.AppendFormat("Exception Type: {0}\n\n", ex.GetType().FullName);
                        message.AppendFormat("Stack Trace:\n{0}\n", ex.StackTrace.ToString());

                        EventLog.WriteEntry("FIM.PowerShell", message.ToString(), EventLogEntryType.Error, 101);
                    }

                    if (ex is RuntimeException)
                    {
                        throw new FIMPowerShellActivityException((RuntimeException)ex);
                    }
                    else
                    {
                        throw new FIMPowerShellActivityException(ex.Message, ex);
                    }
                }
            }
        }
    }
}
