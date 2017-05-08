using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation.Runspaces;
using Microsoft.IdentityServer.ClaimsPolicy.Engine.AttributeStore;

namespace ADFS.PowerShell.AttributeStore
{
    public class PowerShellAttributeStore : IAttributeStore
    {
        Dictionary<string, string> _config;
        Func<Dictionary<string, string>, string, string[], string[][]> _delegate;

        public void Initialize(Dictionary<string, string> config)
        {
            this._config = new Dictionary<string, string>(config);
            this._delegate = new Func<Dictionary<string, string>, string, string[], string[][]>(Invoke);
        }

        public IAsyncResult BeginExecuteQuery(string query, string[] parameters, AsyncCallback callback, object state)
        {
            return this._delegate.BeginInvoke(this._config, query, parameters, callback, state);
        }

        public string[][] EndExecuteQuery(IAsyncResult result)
        {
            try
            {
                return this._delegate.EndInvoke(result);
            }
            catch (Exception ex)
            {
                throw new AttributeStoreQueryExecutionException(ex.Message, ex);
            }
        }

        static string[][] Invoke(Dictionary<string, string> config, string query, string[] parameters)
        {
            using (var runspace = RunspaceFactory.CreateRunspace())
            {
                runspace.ThreadOptions = PSThreadOptions.UseCurrentThread;
                runspace.Open();

                foreach (var item in config)
                    runspace.SessionStateProxy.SetVariable(item.Key, item.Value);

                using (var runtime = System.Management.Automation.PowerShell.Create())
                {
                    runtime.Runspace = runspace;
                    runtime.AddScript(query);

                    foreach (var parameter in parameters)
                        runtime.AddArgument(parameter);

                    var values = new List<string[]>();

                    foreach (var obj in runtime.Invoke())
                    {
                        if (obj.BaseObject is IEnumerable && !(obj.BaseObject is string))
                            values.Add(((IEnumerable)obj).Cast<object>().Select(i => i.ToString()).ToArray());
                        else if (obj.BaseObject is ValueType || obj.BaseObject is string)
                            values.Add(new string[] { obj.BaseObject.ToString() });
                        else
                            values.Add(obj.Properties.Select(p => p.Value.ToString()).ToArray());
                    }

                    return values.ToArray();
                }
            }
        }
    }
}
