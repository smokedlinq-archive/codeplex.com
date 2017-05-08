using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Host;
using System.Security;

namespace FIM.PowerShell.Workflow.Activities
{
    internal sealed class FIMPowerShellHostUserInterface : PSHostUserInterface
    {
        static readonly FIMPowerShellHostRawUserInterface __rawUI = new FIMPowerShellHostRawUserInterface();

        public FIMPowerShellHostUserInterface() { }

        public override PSHostRawUserInterface RawUI { get { return __rawUI; } }

        public override Dictionary<string, PSObject> Prompt(string caption, string message, Collection<FieldDescription> descriptions) { throw new NotSupportedException(); }

        public override int PromptForChoice(string caption, string message, Collection<ChoiceDescription> choices, int defaultChoice) { throw new NotSupportedException(); }

        public override PSCredential PromptForCredential(string caption, string message, string userName, string targetName, PSCredentialTypes allowedCredentialTypes, PSCredentialUIOptions options) { throw new NotSupportedException(); }

        public override PSCredential PromptForCredential(string caption, string message, string userName, string targetName) { throw new NotSupportedException(); }

        public override string ReadLine() { throw new NotSupportedException(); }

        public override SecureString ReadLineAsSecureString() { throw new NotSupportedException(); }

        public override void Write(ConsoleColor foregroundColor, ConsoleColor backgroundColor, string value) { }

        public override void Write(string value) { }

        public override void WriteDebugLine(string message) { }

        public override void WriteErrorLine(string value) { }

        public override void WriteLine(string value) { }

        public override void WriteProgress(long sourceId, ProgressRecord record) { }

        public override void WriteVerboseLine(string message) { }

        public override void WriteWarningLine(string message) { }
    }
}
