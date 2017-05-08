using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web.UI;
using System.Management.Automation.Runspaces;
using System.Management.Automation;
using System.IO;
using System.Web;
using System.Collections;
using System.Web.PowerShell;

namespace System.Web.UI.PowerShell
{
    [ParseChildren(false)]
    [PersistChildren(false)]
    [ControlBuilder(typeof(RunspaceControlBuilder))]
    [ToolboxData(@"<{0}:Runspace runat=""server""><OnLoad></OnLoad></{0}:Runspace>")]
    public class Runspace : RunspaceControl
    {
        public Runspace()
            : base()
        {
        }

        protected override void OnInit(EventArgs e)
        {
            this.Invoke<OnInitEvent>();
        }

        protected override void OnLoad(EventArgs e)
        {
            this.Invoke<OnLoadEvent>();
        }

        protected override void OnUnload(EventArgs e)
        {
            this.Invoke<OnUnloadEvent>();
        }

        protected override void Render(HtmlTextWriter writer)
        {
            var output = this.Invoke<OnRenderEvent>(writer);

            if (this.Visible)
            {
                using (var pipeline = this.Runspace.CreatePipeline())
                {
                    pipeline.Input.Write(output);
                    pipeline.Commands.Add("Out-String");
                    writer.Write((pipeline.Invoke().First() ?? (object)string.Empty).ToString());
                }
            }
        }

        IEnumerable<PSObject> Invoke<T>(params object[] args)
            where T : Script
        {
            var output = new List<PSObject>();
            var scriptlets = this.Controls.OfType<T>();
            
            foreach (Script scriptlet in scriptlets)
            {
                output.AddRange(scriptlet.Invoke(this.Runspace, args));
            }

            return output;
        }

        public class RunspaceControlBuilder : ControlBuilder
        {
            public override void AppendLiteralString(string s)
            {
            }

            public override Type GetChildControlType(string tagName, IDictionary attribs)
            {
                switch (tagName.ToUpper())
                {
                    case "ONINIT":
                        return typeof(OnInitEvent);

                    case "ONLOAD":
                        return typeof(OnLoadEvent);

                    case "ONRENDER":
                        return typeof(OnRenderEvent);

                    case "ONUNLOAD":
                        return typeof(OnUnloadEvent);
                }

                return null;
            }
        }

        public class OnInitEvent : Script
        {
        }

        public class OnLoadEvent : Script
        {
        }

        public class OnRenderEvent : Script
        {
        }

        public class OnUnloadEvent : Script
        {
        }
    }
}
