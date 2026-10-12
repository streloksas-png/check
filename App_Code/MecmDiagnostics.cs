using System;
using System.Diagnostics;

public static class MecmDiagnostics
{
    public static void LogDataError(string context, Exception exception)
    {
        // Use listeners directly: logging must survive release compilation
        // even when the conditional TRACE compiler symbol is not defined.
        foreach (TraceListener listener in Trace.Listeners)
        {
            try
            {
                listener.TraceEvent(null, "MECM Dashboard", TraceEventType.Error,
                    0, "{0}: {1}", context, exception);
                listener.Flush();
            }
            catch (Exception)
            {
                // Failure of a diagnostic sink must not disclose an exception
                // to the browser or interrupt the neutral error response.
            }
        }
    }
}
