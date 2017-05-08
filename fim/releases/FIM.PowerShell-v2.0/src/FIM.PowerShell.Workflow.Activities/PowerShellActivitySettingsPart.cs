using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.IdentityManagement.WebUI.Controls;
using System.Workflow.ComponentModel;
using Microsoft.ResourceManagement.Workflow.Activities;
using System.Web.UI.WebControls;
using System.Web.UI;
using System.Configuration;
using System.Security.Cryptography;
using System.IO;

namespace FIM.PowerShell.Workflow.Activities
{
    class PowerShellActivitySettingsPart : ActivitySettingsPart
    {
        TextBox txtScript;
        TextBox txtRunAsUserName;
        TextBox txtRunAsUserPassword;
        RadioButtonList rblRunAs;

        public PowerShellActivitySettingsPart()
        {
            this.txtScript = new TextBox()
                {
                    ID = "Script",
                    CssClass = base.TextBoxCssClass,
                    Width = Unit.Percentage(100),
                    Rows = 24,
                    TextMode = TextBoxMode.MultiLine,
                    Text = "param($WorkflowDefinitionId, $RequestId, $ActorId, $TargetId, $WorkflowData)\n",
                    Wrap = false
                };

            this.txtRunAsUserName = new TextBox()
                {
                    ID = "RunAsUserName",
                    CssClass = base.TextBoxCssClass,
                    Columns = 40,
                    MaxLength = 260,
                    Text = @"DOMAIN\User"
                };

            this.txtRunAsUserPassword = new TextBox()
                {
                    ID = "RunAsUserPassword",
                    CssClass = base.TextBoxCssClass,
                    Columns = 40,
                    MaxLength = 260,
                    TextMode = TextBoxMode.Password
                };

            this.rblRunAs = new RadioButtonList()
                {
                    ID = "RunAs"
                };

            this.rblRunAs.Items.Add(GetRunAsListItem<PowerShellRunAsFIM>("Default (FIMService)"));
            this.rblRunAs.Items.Add(GetRunAsListItem<PowerShellRunAsRequestor>("Requestor"));
            this.rblRunAs.Items.Add(GetRunAsListItem<PowerShellRunAsUser>("User"));
            this.rblRunAs.SelectedIndex = 0;
        }

        public override Activity GenerateActivityOnWorkflow(SequentialWorkflow workflow)
        {
            return new PowerShellActivity()
                {
                    Script = this.txtScript.Text,
                    RunAs = GetRunAs()
                };
        }

        public override void LoadActivitySettings(Activity activity)
        {
            var psActivity = activity as PowerShellActivity;

            if (psActivity != null)
            {
                this.txtScript.Text = psActivity.Script;
                this.rblRunAs.SelectedIndex = this.rblRunAs.Items.IndexOf(this.rblRunAs.Items.FindByValue(psActivity.RunAs.GetType().Name));

                if (psActivity.RunAs is PowerShellRunAsUser)
                {
                    var runas = (PowerShellRunAsUser)psActivity.RunAs;

                    this.txtRunAsUserName.Text = runas.UserName;
                    this.txtRunAsUserPassword.Attributes["value"] = PowerShellCryptography.Unprotect(runas.Password);
                }
            }
        }

        public override ActivitySettingsPartData PersistSettings()
        {
            var data = new ActivitySettingsPartData();
            var runAs = GetRunAs();

            data["Script"] = this.txtScript.Text;
            data["RunAs"] = runAs;

            return data;
        }

        public override void RestoreSettings(ActivitySettingsPartData data)
        {
            if (data != null)
            {
                this.txtScript.Text = SafeGetData<string>(data, "Script");

                var runAs = SafeGetData<PowerShellRunAs>(data, "RunAs") ?? new PowerShellRunAsFIM();

                this.rblRunAs.SelectedIndex = this.rblRunAs.Items.IndexOf(this.rblRunAs.Items.FindByValue(runAs.GetType().Name));

                if (runAs is PowerShellRunAsUser)
                {
                    var runAsUser = (PowerShellRunAsUser)runAs;

                    this.txtRunAsUserName.Text = runAsUser.UserName;
                    this.txtRunAsUserPassword.Attributes["value"] = PowerShellCryptography.Unprotect(runAsUser.Password);
                }
            }
        }

        ListItem GetRunAsListItem<T>(string text)
            where T : PowerShellRunAs
        {
            return new ListItem(text, typeof(T).Name);
        }

