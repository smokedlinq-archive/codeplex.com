using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web.UI;
using System.Management.Automation.Runspaces;
using System.IO;
using System.ComponentModel;
using System.Management.Automation;

namespace System.Web.UI.PowerShell
{
    [ParseChildren(false, "CommandText")]
    [PersistChildren(false)]
    [ToolboxItem(false)]
    public class Script : Control, IAttributeAccessor
    {
        public Script()
            : base()
        {
            this.Parameters = new Dictionary<string, object>();
        }

        public Script(string text)
            : this()
        {
            this.CommandText = text;
        }

        [PersistenceMode(PersistenceMode.Attribute)]
        public string Source
        {
            get;
            set;
        }

        [PersistenceMode(PersistenceMode.InnerDefaultProperty)]
        public string CommandText
        {
            get;
            set;
        }

        public IDictionary<string, object> Parameters
        {
            get;
            private set;
        }

        string IAttributeAccessor.GetAttribute(string name)
        {
            return this.Parameters[name].ToString();
        }

        void IAttributeAccessor.SetAttribute(string name, string value)
        {
            this.Parameters[name] = value;
        }

        protected override ControlCollection CreateControlCollection()
        {
            return new EmptyControlCollection(this);
        }

        protected override void AddParsedSubObject(object obj)
        {
            if (obj is LiteralControl)
            {
                this.CommandText = ((LiteralControl)obj).Text;
            }
            else
            {
                base.AddParsedSubObject(obj);
            }
        }

        public IEnumerable<PSObject> Invoke(System.Management.Automation.Runspaces.Runspace runspace, params object[] args)
        {
            object currentArgs = runspace.SessionStateProxy.GetVariable("args");
            runspace.SessionStateProxy.SetVariable("args", args);

            try
            {
                using (var pipeline = runspace.CreatePipeline())
                {
                    if (!string.IsNullOrEmpty(this.Source))
                    {
                        pipeline.Commands.AddScript(
                            File.ReadAllText(
                                MapPathSecure(
                                    this.Source.StartsWith("~") ? ResolveUrl(this.Source) : this.Source
                                )
                            )
                        );
                    }
                    else if (!string.IsNullOrEmpty(this.CommandText))
                    {
                        pipeline.Commands.AddScript(this.CommandText);
                    }

                    if (pipeline.Commands.Count > 0)
                    {
                        foreach (var parameter in this.Parameters)
                        {
                            pipeline.Commands[0].Parameters.Add(parameter.Key, parameter.Value);
                        }

                        return pipeline.Invoke();
                    }
                }
            }
            finally
            {
                runspace.SessionStateProxy.SetVariable("args", currentArgs);
            }

            return new PSObject[0];
        }

        protected override void Render(HtmlTextWriter writer)
        {
        }
    }
}
