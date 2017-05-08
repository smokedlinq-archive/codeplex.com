using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.MetadirectoryServices;
using System.Management.Automation;

namespace FIM.PowerShell
{
    public class MAExtensibleCallExport : FIMPowerShell, IMAExtensibleCallExport
    {
        string scriptPath;
        string connectTo;
        PSCredential credential;
        ConfigParameterCollection configParameters;
        TypeDescriptionCollection types;
        
        public void BeginExport(string connectTo, string user, string password, ConfigParameterCollection configParameters, TypeDescriptionCollection types)
        {
            this.Initialize();

            this.scriptPath = FIMUtils.FindMaScript("ExportEntry.ps1");
            this.connectTo = connectTo;
            this.credential = new PSCredential(user, FIMUtils.ConvertToSecureString(password));
            this.configParameters = configParameters;
            this.types = types;
        }

        public void EndExport()
        {
            this.Terminate();
        }

        public void ExportEntry(ModificationType modificationType, string[] changedAttributes, CSEntry csentry)
        {
            var command = this.CreateRuntime(this.scriptPath)
                                           .AddParameter("ConnectTo", this.connectTo)
                                           .AddParameter("Credential", this.credential)
                                           .AddParameter("Types", this.types);

            foreach (var item in configParameters)
            {
                command.AddParameter(item.Name, item.Value);
            }

            command.AddParameter("ModificationType", modificationType);
            command.AddParameter("ChangedAttributes", changedAttributes);
            command.AddParameter("CSEntry", csentry);

            var obj = this.Invoke(command);
        }
    }
}
