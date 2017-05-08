using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.MetadirectoryServices;
using System.Management.Automation;

namespace FIM.PowerShell
{
    public class MAExtensibleFileImport : FIMPowerShell, IMAExtensibleFileImport
    {
        public void GenerateImportFile(string fileName, string connectTo, string user, string password, ConfigParameterCollection configParameters, bool fFullImport, TypeDescriptionCollection types, ref string customData)
        {
            string scriptPath = FIMUtils.FindMaScript("GenerateImportFile.ps1");

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
                                    .AddParameter("FullImport", fFullImport)
                                    .AddParameter("Types", types)
                                    .AddParameter("CustomData", customData);

                foreach (var item in configParameters)
                {
                    command.AddParameter(item.Name, item.Value);
                }

                var obj = this.Invoke(command).FirstOrDefault();

                if (obj != null)
                {
                    customData = obj.ToString();
                }
            }
            finally
            {
                this.Terminate();
            }
        }
    }
}
