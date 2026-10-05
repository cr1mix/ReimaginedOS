// ReimaginedOS - Copyright (C) ReimaginedOS and cr1mix
// Licensed under the GNU General Public License v3.0 or later - see LICENSE.txt
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Threading;

internal static class Program
{
    [DllImport("ntdll.dll")]
    private static extern int NtQueryTimerResolution(out uint min, out uint max, out uint current);

    private static bool IsElevated()
    {
        try
        {
            using (WindowsIdentity id = WindowsIdentity.GetCurrent())
            {
                return new WindowsPrincipal(id).IsInRole(WindowsBuiltInRole.Administrator);
            }
        }
        catch { return false; }
    }

    private static int Main(string[] args)
    {
        int sleepMs = 1;
        int samples = 0;
        for (int i = 0; i < args.Length; i++)
        {
            string a = args[i].ToLowerInvariant();
            if (a == "--help" || a == "-h" || a == "/?")
            {
                Console.WriteLine("ReimaginedOSSleepCheck 1.0.0 by cr1mix - ReimaginedOS");
                Console.WriteLine("Measures the real Sleep() delay against the current timer resolution.");
                Console.WriteLine("Usage: ReimaginedOSSleepCheck.exe [--sleep_n 1] [--samples 50]");
                return 0;
            }
            else if (a == "--sleep_n" && i + 1 < args.Length && int.TryParse(args[i + 1], out int s) && s >= 1 && s <= 1000)
            {
                sleepMs = s;
                i++;
            }
            else if (a == "--samples" && i + 1 < args.Length && int.TryParse(args[i + 1], out int n) && n >= 2)
            {
                samples = n;
                i++;
            }
            else
            {
                Console.Error.WriteLine("Unknown argument: " + args[i]);
                return 1;
            }
        }

        if (!IsElevated())
        {
            Console.Error.WriteLine("Run as administrator for stable results.");
            return 1;
        }

        try { Process.GetCurrentProcess().PriorityClass = ProcessPriorityClass.RealTime; }
        catch { Console.WriteLine("Realtime priority unavailable, measuring anyway."); }

        var delays = new List<double>();
        for (int i = 1; ; i++)
        {
            if (NtQueryTimerResolution(out _, out _, out uint current) != 0)
            {
                Console.Error.WriteLine("NtQueryTimerResolution failed.");
                return 1;
            }

            long t0 = Stopwatch.GetTimestamp();
            Thread.Sleep(sleepMs);
            double deltaMs = (Stopwatch.GetTimestamp() - t0) * 1000.0 / Stopwatch.Frequency;
            double over = deltaMs - sleepMs;

            Console.WriteLine("Resolution: " + (current / 10000.0).ToString("0.0000") + "ms, Sleep(n=" + sleepMs + ") slept " + deltaMs.ToString("0.0000") + "ms (over: " + over.ToString("0.0000") + ")");

            if (samples > 0)
            {
                delays.Add(over);
                if (i == samples)
                {
                    break;
                }
                Thread.Sleep(100);
            }
            else
            {
                Thread.Sleep(1000);
            }
        }

        if (samples > 0)
        {
            delays.RemoveAt(0);
            delays.Sort();
            double sum = 0;
            foreach (double d in delays)
            {
                sum += d;
            }
            double avg = sum / delays.Count;
            double dev = 0;
            foreach (double d in delays)
            {
                dev += (d - avg) * (d - avg);
            }
            double stdev = delays.Count > 1 ? Math.Sqrt(dev / (delays.Count - 1)) : 0;
            Console.WriteLine("");
            Console.WriteLine("Results from " + delays.Count + " samples");
            Console.WriteLine("Max: " + delays[delays.Count - 1].ToString("0.0000"));
            Console.WriteLine("Avg: " + avg.ToString("0.0000"));
            Console.WriteLine("Min: " + delays[0].ToString("0.0000"));
            Console.WriteLine("STDEV: " + stdev.ToString("0.0000"));
        }

        return 0;
    }
}
