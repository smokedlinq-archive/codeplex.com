using System;
using System.Linq;
using System.IO;
using System.Management.Automation;
using Microsoft.MetadirectoryServices;
using System.Security;

namespace FIM.PowerShell
{
    internal static class FIMUtils
    {
        public static string GetMaScriptPath(string maName, string scriptName)
        {
            return FindMaScript(Path.GetFullPath(Path.Combine(Utils.ExtensionsDirectory, @"..\MaData\" + maName)), scriptName);
        }

        public static string FindMaScript(string scriptName)
        {
            return FindMaScript(MAUtils.MAFolder, scriptName);
        }

        public static string FindMaScript(string folder, string scriptName)
        {
            return Directory.GetFiles(folder, scriptName, SearchOption.AllDirectories).FirstOrDefault();
        }

        public static string GetExtensionProfilePath()
        {
            return Path.GetFullPath(Path.Combine(Utils.ExtensionsDirectory, @"FIM.PowerShell.ps1"));
        }

        public static T GetProperty<T>(this PSObject obj, string propertyName, T defaultValue = default(T))
        {
            try
            {
                var property = obj.Properties[propertyName];

                if (property != null)
                {
                    if (property.Value is PSObject)
                    {
                        return (T)((PSObject)property.Value).BaseObject;
                    }

                    return (T)property.Value;
                }

                return defaultValue;
            }
            catch (Exception ex)
            {
                throw new ArgumentException(string.Format("The property '{0}' could not be retrieved from the PSObject: {1}", propertyName, ex.Message), ex);
            }
        }

        internal static SecureString ConvertToSecureString(string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return null;
            }

            var secret = new SecureString();

            foreach (var c in value)
            {
                secret.AppendChar(c);
            }

            secret.MakeReadOnly();

            return secret;
        }
    }
}
