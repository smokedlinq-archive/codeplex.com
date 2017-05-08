using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web.PowerShell;

namespace System.Web.UI.PowerShell
{
    public abstract class RunspaceControl : Control
    {
        System.Management.Automation.Runspaces.Runspace runspace;

        public RunspaceControl()
            : base()
        {
        }

        public override void Dispose()
        {
            if (this.runspace != null)
            {
                this.runspace.Close();
                this.runspace.Dispose();
                this.runspace = null;
            }

            base.Dispose();
        }

        public System.Management.Automation.Runspaces.Runspace Runspace
        {
            get
            {
                if (this.runspace == null)
                {
                    this.runspace = WebRunspaceFactory.CreateRunspace(this.Context, this.Page, this, this.ViewState);
                }

                return this.runspace;
            }
        }
    }
}
