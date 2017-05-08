using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using System.Threading;

namespace FIM.PowerShell.Workflow.Activities
{
    [Serializable]
    public abstract class PowerShellRunAs
    {
        public abstract void Invoke(Action action);
    }

    [Serializable]
    public class PowerShellRunAsFIM : PowerShellRunAs
    {
        public override void Invoke(Action action)
        {
            action();
        }
    }

    [Serializable]
    public class PowerShellRunAsRequestor : PowerShellRunAs
    {
        public override void Invoke(Action action)
        {
            using (((WindowsIdentity)Thread.CurrentPrincipal.Identity).Impersonate())
            {
                action();
            }
        }
    }

    [Serializable]
    public class PowerShellRunAsUser : PowerShellRunAs
    {
        public string UserName
        {
            get;
            set;
        }

        public string Password
        {
            get;
            set;
        }

        const int LOGON32_LOGON_BATCH = 4;
        const int LOGON32_PROVIDER_DEFAULT = 0;

        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool LogonUser(string lpszUserName, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
        public static extern bool CloseHandle(IntPtr handle);

        public override void Invoke(Action action)
        {
            var token = IntPtr.Zero;
            var domain = (string)null;
            var userName = this.UserName;

            if (userName.Contains('\\'))
            {
                var ntUser = userName.Split(new char[] { '\\' }, 2, StringSplitOptions.None);

                domain = ntUser[0];
                userName = ntUser[1];
            }
            else if (!userName.Contains('@'))
            {
                domain = ".";
            }

            if (LogonUser(userName, domain, PowerShellCryptography.Unprotect(this.Password), LOGON32_LOGON_BATCH, LOGON32_PROVIDER_DEFAULT, ref token))
            {
                try
                {
                    using (WindowsIdentity.Impersonate(token))
                    {
                        action();
                    }
                }
                finally
                {
                    CloseHandle(token);
                }
            }
            else
            {
                throw new FIMPowerShellActivityException(string.Format("Failed to login user '{0}', error 0x{1:X8}; USER={2} DOMAIN={3} ENCRYPTEDPASSWORD={4}", this.UserName, Marshal.GetLastWin32Error(), userName, domain, this.Password));
            }
        }
    }
}
