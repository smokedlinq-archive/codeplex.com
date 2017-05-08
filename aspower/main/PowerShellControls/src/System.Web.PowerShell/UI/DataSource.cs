using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web.UI;
using System.IO;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.ComponentModel;
using System.Collections;

namespace System.Web.UI.PowerShell
{
    [ParseChildren(true, "Script")]
    [PersistChildren(false)]
    [ToolboxData(@"<{0}:DataSource runat=""server""><Script></Script></{0}:DataSource>")]
    public class DataSource : RunspaceControl, IDataSource
    {
        [PersistenceMode(PersistenceMode.InnerDefaultProperty)]
        public Script Script
        {
            get;
            set;
        }

        DataSourceView view;

        #region IDataSource Members

        event EventHandler IDataSource.DataSourceChanged
        {
            add
            {
                //NOOP
            }
            remove
            {
                //NOOP
            }
        }

        public System.Web.UI.DataSourceView GetView(string viewName)
        {
            if (view == null)
            {
                view = new DataSourceView(this, viewName);
            }

            return view;
        }

        public ICollection GetViewNames()
        {
            return null;
        }

        #endregion

        protected override void Render(HtmlTextWriter writer)
        {
        }
    }
}
