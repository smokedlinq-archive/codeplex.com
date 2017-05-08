using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.Serialization;
using System.Management.Automation;

namespace FIM.PowerShell.Workflow.Activities
{
    [Serializable]
    public class FIMPowerShellActivityException : Exception
    {
        public FIMPowerShellActivityException()
            : base()
        {
        }

        public FIMPowerShellActivityException(string message)
            : base(message)
        {
        }

        public FIMPowerShellActivityException(string message, Exception innerException)
            : base(message, innerException)
        {
        }

        public FIMPowerShellActivityException(SerializationInfo info, StreamingContext context)
            : base(info, context)
        {
        }

        public FIMPowerShellActivityException(RuntimeException innerException)
            : base(GetMessage(innerException), innerException)
        {
        }

        public static string GetMessage(RuntimeException ex)
        {
            return string.Format("{0}\r\n  Line {1:#,##0}\r\n  Column {2:#,##0}\r\n  {3}\r\n",
                        ex.Message,
                        ex.ErrorRecord.InvocationInfo.ScriptLineNumber,
                        ex.ErrorRecord.InvocationInfo.OffsetInLine,
                        ex.ErrorRecord.InvocationInfo.Line.Trim());
        }
    }
}
