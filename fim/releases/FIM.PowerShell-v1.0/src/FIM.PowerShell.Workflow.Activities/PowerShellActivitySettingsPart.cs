using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.IdentityManagement.WebUI.Controls;
using System.Workflow.ComponentModel;
using Microsoft.ResourceManagement.Workflow.Activities;
using System.Web.UI.WebControls;
using System.Web.UI;

namespace FIM.PowerShell.Workflow.Activities
{
    class PowerShellActivitySettingsPart : ActivitySettingsPart
    {
        TextBox txtScript;
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

            this.rblRunAs = new RadioButtonList()
                {
                    ID = "RunAs"
                };

            this.rblRunAs.Items.Add(new ListItem("Default (FIMService)", PowerShellRunAs.None.ToString()));
            this.rblRunAs.Items.Add(new ListItem("Requestor", PowerShellRunAs.Requestor.ToString()));
            this.rblRunAs.SelectedIndex = 0;
        }

        public override Activity GenerateActivityOnWorkflow(SequentialWorkflow workflow)
        {
            return new PowerShellActivity()
                {
                    Script = this.txtScript.Text,
                    RunAs = ParseEnum<PowerShellRunAs>(this.rblRunAs.SelectedValue)
                };
        }

        public override void LoadActivitySettings(Activity activity)
        {
            var psActivity = activity as PowerShellActivity;

            if (psActivity != null)
            {
                this.txtScript.Text = psActivity.Script;
                this.rblRunAs.SelectedIndex = this.rblRunAs.Items.IndexOf(this.rblRunAs.Items.FindByValue(psActivity.RunAs.ToString()));
            }
        }

        public override ActivitySettingsPartData PersistSettings()
        {
            var data = new ActivitySettingsPartData();

            data["Script"] = this.txtScript.Text;
            data["RunAs"] = ParseEnum<PowerShellRunAs>(this.rblRunAs.SelectedValue);

            return data;
        }

        T ParseEnum<T>(string value)
            where T : struct
        {
            return (T)Enum.Parse(typeof(T), value);
        }

        public override void RestoreSettings(ActivitySettingsPartData data)
        {
            if (data != null)
            {
                this.txtScript.Text = SafeGetData<string>(data, "Script");
                this.rblRunAs.SelectedIndex = this.rblRunAs.Items.IndexOf(this.rblRunAs.Items.FindByValue(SafeGetData<PowerShellRunAs>(data, "RunAs", PowerShellRunAs.None).ToString())); 
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
