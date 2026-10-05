ReimaginedOS - custom tools source code
========================================
This playbook: https://github.com/cr1mix/ReimaginedOS

Every project below is GPLv3 (Copyright (C) ReimaginedOS and cr1mix):
each source file carries the header, each folder its LICENSE.txt,
full text in the playbook root LICENSE.txt.

Clean, publishable sources (build with: dotnet publish -c Release -r win-x64):
  ReimaginedOS About\        - first-boot welcome screen (WPF, self-contained).
                               Ships as Executables\About\ReimaginedOS-About.exe
  ReimaginedOS Timer\        - high-resolution timer tool (NativeAOT).
                               Ships as PostInstall\1-CPU\TIMER-RESOLUTION\ReimaginedOSTimer.exe
  ReimaginedOS Sleep Check\  - sleep-state checker (NativeAOT).
                               Ships as PostInstall\1-CPU\TIMER-RESOLUTION\ReimaginedOSSleepCheck.exe

  toolbox.txt  - where the ToolBox source code lives (separate repo).