        PowerShellRunAs GetRunAs()
        {
            if (string.Equals(this.rblRunAs.SelectedValue, typeof(PowerShellRunAsRequestor).Name, StringComparison.OrdinalIgnoreCase))
            {
                return new PowerShellRunAsRequestor();
            }
            else if (string.Equals(this.rblRunAs.SelectedValue, typeof(PowerShellRunAsUser).Name, StringComparison.OrdinalIgnoreCase))
            {
                return new PowerShellRunAsUser()
                        {
                            UserName = this.txtRunAsUserName.Text,
                            Password = PowerShellCryptography.Protect(string.IsNullOrEmpty(this.txtRunAsUserPassword.Text) ? this.txtRunAsUserPassword.Attributes["value"] : this.txtRunAsUserPassword.Text)
                        };
            }
            else
            {
                return new PowerShellRunAsFIM();
            }
        }

        T SafeGetData<T>(ActivitySettingsPartData data, string name)
        {
            return SafeGetData<T>(data, name, default(T));
        }

        T SafeGetData<T>(ActivitySettingsPartData data, string name, T defaultValue)
        {
            var value = data[name];

            if (value == null)
            {
                return defaultValue;
            }

            try
            {
                return (T)value;
            }
            catch
            {
                return defaultValue;
            }
        }

        public override void SwitchMode(ActivitySettingsPartMode mode)
        {
            this.txtScript.ReadOnly = (mode == ActivitySettingsPartMode.View);
            this.rblRunAs.Enabled = (mode == ActivitySettingsPartMode.Edit);
            this.txtRunAsUserName.ReadOnly = (mode == ActivitySettingsPartMode.View);
            this.txtRunAsUserPassword.ReadOnly = (mode == ActivitySettingsPartMode.View);
        }

        public override string Title
        {
            get { return "PowerShell Activity"; }
        }

        public override bool ValidateInputs()
        {
            return true;
        }

        protected override void CreateChildControls()
        {
            this.Controls.Add(new LiteralControl(@"<fieldset style=""text-align: left; padding: 0.25em;""><legend>&nbsp;Run As&nbsp;</legend>"));
            this.Controls.Add(this.rblRunAs);
                this.Controls.Add(new LiteralControl(@"<fieldset style=""text-align: left; padding: 0.25em;""><legend>&nbsp;User Credentials&nbsp;</legend>"));
                this.Controls.Add(new LiteralControl(@"<label for=""" + this.txtRunAsUserName.ClientID + @""" style=""padding-left: 0.5em; width: 8em;"">User Name:</label>"));
                this.Controls.Add(this.txtRunAsUserName);
                this.Controls.Add(new LiteralControl(@"<br /><label for=""" + this.txtRunAsUserPassword.ClientID + @""" style=""padding-left: 0.5em; width: 8em;"">Password:</label>"));
                this.Controls.Add(this.txtRunAsUserPassword);
                this.Controls.Add(new LiteralControl(@"</fieldset>"));
            this.Controls.Add(new LiteralControl(@"</fieldset>"));
            this.Controls.Add(new LiteralControl(@"<div style=""margin: 0.25em auto 0.25em auto;"">"));
            this.Controls.Add(this.txtScript);
            this.Controls.Add(new LiteralControl(@"</div>"));
            this.Controls.Add(new LiteralControl(@"<div style=""text-align: left; font-size: 0.75em; padding: 0.25em; margin: 0.25em;"">
                                                    <p>Standard script parameters:</p>
                                                    <ul>
                                                     <li><a href=""http://msdn.microsoft.com/en-us/library/microsoft.resourcemanagement.workflow.activities.sequentialworkflow.workflowdefinitionid.aspx"" target=""_blank"">[Guid] $WorkflowDefinitionId</a></li>
                                                     <li><a href=""http://msdn.microsoft.com/en-us/library/microsoft.resourcemanagement.workflow.activities.sequentialworkflow.requestid.aspx"" target=""_blank"">[Guid] $RequestId</a></li>
                                                     <li><a href=""http://msdn.microsoft.com/en-us/library/microsoft.resourcemanagement.workflow.activities.sequentialworkflow.actorid.aspx"" target=""_blank"">[Guid] $ActorId</a></li>
                                                     <li><a href=""http://msdn.microsoft.com/en-us/library/microsoft.resourcemanagement.workflow.activities.sequentialworkflow.targetid.aspx"" target=""_blank"">[Guid] $TargetId</a></li>
                                                     <li><a href=""http://msdn.microsoft.com/en-us/library/microsoft.resourcemanagement.workflow.activities.sequentialworkflow.workflowdictionary.aspx"" target=""_blank"">[Dictionary<string, object>] $WorkflowData</a></li>
                                                    </ul>
                                                    <p>Note: WorkflowData items will be added as a parameter when calling the script.</p>
                                                   </div>"));

            base.CreateChildControls();
        }
    }
}
