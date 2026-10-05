// ReimaginedOS - Copyright (C) ReimaginedOS and cr1mix
// Licensed under the GNU General Public License v3.0 or later - see LICENSE.txt
using System;
using System.Runtime.InteropServices;
using System.Threading;

internal static class Program
{
    private const uint DefaultResolution = 5000;
    private const uint MinResolution = 5000;
    private const uint MaxResolution = 156001;
    private const int ProcessPowerThrottling = 4;
    private const uint ThrottlingVersion = 1;
    private const uint IgnoreTimerResolution = 4;

    [StructLayout(LayoutKind.Sequential)]
    private struct PowerThrottlingState
    {
        public uint Version;
        public uint ControlMask;
        public uint StateMask;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct SystemPowerStatus
    {
        public byte ACLineStatus;
        public byte BatteryFlag;
        public byte BatteryLifePercent;
        public byte Reserved1;
        public int BatteryLifeTime;
        public int BatteryFullLifeTime;
    }

    [DllImport("kernel32.dll")]
    private static extern bool GetSystemPowerStatus(out SystemPowerStatus status);

    [DllImport("ntdll.dll")]
    private static extern int NtSetTimerResolution(uint desired, [MarshalAs(UnmanagedType.U1)] bool set, out uint current);

    [DllImport("kernel32.dll")]
    private static extern bool SetProcessInformation(IntPtr hProcess, int infoClass, ref PowerThrottlingState info, uint size);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetCurrentProcess();

    [DllImport("kernel32.dll")]
    private static extern bool FreeConsole();

    private static int Main(string[] args)
    {
        uint resolution = DefaultResolution;
        bool noConsole = false;
        for (int i = 0; i < args.Length; i++)
        {
            string a = args[i].ToLowerInvariant();
            if (a == "--help" || a == "-h" || a == "/?")
            {
                Console.WriteLine("ReimaginedOSTimer 1.0.0 by cr1mix - ReimaginedOS");
                Console.WriteLine("Holds the Windows timer at the requested resolution until stopped.");
                Console.WriteLine("Usage: ReimaginedOSTimer.exe [--resolution 5000] [--no-console]");
                Console.WriteLine("  resolution in 100-ns units, 5000 to 156001 (5000 = 0.5ms).");
                return 0;
            }
            else if (a == "--resolution" && i + 1 < args.Length && uint.TryParse(args[i + 1], out uint r) && r >= MinResolution && r <= MaxResolution)
            {
                resolution = r;
                i++;
            }
            else if (a == "--no-console")
            {
                noConsole = true;
            }
            else
            {
                Console.Error.WriteLine("Unknown argument: " + args[i]);
                return 1;
            }
        }

        bool created;
        using (var mutex = new Mutex(true, @"Global\ReimaginedOSTimer-holder", out created))
        {
            if (!created)
            {
                Console.Error.WriteLine("ReimaginedOSTimer is already running.");
                return 1;
            }

            if (noConsole)
            {
                try { FreeConsole(); } catch { }
            }

            try
            {
                var state = new PowerThrottlingState { Version = ThrottlingVersion, ControlMask = IgnoreTimerResolution, StateMask = 0 };
                SetProcessInformation(GetCurrentProcess(), ProcessPowerThrottling, ref state, (uint)Marshal.SizeOf<PowerThrottlingState>());
            }
            catch { }

            int status = NtSetTimerResolution(resolution, true, out uint current);
            if (status != 0)
            {
                Console.Error.WriteLine("NtSetTimerResolution failed.");
                return 1;
            }

            Console.WriteLine("ReimaginedOSTimer: resolution held at " + (current / 10000.0).ToString("0.####") + "ms. Stop this process to release.");
            Console.WriteLine("Battery-aware: releases the request while on battery, re-holds on AC power.");
            bool held = true;
            while (true)
            {
                Thread.Sleep(30000);
                try
                {
                    bool onAc = true;
                    if (GetSystemPowerStatus(out SystemPowerStatus ps))
                    {
                        onAc = ps.ACLineStatus != 0;
                    }
                    if (!onAc && held)
                    {
                        NtSetTimerResolution(resolution, false, out _);
                        held = false;
                        Console.WriteLine("ReimaginedOSTimer: on battery, request released.");
                    }
                    else if (onAc && !held)
                    {
                        if (NtSetTimerResolution(resolution, true, out uint cur2) == 0)
                        {
                            held = true;
                            Console.WriteLine("ReimaginedOSTimer: on AC, request re-held at " + (cur2 / 10000.0).ToString("0.####") + "ms.");
                        }
                    }
                }
                catch { }
            }
        }
    }
}
