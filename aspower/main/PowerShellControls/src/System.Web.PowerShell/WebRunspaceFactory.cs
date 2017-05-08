using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Management.Automation.Runspaces;
using System.Web.UI;

namespace System.Web.PowerShell
{
    internal static class WebRunspaceFactory
    {
        public static Runspace CreateRunspace(HttpContext context, Page page, Control control, StateBag viewState)
        {
            var runspace = RunspaceFactory.CreateRunspace();
            
            runspace.Open();

            runspace.SessionStateProxy.SetVariable("Context", context);

            if (context != null)
            {
                runspace.SessionStateProxy.SetVariable("Server", context.Server);
                runspace.SessionStateProxy.SetVariable("Trace", context.Trace);
                runspace.SessionStateProxy.SetVariable("Application", context.Application);
                runspace.SessionStateProxy.SetVariable("Cache", context.Cache);
                runspace.SessionStateProxy.SetVariable("User", context.User);
                runspace.SessionStateProxy.SetVariable("Session", context.Session);
                runspace.SessionStateProxy.SetVariable("Request", context.Request);
                runspace.SessionStateProxy.SetVariable("Response", context.Response);
            }

            runspace.SessionStateProxy.SetVariable("Page", page);

            if (control != null)
            {
                runspace.SessionStateProxy.SetVariable("this", control);
            }

            if (viewState != null)
            {
                runspace.SessionStateProxy.SetVariable("ViewState", viewState);
            }

            return runspace;
        }
    }
}
