# HỆ THỐNG QUẢN LÝ CA LÀM VÀ ĐIỂM DANH

Hệ thống phục vụ bài tập môn Triển khai và Quản trị Hệ thống Phần mềm.
Mô hình triển khai 3 tầng gồm Reverse Proxy (Nginx), Backend API (Node.js/Express) và Cơ sở dữ liệu quan hệ (MySQL 8.0 utf8mb4) thông qua Docker Compose.

---

## 1. Yêu cầu Hệ thống
- Hệ điều hành: Windows 10/11, Linux hoặc macOS.
- Công cụ bắt buộc:
  - Docker Engine (phiên bản 24.0 trở lên).
  - Docker Compose (v2.0 trở lên).
- Trình duyệt web hiện đại (Chrome, Edge, Firefox).

---

## 2. Cấu trúc Thư mục

```text
.
├── .env.example              # File mẫu cấu hình biến môi trường
├── .env                      # File biến môi trường thực tế (không commit git)
├── .gitignore                # Loại trừ file bí mật và file tạm khỏi git
├── docker-compose.yml        # Định nghĩa và phối hợp các container (MySQL, Backend, Proxy)
├── backend/
│   ├── Dockerfile            # Khởi tạo container Node.js 20-alpine
│   ├── package.json          # Thư viện phụ thuộc (express 4.22.3, mysql2 3.11.0)
│   └── src/
│       ├── db.js             # Kết nối MySQL pool với charset utf8mb4
│       └── server.js         # REST API điểm danh, healthcheck, thống kê
├── database/
│   └── init.sql              # Cấu trúc bảng và seed data tiếng Việt (UTF-8 không BOM, SET NAMES utf8mb4)
├── frontend/
│   ├── index.html            # Giao diện HTML5 ngữ nghĩa
│   ├── style.css             # CSS thuần, phong cách kỹ thuật thực dụng
│   └── app.js                # Xử lý giao diện, gọi API và đồng hồ
├── nginx/
│   ├── Dockerfile            # Khởi tạo container Nginx 1.27-alpine
│   └── nginx.conf            # Cấu hình Reverse Proxy và bảo mật
└── scripts/
    ├── backup.ps1            # Kịch bản sao lưu CSDL MySQL cho Windows PowerShell
    ├── backup.sh             # Kịch bản sao lưu CSDL MySQL cho Linux/sh
    ├── restore.ps1           # Kịch bản phục hồi CSDL MySQL (không dùng pipe) cho Windows PowerShell
    └── restore.sh            # Kịch bản phục hồi CSDL MySQL cho Linux/sh
```

---

## 3. Hướng dẫn Triển khai và Khởi chạy

### Bước 1: Chuẩn bị tệp cấu hình môi trường
Nếu chưa có tệp `.env`, sao chép từ tệp mẫu:
```powershell
Copy-Item .env.example .env
```
Nội dung file `.env` xác định cổng dịch vụ và mật khẩu CSDL:
```env
APP_PORT=8080
MYSQL_DATABASE=quan_ly_diem_danh
MYSQL_USER=diemdanh_user
MYSQL_PASSWORD=DiemDanhDevOps2026Secure
MYSQL_ROOT_PASSWORD=RootDevOps2026Secure
```

### Bước 2: Khởi động hệ thống
Thực hiện build và khởi động toàn bộ cụm dịch vụ ở chế độ chạy ngầm:
```bash
docker compose up -d --build
```

### Bước 3: Kiểm tra trạng thái các dịch vụ
```bash
docker compose ps
```
Khi toàn bộ các dịch vụ đạt trạng thái `healthy`, truy cập ứng dụng:
- **Giao diện người dùng:** `http://localhost:8080`
- **Kiểm tra API Healthcheck:** `http://localhost:8080/api/health`
- **Tra cứu lịch sử điểm danh:** `http://localhost:8080/api/diem-danh` (hoặc `/api/history`)

---

## 4. Xử lý chuẩn Tiếng Việt UTF-8 (utf8mb4) trong MySQL

Để ngăn ngừa triệt để lỗi ký tự tiếng Việt có dấu bị biến dạng thành dấu `?` (0x3F):
1. **Tham số máy chủ MySQL:** Khởi chạy với `--character-set-server=utf8mb4` và `--collation-server=utf8mb4_unicode_ci`.
2. **Schema & Dữ liệu khởi tạo:** Khởi tạo database và toàn bộ bảng với `CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci`. Dòng đầu tệp `database/init.sql` khai báo `SET NAMES utf8mb4;`. Tệp lưu chuẩn **UTF-8 không BOM**.
3. **Kết nối ứng dụng:** Thư viện `mysql2` kết nối với `charset: 'utf8mb4'`.
4. **Sao lưu & Phục hồi an toàn:** Kịch bản `restore.ps1` và `backup.ps1` sử dụng `docker compose cp` và `--result-file` nhị phân, tuyệt đối **không sử dụng PowerShell pipe (`|`)** để tránh lỗi chuyển đổi mã hóa của shell Windows.

---

## 5. Sao lưu và Phục hồi Dữ liệu

### Sao lưu (Backup)
- **Windows PowerShell:**
  ```powershell
  .\scripts\backup.ps1
  ```
- **Linux/POSIX:**
  ```bash
  ./scripts/backup.sh
  ```

### Phục hồi (Restore)
- **Windows PowerShell:**
  ```powershell
  .\scripts\restore.ps1 -BackupFilePath .\backups\<ten_tep_sao_luu>.sql
  ```
- **Linux/POSIX:**
  ```bash
  ./scripts/restore.sh ./backups/<ten_tep_sao_luu>.sql
  ```
