# ReimaginedOS

<div align="center">

### Windows, reimagined.

A Windows optimization playbook for **AME Wizard** focused on performance, privacy, debloating and control.

![Status](https://img.shields.io/badge/status-Coming%20Soon-orange?style=for-the-badge)
![Windows](https://img.shields.io/badge/Windows-10%20%2F%2011-0078D6?style=for-the-badge&logo=windows11&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-AMD64-blue?style=for-the-badge)

[![Discord](https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/NjkgT7vXBb)
[![Website](https://img.shields.io/badge/Website-GitHub%20Pages-222222?style=for-the-badge&logo=github&logoColor=white)](https://cr1mix.github.io/reimaginedos-github.io/)
[![TikTok](https://img.shields.io/badge/TikTok-000000?style=for-the-badge&logo=tiktok&logoColor=white)](https://tiktok.com/@cr1mix)

</div>

---

<table>
<tr>
<td width="55%" valign="top">

<h2>What is ReimaginedOS?</h2>

<p>
ReimaginedOS is a Windows optimization playbook built for
<a href="https://github.com/Ameliorated-LLC/trusted-uninstaller-cli/releases/tag/0.8.4">
AME Wizard
</a>.
</p>

<p>
It is designed for people who want a cleaner Windows installation
without manually going through hundreds of services, scheduled tasks
and system settings.
</p>

<p>
The playbook lets you choose what you want to change before anything
is applied.
</p>

<p><strong>No forced configuration. No mystery tweaks.</strong></p>

<h3>Built around four things</h3>

<ul>
<li>⚡ <strong>Performance</strong> — reduce unnecessary background activity</li>
<li>🧹 <strong>Debloat</strong> — remove Windows components you don't need</li>
<li>🔒 <strong>Privacy</strong> — configure telemetry and tracking-related settings</li>
<li>🎮 <strong>Gaming</strong> — optional performance and latency-oriented tweaks</li>
</ul>

</td>

<td width="45%" align="center" valign="middle">

<img src="https://cr1mix.github.io/reimaginedos-github.io/assets/playbook.png" alt="ReimaginedOS Playbook" width="380">

</td>
</tr>
</table>

---

## ✨ Features

### ⚡ Performance

Reduce unnecessary background activity and configure Windows for a lighter setup.

- Background services
- Scheduled tasks
- Power plans
- Timer-related settings
- CPU / GPU tweaks
- System performance settings

### 🧹 Debloat

Remove or disable optional Windows components you don't want.

- Microsoft Store
- OneDrive
- Widgets
- Copilot
- Microsoft Teams
- Other optional components

Changes are optional and can be reviewed before applying them.

### 🔒 Privacy

Take control over Windows telemetry and privacy-related configuration.

- Telemetry settings
- Diagnostic data
- Tracking-related services
- Windows privacy options
- Windows Update configuration

### 🎮 Gaming

Optional tweaks aimed at reducing unnecessary overhead while gaming.

- Power configuration
- Network settings
- Latency-related tweaks
- Background process reduction
- Timer and scheduling settings

> Results will vary depending on your hardware and Windows configuration.

---

## 🛡️ Windows Defender

Windows Defender is **your choice**.

ReimaginedOS provides different configuration options instead of assuming everyone wants the same setup.

You can:

- Keep Defender enabled
- Change selected Defender settings
- Disable Defender if you use another security solution

> **⚠️ Disabling security features can make your system less secure. Only change these settings if you understand the consequences.**

---

## 🛠️ ToolBox

The **ReimaginedOS ToolBox** is a lightweight companion application designed to manage common system settings after the initial playbook run.

### Current functionality

| Category | Included |
|---|---|
| System information | OS, CPU, RAM, GPU, power plan |
| Services | Service management |
| Network | Wi-Fi and Bluetooth controls |
| Performance | CPU / GPU related settings |
| Windows Update | Update controls |
| Defender | Defender controls |
| Privacy | Telemetry settings |
| Power | Power plan management |

The ToolBox keeps commonly used controls in one place instead of making you dig through Windows settings every time.

---

## 💻 Supported Systems

ReimaginedOS currently targets **AMD64 / x64** Windows installations.

![Windows 10 22H2](https://img.shields.io/badge/Windows%2010-22H2-0078D6?style=for-the-badge&logo=windows11&logoColor=white) ![Windows 11 23H2](https://img.shields.io/badge/Windows%2011-23H2-0078D6?style=for-the-badge&logo=windows11&logoColor=white) ![Windows 11 24H2](https://img.shields.io/badge/Windows%2011-24H2-0078D6?style=for-the-badge&logo=windows11&logoColor=white) ![Windows 11 24H2 LTSC](https://img.shields.io/badge/Windows%2011-24H2%20LTSC-0078D6?style=for-the-badge&logo=windows11&logoColor=white) ![Windows 11 25H2](https://img.shields.io/badge/Windows%2011-25H2-0078D6?style=for-the-badge&logo=windows11&logoColor=white)

Support for additional Windows versions may be added as development continues.

---

## 🚀 How it works

ReimaginedOS runs through **AME Wizard**.

```text
Windows
   │
   ▼
AME Wizard
   │
   ▼
ReimaginedOS Playbook
   │
   ├── Performance
   ├── Debloat
   ├── Privacy
   ├── Gaming
   └── System configuration
   │
   ▼
Your Windows installation
