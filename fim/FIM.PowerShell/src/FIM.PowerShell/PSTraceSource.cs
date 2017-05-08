using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;
using Microsoft.MetadirectoryServices;
using Microsoft.Win32;

namespace FIM.PowerShell
{
    public class PSTraceSource : TraceSource
    {
        public PSTraceSource(string name)
            : base(name)
        {
            try
            {
                var key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Forefront Identity Manager\2010\Synchronization Service\FIM.PowerShell");
                var path = (string)key.GetValue("Path", string.Empty);

                if (!string.IsNullOrWhiteSpace(path))
                {
                    if (!Directory.Exists(path))
                        Directory.CreateDirectory(path);

                    var value = (string)key.GetValue("Level", string.Empty);
                    var sourceLevel = SourceLevels.Off;

                    if (!Enum.TryParse<SourceLevels>(value, out sourceLevel))
                        sourceLevel = SourceLevels.All;

                    this.Switch.Level = sourceLevel;

                    this.Listeners.Add(new XmlWriterTraceListener(Path.Combine(path, "FIM.PowerShell.svclog"), "PSTraceSourceXmlWriterTraceListener"));
                }
            }
            catch
            {
                // NOOP
            }
        }

        public IDisposable TraceMethod()
        {
            return TraceMethod(GetCallingMethodDefinition());
        }

        IDisposable TraceMethod(string activityName)
        {
            var activity = PowerShellTraceActivity.Start(this, activityName);

            try
            {
                if (!string.IsNullOrWhiteSpace(MAUtils.MAFolder))
                {
                    var maName = Directory.GetParent(MAUtils.MAFolder).Name;
                    this.TraceVerbose("Current Management Agent: {0}", maName);
                }
            }
            catch (InvalidOperationException)
            {
                // NOOP
            }

            return activity;
        }

        [Conditional("TRACE")]
        public void TraceParameter<T>(string parameterName, T obj)
        {
            TraceObject(TraceEventType.Verbose, obj, parameterName);
        }

        [Conditional("TRACE")]
        public void TraceObject<T>(T obj)
        {
            if (obj == null)
                return;

            TraceObject(TraceEventType.Verbose, obj, typeof(T).AssemblyQualifiedName);
        }

        [Conditional("TRACE")]
        public void TraceObject<T>(TraceEventType eventType, T obj, string name)
        {
            if (obj == null || !this.Switch.ShouldTrace(eventType))
                return;

            if (obj is ValueType)
            {
                this.TraceEvent(eventType, 0, obj.ToString());
            }
            else if (obj is Delegate)
            {
                this.TraceEvent(eventType, 0, "Delegate: " + obj.ToString());
            }
            else
            {
                try
                {
                    var serializer = new JavaScriptSerializer();
                    var json = serializer.Serialize(obj);

                    if (string.IsNullOrWhiteSpace(name))
                        this.TraceEvent(eventType, 0, name + ": " + json);
                }
                catch (Exception ex)
                {
                    // Try to trace the object as data and log that we failed to trace the object
                    this.TraceData(eventType, 0, obj);
                    this.TraceException(TraceEventType.Error, ex, "TraceObject failed: {0}", name);
                }
           }
        }

        [Conditional("TRACE")]
        public void TraceVerbose(string message)
        {
            this.TraceEvent(TraceEventType.Verbose, 0, message);
        }

        [Conditional("TRACE")]
        public void TraceVerbose(string format, params object[] args)
        {
            this.TraceEvent(TraceEventType.Verbose, 0, format, args);
        }

        [Conditional("TRACE")]
        public void TraceException(TraceEventType eventType, Exception ex, string format, params object[] args)
        {
            this.TraceEvent(eventType, 0, format, args);
            this.TraceData(eventType, 0, ex);
        }

        [MethodImpl(MethodImplOptions.NoInlining)]
        static string GetCallingMethodDefinition(int skipFrames = 2)
        {
            var sb = new StringBuilder();

            try
            {
                var frame = new StackFrame(skipFrames, true);
                var method = frame.GetMethod();
                var declaringType = method.DeclaringType;
                var parameters = method.GetParameters();
                

                sb.AppendFormat(Thread.CurrentThread.CurrentCulture, "[{0}", method.DeclaringType.FullName);

                if (declaringType.IsGenericType)
                {
                    sb.Append("<");
                    sb.Append(string.Join(", ", declaringType.GetGenericArguments().Select(i => string.Format(Thread.CurrentThread.CurrentCulture, "[{0}]", i.FullName)).ToArray()));
                    sb.Append(">");
                }

                sb.AppendFormat(Thread.CurrentThread.CurrentCulture, "]::{0}", method.Name);
                
                if (method.IsGenericMethod)
                {
                    sb.Append("<");
                    sb.Append(string.Join(", ", method.GetGenericArguments().Select(i => string.Format(Thread.CurrentThread.CurrentCulture, "[{0}]", i.FullName)).ToArray()));
                    sb.Append(">");
                }

                sb.Append("(");

                if (parameters != null && parameters.Length > 0)
                    sb.Append(string.Join(", ", parameters.Select(i => string.Format(Thread.CurrentThread.CurrentCulture, "[{0}] {1}", i.ParameterType.FullName, i.Name)).ToArray()));

                sb.Append(")");
            }
            catch
            {
            }

            return sb.ToString();
        }

        class PowerShellTraceActivity : IDisposable
        {
            private Guid _previousActivityId;
            private Guid _activityId;
            private TraceSource _source;
            private Stopwatch _sw;
            private string _name;

            private PowerShellTraceActivity(TraceSource source, string name)
            {
                this._source = source;
                this._name = name;

                this._previousActivityId = Trace.CorrelationManager.ActivityId;
                this._activityId = Guid.NewGuid();

                this._sw = Stopwatch.StartNew();
            }

            public static PowerShellTraceActivity Start(TraceSource source, string name)
            {
                var activity = new PowerShellTraceActivity(source, name);

                if (activity._previousActivityId != Guid.Empty)
                    source.TraceTransfer(0, null, activity._activityId);

                Trace.CorrelationManager.ActivityId = activity._activityId;

                source.TraceEvent(TraceEventType.Start, 0, "{0}::{1}", source.Name, activity._name);

                return activity;
            }

            ~PowerShellTraceActivity()
            {
                Dispose(false);
            }

            void IDisposable.Dispose()
            {
                Dispose(true);
                GC.SuppressFinalize(this);
            }

            [Conditional("TRACE")]
            public void Complete()
            {
                if (this._previousActivityId != Guid.Empty)
                    this._source.TraceTransfer(0, null, this._previousActivityId);

                this._source.TraceEvent(TraceEventType.Stop, 0, "{0}::{1} ({2:#,##0.###} ms)", this._source.Name, this._name, this._sw.ElapsedMilliseconds);
                Trace.CorrelationManager.ActivityId = this._previousActivityId;
            }

            private void Dispose(bool disposing)
            {
                if (disposing)
                {
                    if (this._source != null)
                    {
                        this.Complete();
                        this._source = null;
                    }
                }
            }
        }
    }
}
