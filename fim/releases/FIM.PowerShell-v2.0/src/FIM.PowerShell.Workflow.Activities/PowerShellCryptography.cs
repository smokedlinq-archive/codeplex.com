using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace FIM.PowerShell.Workflow.Activities
{
    public static class PowerShellCryptography
    {
        static readonly byte[] __encryptionKey = Convert.FromBase64String(ConfigurationManager.AppSettings["FIMPowerShellActivity.EncryptionKey"]);

        public static string Protect(string data)
        {
            using (var aes = AesCryptoServiceProvider.Create())
            {
                aes.Key = __encryptionKey;
                aes.GenerateIV();

                var encryptor = aes.CreateEncryptor(aes.Key, aes.IV);

                using (var msEncrypt = new MemoryStream())
                {
                    using (var csEncrypt = new CryptoStream(msEncrypt, encryptor, CryptoStreamMode.Write))
                    {
                        using (var swEncrypt = new StreamWriter(csEncrypt))
                        {
                            swEncrypt.Write(data);
                        }
                    }

                    var buffer = msEncrypt.ToArray();
                    var encrypted = new byte[aes.IV.Length + buffer.Length];
                    
                    Array.Copy(aes.IV, encrypted, aes.IV.Length);
                    Array.Copy(buffer, 0, encrypted, aes.IV.Length, buffer.Length);

                    return Convert.ToBase64String(encrypted);
                }
            }
        }

        public static string Unprotect(string data)
        {
            var encrypted = Convert.FromBase64String(data);
            
            using (var aes = AesCryptoServiceProvider.Create())
            {
                var blockSize = aes.BlockSize / 8;

                aes.Key = __encryptionKey;
                aes.IV = encrypted.Take(blockSize).ToArray();

                var decryptor = aes.CreateDecryptor(aes.Key, aes.IV);

                using (var msDecrypt = new MemoryStream(encrypted.Skip(blockSize).ToArray()))
                {
                    using (var csDecrypt = new CryptoStream(msDecrypt, decryptor, CryptoStreamMode.Read))
                    {
                        using (var srDecrypt = new StreamReader(csDecrypt))
                        {
                            return srDecrypt.ReadToEnd();
                        }
                    }
                }
            }
        }
    }
}
