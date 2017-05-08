using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace FIM.PowerShell
{
    internal sealed class FIMPowerShellScriptCache : IDisposable
    {
        Dictionary<string, string> _items;
        List<FileSystemWatcher> _watchers;

        public FIMPowerShellScriptCache()
        {
            this._items = new Dictionary<string,string>(StringComparer.InvariantCultureIgnoreCase);
            this._watchers = new List<FileSystemWatcher>();
        }

        ~FIMPowerShellScriptCache()
        {
            Dispose(false);
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        void Dispose(bool disposing)
        {
            if (disposing)
            {
                foreach (var fsw in this._watchers)
                {
                    fsw.Dispose();
                }

                this._watchers.Clear();
                this._items.Clear();
            }
        }

        public string this[string path]
        {
            get
            {
                var info = new FileInfo(path);

                if (!this._items.ContainsKey(path))
                {
                    lock (this._items)
                    {
                        if (!this._items.ContainsKey(path))
                        {
                            if (File.Exists(path))
                            {
                                this._items.Add(path, File.ReadAllText(path));

                                // Use a FileSystemWatcher to remove the item from cache if it changes
                                var fsw = new FileSystemWatcher(info.DirectoryName, info.Name)
                                {
                                    NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.Size | NotifyFilters.FileName
                                };

                                this._watchers.Add(fsw);

                                fsw.Changed += (sender, e) => Remove((FileSystemWatcher)sender, e.FullPath);
                                fsw.Deleted += (sender, e) => Remove((FileSystemWatcher)sender, e.FullPath);
                                fsw.Renamed += (sender, e) => Remove((FileSystemWatcher)sender, e.OldFullPath);

                                fsw.EnableRaisingEvents = true;
                            }
                            else
                            {
                                this._items.Add(path, null);
                            }
                        }
                    }
                }

                return this._items[path];
            }
        }

        void Remove(FileSystemWatcher fsw, string path)
        {
            lock (this._items)
            {
                if (this._items.ContainsKey(path))
                {
                    this._items.Remove(path);
                }

                fsw.Dispose();
                this._watchers.Remove(fsw);
            }
        }
    }
}
