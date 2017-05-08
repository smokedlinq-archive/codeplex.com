using System;
using System.Globalization;
using System.Management.Automation.Host;
using System.Threading;

namespace FIM.PowerShell
{
    internal sealed class FIMPowerShellHost : PSHost
    {
        static readonly Version __version = new Version(1, 0, 0, 0);
        readonly FIMPowerShellHostUserInterface _ui;
        readonly Guid _instanceId;

        public FIMPowerShellHost()
        {
            this._ui = new FIMPowerShellHostUserInterface(); 
            this._instanceId = Guid.NewGuid();
        }

        public override CultureInfo CurrentCulture { get { return Thread.CurrentThread.CurrentCulture; } }
        public override CultureInfo CurrentUICulture { get { return Thread.CurrentThread.CurrentUICulture; } }
        public override Guid InstanceId { get { return this._instanceId; } }
        public override string Name { get { return "System.Web.PowerShell"; } }
        public override PSHostUserInterface UI { get { return _ui; } }
        public override Version Version { get { return __version; } }

        public override void EnterNestedPrompt() { }

        public override void ExitNestedPrompt() { }

        public override void NotifyBeginApplication() { }

        public override void NotifyEndApplication() { }

        public override void SetShouldExit(int exitCode) { }
    }
}
