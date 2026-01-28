# PMK Toolbox - Tối ưu Windows

Công cụ tối ưu Windows – tổng hợp từ WinUtil, Win11Debloat, Sophia Script, DTLegit, v.v.

## Cách chạy nhanh (one-liner - bundled, không lỗi path)
Mở PowerShell với quyền Administrator rồi chạy:


irm https://raw.githubusercontent.com/mkhai2589/toiuupc/main/ToiUuPC-Bundled.ps1 | iex


- Hiển thị logo + menu console cơ bản (kiểm tra Winget, info hệ thống).
- Không cần tải repo.

## Cách chạy đầy đủ (GUI WPF + tất cả tính năng)
1. Tải repo về máy: Nhấn **Code** → **Download ZIP**
2. Giải nén folder.
3. Right-click file **ToiUuPC.ps1** → **Run with PowerShell** (hoặc mở PowerShell Admin → cd vào folder → `.\ToiUuPC.ps1`)
4. GUI sẽ hiện ra với các tab: Cài ứng dụng, Tối ưu hệ thống, Quản lý DNS, Thông tin hệ thống.

**Lưu ý**: Chạy với quyền Admin để áp dụng tweaks/debloat.
