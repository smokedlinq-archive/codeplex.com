using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using System.Management.Automation.Runspaces;
using System.Web;
using System.IO;
using System.Management.Automation;
using System.Collections;

namespace System.Web.UI.PowerShell
{
    public class DataSourceView : System.Web.UI.DataSourceView
    {
        DataSource owner;

        public DataSourceView(DataSource owner, string viewName)
            : base(owner, viewName)
        {
            this.owner = owner;
        }

        protected override IEnumerable ExecuteSelect(DataSourceSelectArguments arguments)
        {
            var currentArguments = this.owner.Runspace.SessionStateProxy.GetVariable("arguments");
            this.owner.Runspace.SessionStateProxy.SetVariable("arguments", arguments);
            
            try
            {
                return this.owner.Script.Invoke(this.owner.Runspace);
            }
            finally
            {
                this.owner.Runspace.SessionStateProxy.SetVariable("arguments", currentArguments);
            }
        }
    }
}
