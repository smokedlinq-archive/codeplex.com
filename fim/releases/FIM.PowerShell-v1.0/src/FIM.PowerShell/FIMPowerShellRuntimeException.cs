using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.Serialization;
using System.Management.Automation;

namespace FIM.PowerShell
{
    [Serializable]
    public class FIMPowerShellRuntimeException : Exception
    {
        public FIMPowerShellRuntimeException(RuntimeException innerException)
            : base(GetMessage(innerException), innerException)
        {
        }

        public FIMPowerShellRuntimeException(SerializationInfo info, StreamingContext context)
            : base(info, context)
        {
        }

        static string GetMessage(RuntimeException ex)
        {
            return string.Format("{0}\r\n  Line {1:#,##0}\r\n  Column {2:#,##0}\r\n  {3}\r\n",
                        ex.Message,
                        ex.ErrorRecord.InvocationInfo.ScriptLineNumber,
                        ex.ErrorRecord.InvocationInfo.OffsetInLine,
                        ex.ErrorRecord.InvocationInfo.Line.Trim());
        }
    }
}
