using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace FIM.PowerShell.Workflow.Activities
{
    [Serializable]
    public enum PowerShellRunAs
    {
        None = 0,
        Requestor = 1
    }
}
