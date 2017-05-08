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
            get { return (string)GetValue(ScriptProperty);  }
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
                
            isolatedDomain.UnhandledException += new UnhandledExceptionEventHandler((sender, e) =>
            {
                throw (Exception)e.ExceptionObject;
            });

            try
            {
                var activity = (IsolatedAppDomainActivity)isolatedDomain.CreateInstance(typeof(IsolatedAppDomainActivity).Assembly.FullName, typeof(IsolatedAppDomainActivity).FullName).Unwrap();
                var workflowData = containingWorkflow.WorkflowDictionary;

                switch (this.RunAs)
                {
                    case PowerShellRunAs.Requestor:
                        using (((WindowsIdentity)Thread.CurrentPrincipal.Identity).Impersonate())
                        {
                            activity.Execute(containingWorkflow.WorkflowDefinitionId, containingWorkflow.RequestId, containingWorkflow.ActorId, containingWorkflow.TargetId, ref workflowData, this.Script);
                        }
                        break;

                    case PowerShellRunAs.None:
                    default:
                        activity.Execute(containingWorkflow.WorkflowDefinitionId, containingWorkflow.RequestId, containingWorkflow.ActorId, containingWorkflow.TargetId, ref workflowData, this.Script);
                        break;
                }
            }
            finally
            {
                AppDomain.Unload(isolatedDomain);
            }
            
            return base.Execute(executionContext);
        }

        class IsolatedAppDomainActivity : MarshalByRefObject
        {
            public void Execute(Guid workflowDefinitionId, Guid requestId, Guid actorId, Guid targetId, ref Dictionary<string, object> workflowData, string script)
            {
                using (var runspace = RunspaceFactory.CreateRunspace(new FIMPowerShellHost()))
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
                        {
                            powershell.AddParameter(item.Key, item.Value);
                        }

                        try
                        {
                            powershell.Invoke();
                        }
                        catch (RuntimeException ex)
                        {
                            throw new FIMPowerShellActivityException(ex);
                        }
                    }
                }
            }
        }
    }
}
