# ReimaginedOS

<p align="center">
  <img src="https://avatars.githubusercontent.com/u/220206221?v=4" width="110" alt="cr1mix">
</p>

<h3 align="center">Windows, reimagined.</h3>

<p align="center">
  A configurable Windows optimization playbook for <strong>AME Wizard</strong>.
</p>

<p align="center">
  Performance · Privacy · Debloat · Gaming
</p>

<p align="center">
  <img src="https://img.shields.io/badge/STATUS-COMING%20SOON-orange?style=for-the-badge" alt="Status">
  <img src="https://img.shields.io/badge/WINDOWS-10%20%2F%2011-0078D6?style=for-the-badge&logo=windows11&logoColor=white" alt="Windows">
  <img src="https://img.shields.io/badge/ARCH-x64-5865F2?style=for-the-badge" alt="Architecture">
</p>

<p align="center">
  <a href="https://discord.gg/NjkgT7vXBb">
    <img src="https://img.shields.io/badge/DISCORD-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord">
  </a>
  <a href="https://cr1mix.github.io/reimaginedos-github.io/">
    <img src="https://img.shields.io/badge/WEBSITE-222222?style=for-the-badge&logo=github&logoColor=white" alt="Website">
  </a>
  <a href="https://tiktok.com/@cr1mix">
    <img src="https://img.shields.io/badge/TIKTOK-000000?style=for-the-badge&logo=tiktok&logoColor=white" alt="TikTok">
  </a>
</p>

---

<p align="center">
  <img src="https://cr1mix.github.io/reimaginedos-github.io/assets/playbook.png" width="850" alt="ReimaginedOS Playbook">
</p>

## What is ReimaginedOS?

