📘 ToiUuPC — Windows Optimization Toolkit

ToiUuPC is a powerful all-in-one Windows optimization toolkit that helps users clean, tweak, manage DNS settings, install common applications, and monitor system performance — all from an easy-to-use PowerShell interface and optional graphical dashboard.

📥 Installation
Option 1 — Run Bootstrap (auto installer)

Open PowerShell as Administrator and run:

irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/bootstrap.ps1 | iex


This will download, update, and launch the toolkit.

Option 2 — Clone from GitHub
git clone https://github.com/mkhai2589/toiuupc.git
cd toiuupc
powershell -ExecutionPolicy Bypass -File bootstrap.ps1

🧭 Usage

🚀 Features
🧹 System Optimization

Clean temporary files, update cache, logs, event logs, browser cache, shader cache, Windows Defender history, and more.

Safe progress tracking with estimated freed space.

⚙️ Windows Tweaks

Apply privacy and performance tweaks (registry, services, scheduled tasks).

Backup existing settings automatically for undo.

📦 Application Installer

Batch install popular tools using Winget and Microsoft Store.

Supports presets like Office, Gaming, Privacy, etc.

🌐 DNS Management

Apply custom DNS servers (Google, Cloudflare, Quad9, AdGuard, etc.).

Auto detect, latency test, and highlight fastest DNS.

Reset back to DHCP.

📊 Real-Time Dashboard

Performance dashboard with CPU usage ring, RAM, Disk utilization, and system clean progress.

Styled like MSI Afterburner overlay.

Updates in realtime without blocking the UI.

🖼️ Demo (optional)

Add screenshots or animations here.

![Dashboard](/path/to/screenshot.png)

🛠️ Requirements

Windows 10 or Windows 11

PowerShell 5.1 or newer

Administrator privileges (required for tweaks, DNS, cleaning)
