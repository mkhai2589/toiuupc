# 🛠️ ToiUuPC – Bộ công cụ tối ưu Windows 10 / 11

**ToiUuPC** là bộ công cụ tối ưu **Windows 10 / 11** được viết hoàn toàn bằng **PowerShell**, tập trung vào các tinh chỉnh **thực sự hiệu quả**, **có thể hoàn tác**, và **minh bạch**.

Công cụ hướng tới người dùng muốn:

- Windows gọn nhẹ hơn
- Bảo mật & quyền riêng tư tốt hơn
- Hiệu năng ổn định, không tweak bừa

---

## ▶️ Cách sử dụng

### Phiên bản nhẹ

```powershell
irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex



## 🎯 Mục tiêu
- ⚙️ Tối ưu hệ thống dựa trên tài liệu chuẩn
- 🔄 Mọi tweak đều có thể rollback
- ❌ Không tweak placebo
- ❌ Không phần mềm rác
- ❌ Không crack / can thiệp bản quyền

---

## 📦 Tính năng chính

### ⚙️ Tối ưu hệ thống (System Tweaks)
Nguồn tham khảo:
- Microsoft Docs
- Sophia Script
- Chris Titus WinUtil

Có phân loại rõ ràng:
- **Privacy** – Quyền riêng tư
- **Performance** – Hiệu năng
- **UI / UX** – Giao diện & trải nghiệm

Có preset sẵn:
- 🔒 **Privacy** – Giảm telemetry, tăng quyền riêng tư
- 🎮 **Gaming** – Ưu tiên hiệu năng / FPS
- 🏢 **Office** – Ổn định, bảo mật, phù hợp máy làm việc

Tính năng an toàn:
- ⚠️ Đánh dấu tweak nguy hiểm (Dangerous)
- 🔄 Tự động tạo **System Restore Point** trước khi áp dụng

---

### 📦 Cài đặt ứng dụng bằng Winget
- Cài các ứng dụng phổ biến:
  - Chrome, Firefox, VS Code, 7-Zip, Steam, Spotify, …
- Tự động phát hiện app đã cài → **bỏ qua**
- Có log quá trình cài đặt
- Rollback bằng `winget uninstall`

---

### 🌐 Thiết lập DNS
- Google DNS
- Cloudflare DNS
- Chuyển đổi nhanh, có thể khôi phục DNS mặc định

---

### 🧹 Dọn dẹp hệ thống
- Thư mục Temp (User & System)
- Cache Windows Update
- Recycle Bin
- An toàn, không xoá file hệ thống quan trọng

---

## ⚠️ Yêu cầu
- **Bắt buộc chạy PowerShell với quyền Administrator**
- Windows 10 / 11
- Có Internet (để dùng Winget)

---

🛠️ ToiUuPC – Windows 10 / 11 Optimization Toolkit

ToiUuPC is an open-source PowerShell-based toolkit designed to optimize Windows 10 / 11 with a focus on real performance gains, reversible tweaks, and full transparency.

This project is built for users who want:

A cleaner and lighter Windows

Better privacy and security

Stable performance without placebo tweaks

▶️ Usage
Lightweight version
irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC.ps1 | iex

Bundled version
irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC-Bundled.ps1 | iex


🎯 Goals

⚙️ Apply optimizations based on trusted sources

🔄 All tweaks are reversible

❌ No placebo tweaks

❌ No bloatware

❌ No cracks or piracy

📦 Key Features
⚙️ System Tweaks

Sources:

Microsoft Docs

Sophia Script

Chris Titus WinUtil

Well-categorized tweaks:

Privacy

Performance

UI / UX

Built-in presets:

🔒 Privacy – Reduce telemetry & tracking

🎮 Gaming – Performance / FPS focused

🏢 Office – Stability & security for work machines

Safety features:

⚠️ Dangerous tweaks are clearly labeled

🔄 Automatic System Restore Point creation

📦 Application Installation (Winget)

Install popular applications:

Chrome, Firefox, VS Code, 7-Zip, Steam, Spotify, …

Detect installed apps → skip

Installation logs included

Rollback supported via winget uninstall

🌐 DNS Configuration

Google DNS

Cloudflare DNS

Easy switching and restore to default

🧹 System Cleanup

User & system temp files

Windows Update cache

Recycle Bin

Safe cleanup only

⚠️ Requirements

PowerShell must be run as Administrator

Windows 10 / 11

Internet connection (for Winget)

🧑‍💻 Author

Pham Minh Khai (PMK)
Facebook: https://www.facebook.com/khaiitcntt
```