ReimaginedOS is a **Windows optimization playbook** built for [AME Wizard](https://github.com/Ameliorated-LLC/trusted-uninstaller-cli/releases/tag/0.8.4).

It is made for users who want more control over their Windows installation without manually going through hundreds of services, scheduled tasks and system settings.

ReimaginedOS does not rely on one huge preset. The playbook is divided into individual options so you can choose what you actually want to change.

> **Choose what you need. Skip what you don't.**

The project focuses on four main areas:

| ⚡ Performance | 🧹 Debloat | 🔒 Privacy | 🎮 Gaming |
|:---:|:---:|:---:|:---:|
| Reduce unnecessary background activity | Remove unwanted components | Configure telemetry & privacy | Optional performance tweaks |

---

# Features

## ⚡ Performance

Tune Windows without turning the system into a black box.

- Background service configuration
- Scheduled task management
- Power plan configuration
- Timer-related settings
- CPU / GPU related tweaks
- General system performance settings

## 🧹 Debloat

Remove Windows components and applications you don't use.

Possible targets include:

- Microsoft Store
- OneDrive
- Widgets
- Copilot
- Microsoft Teams
- Optional Windows components
- Unnecessary background services

All changes are configurable through the playbook.

## 🔒 Privacy

Take control over Windows privacy and telemetry settings.

- Telemetry configuration
- Diagnostic data
- Tracking-related services
- Windows privacy settings
- Windows Update configuration

The goal is to reduce unnecessary background communication while keeping the system usable.

## 🎮 Gaming

Optional settings for users who want a more gaming-focused configuration.

- Power configuration
- Network settings
- Latency-related tweaks
- Background process reduction
- Timer and scheduling configuration

> Performance improvements vary depending on hardware, drivers, games and the existing Windows configuration.

---

# 🛡️ Windows Defender

Security configuration is optional.

ReimaginedOS gives you control instead of forcing a single Defender setup.

You can:

- Keep Microsoft Defender enabled
- Modify selected Defender settings
- Disable Defender if you use another security solution

> **⚠️ Disabling security features can reduce system security. Only do so if you understand the consequences.**

---

# 🛠️ ReimaginedOS ToolBox

The playbook handles the initial configuration.

The **ToolBox** is designed for managing commonly used settings afterwards.

### Current areas

| Category | Controls |
|---|---|
| 🖥️ System | OS, CPU, RAM, GPU, power plan |
| ⚡ Performance | CPU / GPU related settings |
| 🔧 Services | Service management |
| 🌐 Network | Wi-Fi & Bluetooth |
| 🛡️ Defender | Defender configuration |
| 🔄 Windows Update | Update controls |
| 🔒 Privacy | Telemetry settings |
| 🔋 Power | Power plan management |

The idea is simple:

**Keep the settings you actually use in one place.**

---

# 💻 Supported Systems

ReimaginedOS currently targets **AMD64 / x64** Windows installations.

<p>
  <img src="https://img.shields.io/badge/WINDOWS%2010-22H2-0078D6?style=for-the-badge&logo=windows11&logoColor=white" alt="Windows 10 22H2">
  <img src="https://img.shields.io/badge/WINDOWS%2011-23H2-0078D6?style=for-the-badge&logo=windows11&logoColor=white" alt="Windows 11 23H2">
  <img src="https://img.shields.io/badge/WINDOWS%2011-24H2-0078D6?style=for-the-badge&logo=windows11&logoColor=white" alt="Windows 11 24H2">
  <img src="https://img.shields.io/badge/WINDOWS%2011-24H2%20LTSC-0078D6?style=for-the-badge&logo=windows11&logoColor=white" alt="Windows 11 24H2 LTSC">
  <img src="https://img.shields.io/badge/WINDOWS%2011-25H2-0078D6?style=for-the-badge&logo=windows11&logoColor=white" alt="Windows 11 25H2">
</p>

Support for additional versions may be added as development continues.

---

# 🔄 How It Works

ReimaginedOS is built around a simple workflow:

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
   └── System Configuration
   │
   ▼
Your Windows Setup
```

### 01 — Choose

Open the playbook in AME Wizard and review the available options.

### 02 — Configure

Select only the components and tweaks you want.

### 03 — Apply

AME Wizard applies the selected configuration to Windows.

### 04 — Fine-tune

Use the ReimaginedOS ToolBox for additional configuration afterwards.

---

# 📦 Requirements

Before using ReimaginedOS you will need:

- A supported **64-bit Windows installation**
- Administrator privileges
- [AME Wizard](https://github.com/Ameliorated-LLC/trusted-uninstaller-cli/releases/tag/0.8.4)

### Recommended

A fresh, stock Windows installation.

> **⚠️ Back up important files before applying system-level modifications.**

---

# 🚧 Project Status

<p align="center">
  <img src="https://img.shields.io/badge/RELEASE-COMING%20SOON-orange?style=for-the-badge" alt="Coming Soon">
  <img src="https://img.shields.io/badge/DEVELOPMENT-ACTIVE-5865F2?style=for-the-badge" alt="Development">
</p>

ReimaginedOS is currently under development.

The playbook and ToolBox are still being tested, and features may change before the first public release.

There is currently **no public release date**.

When the project is ready, releases will be published through GitHub.

---

# 🚀 Installation

## Coming soon.

The first public release has not been published yet.

Once released:

```text
1. Download AME Wizard
          ↓
2. Download ReimaginedOS
          ↓
3. Open the playbook
          ↓
4. Review the options
          ↓
5. Select what you want
          ↓
6. Apply
```

---

# ❓ FAQ

<details>
<summary><strong>What is ReimaginedOS?</strong></summary>

ReimaginedOS is a Windows optimization playbook for AME Wizard focused on performance, privacy, debloating and gaming-oriented configuration.

</details>

<details>
<summary><strong>Is ReimaginedOS a custom Windows ISO?</strong></summary>

No.

ReimaginedOS is an **AME Wizard playbook**, not a modified Windows ISO.

</details>

<details>
<summary><strong>Do I need AME Wizard?</strong></summary>

Yes.

ReimaginedOS is designed to run through AME Wizard.

[Download AME Wizard](https://github.com/Ameliorated-LLC/trusted-uninstaller-cli/releases/tag/0.8.4)

</details>

<details>
<summary><strong>Is ReimaginedOS released?</strong></summary>

Not yet.

The project is currently in development and testing.

</details>

<details>
<summary><strong>Can I keep Windows Defender?</strong></summary>

Yes.

Defender configuration is optional. You can keep it enabled and skip Defender-related changes.

</details>

<details>
<summary><strong>Will it improve my FPS?</strong></summary>

There is no universal FPS improvement.

The goal is to reduce unnecessary background activity and provide optional gaming-oriented configuration.

Actual results depend on your hardware, drivers, games and Windows configuration.

</details>

<details>
<summary><strong>Is a fresh Windows installation recommended?</strong></summary>

Yes.

A clean Windows installation is recommended to avoid conflicts with existing modifications, software and system configuration.

</details>

<details>
<summary><strong>Is it safe?</strong></summary>

ReimaginedOS makes system-level changes, so there is always some risk.

Review every option before applying it and keep a backup of important data.

</details>

---

# 🔗 Links

<p align="center">
  <a href="https://cr1mix.github.io/reimaginedos-github.io/">
    <img src="https://img.shields.io/badge/WEBSITE-222222?style=for-the-badge&logo=github&logoColor=white" alt="Website">
  </a>
  <a href="https://discord.gg/NjkgT7vXBb">
    <img src="https://img.shields.io/badge/DISCORD-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord">
  </a>
  <a href="https://tiktok.com/@cr1mix">
    <img src="https://img.shields.io/badge/TIKTOK-000000?style=for-the-badge&logo=tiktok&logoColor=white" alt="TikTok">
  </a>
</p>

---

# 👤 About

<p align="center">
  <img src="https://avatars.githubusercontent.com/u/220206221?v=4" width="100" alt="cr1mix">
</p>

<p align="center">
  <strong>Made by cr1mix</strong>
  <br>
  Building ReimaginedOS to make Windows lighter, cleaner and more configurable.
</p>

<p align="center">
  <a href="https://github.com/cr1mix">
    <img src="https://img.shields.io/badge/GitHub-cr1mix-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub">
  </a>
</p>

---

# ⚠️ Disclaimer

ReimaginedOS modifies Windows system settings and components.

Some changes may affect:

- Windows features
- Applications
- Security settings
- System behaviour
- Windows Update

Use ReimaginedOS at your own risk.

Always keep a backup of important data before applying major system modifications.

---

<p align="center">

<img src="https://avatars.githubusercontent.com/u/220206221?v=4" width="70" alt="cr1mix">

<br><br>

<strong>ReimaginedOS</strong>

<br>

<em>Windows, reimagined.</em>

<br><br>

Made with ❤️ by <strong>cr1mix</strong>

</p>
