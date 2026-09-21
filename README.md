<div align="center">
  <picture>
    <img src="https://github.com/cr1mix/ReimaginedOS/blob/main/banner.png?raw=true" alt="ReimaginedOS Banner" width="800" height="auto">
  </picture>

  <p>
    <a href="https://discord.gg/NjkgT7vXBb" aria-label="Beta test">
      <img src="https://img.shields.io/badge/BETA-0.1V-E5484D?style=for-the-badge&logo=windows11&logoColor=white" alt="Beta 0.1V testing">
    </a>
    <img src="https://img.shields.io/badge/WINDOWS-10_%2F_11-0d0d10?style=for-the-badge&logo=windows11&logoColor=white" alt="Windows">
    <img src="https://img.shields.io/badge/ARCH-AMD64-E5484D?style=for-the-badge" alt="Architecture">
    <a href="https://discord.gg/NjkgT7vXBb" aria-label="Discord">
      <img src="https://img.shields.io/badge/DISCORD-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord">
    </a>
  </p>
</div>

---

<div align="center">

<table align="center" width="85%">
<tr>

<td width="65%" align="center">

<h2>Windows, reimagined.</h2>

ReimaginedOS is a Windows optimization playbook for <strong>AME Wizard</strong>.

<br>
Built for a <strong>complete tweaked PC</strong> — not just debloat:
auto-tuning, driver profiles and custom tools.


<br>


Almost every tweak is optional. Choose what you want to change,
skip what you don't, and keep the parts of Windows you still use.
A small core (branding, diagnostics, boot safety) always applies.
A reboot is required after applying.
<br>

<strong>Performance · Debloat · Privacy · Gaming</strong>

</td>

<td width="35%" align="center">

<img src="https://github.com/user-attachments/assets/66d99414-6fb3-4e9e-9f81-a9ceda98a479" width="200" alt="ReimaginedOS Playbook">

</td>

</tr>
</table>

</div>

---

---

## Website

Visit the official website for more information, updates, and resources:

<p align="center">
  <a href="https://reimaginedos.pages.dev/">
    <img src="https://img.shields.io/badge/WEBSITE-REIMAGINEDOS.PAGES.DEV-E5484D?style=for-the-badge&logo=google-chrome&logoColor=white" alt="Website">
  </a>
</p>

---

## What is ReimaginedOS?

ReimaginedOS is a configurable Windows optimization playbook built for **AME Wizard**.

Instead of applying one fixed configuration to every system, the playbook lets you decide which changes should be made.

| Choose | Review | Apply |
| :---: | :---: | :---: |
| **Select the changes you want.** | **See what your selections change.** | **Only your selections are applied.** |

---

## Features

- **Drops the process count** — Background services and scheduled tasks can be reduced to keep Windows lighter.
- **Windows debloat** — Choose whether optional components such as Microsoft Store, Copilot, Widgets, OneDrive and Teams should be removed.
- **Privacy-focused controls** — Optional controls for telemetry, tracking, diagnostics and Windows privacy settings.
- **Gaming-first tuning** — Optional power, timer, network and background-process settings for a gaming-focused setup.
- **Intel** — ThrottleStop installed and profiled automatically: EPP, Speed Shift and core/cache undervolt where the chip allows it.
- **AMD** — RyzenAdj power tuning plus a deep driver block (light-sleep, clock and power gating off on desktops).
- **Per-hardware auto-tuning** — CPU vendor, chassis and thermals are detected at apply time, then matched power, parking and undervolt settings are applied.
- **NVIDIA profiles** — Separate Desktop and Laptop driver profiles, picked automatically and applied silently.
- **Custom open tools** — Timer, SleepCheck, ToolBox and Splash are written for ReimaginedOS and shipped inside, GPLv3.
- **Defender, your way** — Keep Defender enabled, configure selected settings, or disable it if you use another security solution.
- **Clean desktop** — Optional shortcuts, custom branding, wallpaper and an `apps` folder for everything else.

---

## Why ReimaginedOS?

<p align="center">
  <img src="https://img.shields.io/badge/AUTO--TUNING-per_hardware-E5484D?style=for-the-badge" alt="Auto-Tuning">
  <img src="https://img.shields.io/badge/NVIDIA-DESKTOP_%2B_LAPTOP-E5484D?style=for-the-badge" alt="NVIDIA">
  <img src="https://img.shields.io/badge/TOOLS-OPEN_SOURCE-0d0d10?style=for-the-badge" alt="Open tools">
  <img src="https://img.shields.io/badge/LICENSE-GPLv3-0d0d10?style=for-the-badge" alt="GPLv3">
</p>

**Auto-Tuning** — CPU vendor, chassis and thermals are detected at apply time, then matched power, parking and undervolt settings are applied. Skipped on battery and in VMs.

**NVIDIA profiles** — two driver profiles, picked automatically by chassis and applied silently:

<div align="center">

| Setting | Desktop | Laptop |
| :--- | :---: | :---: |
| Power management | Maximum performance | Driver default |
| Low Latency Mode | Ultra | On |
| Vertical Sync | Forced off | App default |
| Pre-rendered frames | 1 | 1 |
| Shader Cache | On | On |
| Texture filtering | High performance | High performance |
| AA / FXAA / Ansel | Off, app decides | Off, app decides |

