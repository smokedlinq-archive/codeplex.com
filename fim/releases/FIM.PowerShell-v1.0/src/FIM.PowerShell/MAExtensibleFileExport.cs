using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.MetadirectoryServices;
using System.Management.Automation;
using System.Security;

namespace FIM.PowerShell
{
    public class MAExtensibleFileExport : FIMPowerShell, IMAExtensibleFileExport
    {
        public void DeliverExportFile(string fileName, string connectTo, string user, string password, ConfigParameterCollection configParameters, TypeDescriptionCollection types)
        {
            string scriptPath = FIMUtils.FindMaScript("DeliverExportFile.ps1");

            if (scriptPath == null)
            {
                throw new EntryPointNotImplementedException();
            }

            this.Initialize();

            try
            {
                var command = this.CreateRuntime(scriptPath)
                                            .AddParameter("FileName", fileName)
                                            .AddParameter("ConnectTo", connectTo)
                                            .AddParameter("Credential", new PSCredential(user, FIMUtils.ConvertToSecureString(password)))
                                            .AddParameter("Types", types);

                foreach (var item in configParameters)
                {
                    command.AddParameter(item.Name, item.Value);
                }

                var obj = this.Invoke(command);
            }
            finally
            {
                this.Terminate();
            }
        }
    }
}