</div>

**Custom tools, open source** — Timer, SleepCheck, ToolBox and Splash are written for ReimaginedOS, GPLv3, shipped inside the playbook.

---

## Under the hood

How the tuning actually works — no magic numbers without a reason:

- **ThrottleStop, automated** — Installed via winget (never bundled), then a profile INI is generated from your detected hardware: EPP for AC and DC, core/cache undervolt in mV, BD PROCHOT + C1E on hot laptops. Started by its own scheduled task at logon.
- **Core parking** — Parking policy rewritten per power plan, paired with EPP-tuned plans so cores unpark instantly under load and rest at idle.
- **Timer resolution** — Global timer requests plus native timer tools for sub-millisecond frame pacing where it matters.
- **NVIDIA via NVAPI** — The Base Profile is written straight into the driver store with a silent import, verified live on hardware. Desktop gets maximum performance, laptops keep their defaults.
- **Everything logged** — Every apply writes logs and a receipt. The ToolBox reads them back, so anything can be flipped off again.

---

## What actually changes?

ReimaginedOS is not one fixed configuration. The changes depend on the options you select in the playbook.

- **Services** — Optional Windows service configuration.
- **Scheduled Tasks** — Optional task configuration and cleanup.
- **Components** — Optional Windows component removal.
- **Privacy** — Telemetry, diagnostics and privacy-related settings.
- **Performance** — Power, CPU / GPU and system configuration.
- **Gaming** — Optional latency and background-process tweaks.

> [!NOTE]
> **No single configuration is forced on every system.**

---

## Results

On a tested **Windows 11 25H2** beta configuration, ReimaginedOS sits at approximately:

<div align="center">

<table align="center" width="55%">
<tr>
<td align="center"><b>~50</b><br><sub>Processes at idle</sub></td>
<td align="center"><b>~1 GB</b><br><sub>RAM at idle</sub></td>
</tr>
</table>

</div>

> [!WARNING]
> These figures are from a specific tested configuration and are not guaranteed system-wide.
> Results vary depending on hardware, drivers, Windows build, installed software and the options selected in the playbook.

---

## Meet the ToolBox

Every tweak as a toggle. Apply or revert in one click.

<p align="center">
  <img src="https://reimaginedos.pages.dev/assets/toolbox.jpg?raw=true" width="700" alt="ReimaginedOS ToolBox">
</p>

<div align="center">

| System | Performance | Information |
| :---: | :---: | :---: |
| Services · Wi-Fi · Bluetooth · Power | CPU / GPU settings and controls | Windows · CPU · RAM · GPU · Power plan |

</div>

<p align="center">
  <a href="https://github.com/cr1mix/reimaginedOS_toolbox">
    <img src="https://img.shields.io/badge/TOOLBOX-OPEN_SOURCE-E5484D?style=for-the-badge&logo=github&logoColor=white" alt="ToolBox source">
  </a>
</p>

---

## Defender

> [!IMPORTANT]
> **Security is your choice.** ReimaginedOS does not require one Defender configuration for every user.

- **Keep** — Leave Microsoft Defender enabled.
- **Configure** — Change selected Defender settings.
- **Disable** — Use another security solution if appropriate.

> [!WARNING]
> **Disabling security features can reduce system security.**
> Only disable protection if you understand the consequences and have appropriate protection in place.

---

## Getting Started

ReimaginedOS **0.1V is in beta testing** and runs through **AME Wizard**.

1. **Download** the playbook file.
2. **Open** it in AME Wizard.
3. **Review** options carefully.
4. **Choose** your tweaks.
5. **Apply** your custom selection.

> [!TIP]
> **Most of what applies is what you select.** A small core (branding, diagnostics, boot safety) always applies. A fresh, stock Windows installation is recommended before applying the playbook.
> Beta testers get a **custom role** on [Discord](https://discord.gg/NjkgT7vXBb).

---

## Supported Systems

ReimaginedOS currently targets **AMD64 / x64** Windows installations.

<p align="center">
  <img src="https://img.shields.io/badge/Windows%2010-22H2-0078D6?style=flat-square&logo=windows11&logoColor=white" alt="Windows 10 22H2">
  <img src="https://img.shields.io/badge/Windows%2011-23H2-0078D6?style=flat-square&logo=windows11&logoColor=white" alt="Windows 11 23H2">
  <img src="https://img.shields.io/badge/Windows%2011-24H2%20%2B%20LTSC-0078D6?style=flat-square&logo=windows11&logoColor=white" alt="Windows 11 24H2 LTSC">
  <img src="https://img.shields.io/badge/Windows%2011-25H2-0078D6?style=flat-square&logo=windows11&logoColor=white" alt="Windows 11 25H2">
</p>

---

## Transparency

ReimaginedOS is built around making system changes visible and selectable.

- **Visible changes** — Options are presented before they are applied.
- **User control** — Unwanted changes can simply be skipped.
- **Open source ToolBox** — Publicly inspectable at [github.com/cr1mix/reimaginedOS_toolbox](https://github.com/cr1mix/reimaginedOS_toolbox), open to community contributions.
- **No mystery configuration** — The goal is to make the purpose of each option understandable.

> [!NOTE]
> Always review the playbook and its options before applying system-level changes.

---

## Documentation

Technical documentation will cover the changes made by the playbook, including services, scheduled tasks, Windows components, privacy settings and other system-level modifications.

The goal is simple: **know what changes before you apply them.**

---

## Project Status

<p align="center">
  <img src="https://img.shields.io/badge/BETA-0.1V_TESTING-E5484D?style=flat-square" alt="Beta 0.1V">
  <img src="https://img.shields.io/badge/DEVELOPMENT-ACTIVE-5865F2?style=flat-square" alt="Development">
</p>

ReimaginedOS **0.1V is in beta testing**. Join the Discord, test it, report what breaks — testers get a **custom role**.

<p align="center">
  <a href="https://discord.gg/NjkgT7vXBb">
    <img src="https://img.shields.io/badge/BETA_TEST_NOW-GET_A_CUSTOM_ROLE-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Beta test now">
  </a>
</p>

---

## FAQ

<details>
<summary><strong>What is ReimaginedOS?</strong></summary>
<br>
ReimaginedOS is a Windows optimization playbook for AME Wizard focused on performance, debloating, privacy, gaming and system configuration.
</details>

<details>
<summary><strong>How do I join the beta?</strong></summary>
<br>
Join the <a href="https://discord.gg/NjkgT7vXBb">Discord</a>, test version 0.1V and report what breaks. Beta testers get a <strong>custom role</strong>.
</details>

<details>
<summary><strong>Does ReimaginedOS automatically remove things?</strong></summary>
<br>
Only some things. Important ones like Microsoft Store, Defender, Updates and Copilot are always asked about before removing.
</details>

<details>
<summary><strong>Can I keep things I still use?</strong></summary>
<br>
Yes. If you still use a Windows component, service or feature, simply skip its option in the playbook.
</details>

<details>
<summary><strong>Do I need AME Wizard?</strong></summary>
<br>
Yes. ReimaginedOS is designed to run through AME Wizard.<br><br>
<a href="https://download.ameliorated.io/AME%20Beta.zip">Get AME Wizard →</a>
</details>

<details>
<summary><strong>Can I keep Windows Defender?</strong></summary>
<br>
Yes. You can keep Defender enabled, configure selected settings, or disable it if you use another security solution.<br><br>
<strong>Warning:</strong> Disabling security features can reduce system security.
</details>

<details>
<summary><strong>Will I get the same results shown above?</strong></summary>
<br>
Not necessarily. The ~50 process and ~1 GB RAM figures are approximate, measured on a Windows 11 25H2 beta test configuration.<br><br>
Results depend on hardware, drivers, Windows build, installed software and the options selected in the playbook.
</details>

<details>
<summary><strong>Which Windows versions are supported?</strong></summary>
<br>
Windows 10 22H2 and Windows 11 23H2, 24H2 / LTSC and 25H2 on AMD64.
</details>

<details>
<summary><strong>Is the ToolBox open source?</strong></summary>
<br>
Yes: <a href="https://github.com/cr1mix/reimaginedOS_toolbox">github.com/cr1mix/reimaginedOS_toolbox</a> — inspect it and contribute.
</details>

---

## Links

<p align="center">
  <a href="https://reimaginedos.pages.dev/">
    <img src="https://img.shields.io/badge/Website-222222?style=flat-square&logo=google-chrome&logoColor=white" alt="Website">
  </a>
  <a href="https://discord.gg/NjkgT7vXBb">
    <img src="https://img.shields.io/badge/Discord-5865F2?style=flat-square&logo=discord&logoColor=white" alt="Discord">
  </a>
  <a href="https://tiktok.com/@cr1mix">
    <img src="https://img.shields.io/badge/TikTok-000000?style=flat-square&logo=tiktok&logoColor=white" alt="TikTok">
  </a>
  <a href="https://github.com/cr1mix">
    <img src="https://img.shields.io/badge/GitHub-cr1mix-181717?style=flat-square&logo=github&logoColor=white" alt="GitHub">
  </a>
</p>

---

<br>

<p align="center">
  <img src="https://avatars.githubusercontent.com/u/220206221?v=4" width="170" height="170" alt="𝕮𝖗1𝖒𝖎𝖝">
</p>

<h2 align="center">𝕮𝖗1𝖒𝖎𝖝</h2>

<p align="center">
  <sub>Creator of ReimaginedOS :3</sub>
</p>

<p align="center">
  <a href="https://github.com/cr1mix">
    <img src="https://img.shields.io/badge/GitHub-cr1mix-181717?style=flat-square&logo=github&logoColor=white" alt="GitHub">
  </a>
</p>

<br>

<p align="center">
© 2026 𝕮𝖗1𝖒𝖎𝖝 · ReimaginedOS
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Windows%2C-REIMAGINED-E5484D?style=for-the-badge" alt="Windows, Reimagined">
  <br>
  <sub>Windows, <strong>Reimagined</strong>.</sub>
</p>
