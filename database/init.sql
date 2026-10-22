SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

CREATE DATABASE IF NOT EXISTS quan_ly_diem_danh CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE quan_ly_diem_danh;

-- Khởi tạo cấu trúc bảng cho hệ thống Quản lý Ca làm và Điểm danh (MySQL utf8mb4)
CREATE TABLE IF NOT EXISTS nhan_vien (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ma_nv VARCHAR(20) NOT NULL UNIQUE,
    ho_ten VARCHAR(100) NOT NULL,
    full_name VARCHAR(100) GENERATED ALWAYS AS (ho_ten) STORED,
    phong_ban VARCHAR(50) NOT NULL,
    chuc_vu VARCHAR(50) NOT NULL,
    ngay_vao_lam DATE NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ca_lam (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ma_ca VARCHAR(20) NOT NULL UNIQUE,
    ten_ca VARCHAR(50) NOT NULL,
    gio_bat_dau TIME NOT NULL,
    gio_ket_thuc TIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS diem_danh (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nhan_vien_id INT NOT NULL,
    ca_lam_id INT NOT NULL,
    ngay DATE NOT NULL,
    check_in DATETIME NULL,
    check_out DATETIME NULL,
    trang_thai VARCHAR(30) NOT NULL,
    ghi_chu TEXT NULL,
    CONSTRAINT fk_dd_nhan_vien FOREIGN KEY (nhan_vien_id) REFERENCES nhan_vien(id) ON DELETE CASCADE,
    CONSTRAINT fk_dd_ca_lam FOREIGN KEY (ca_lam_id) REFERENCES ca_lam(id) ON DELETE RESTRICT,
    CONSTRAINT uq_nv_ca_ngay UNIQUE (nhan_vien_id, ca_lam_id, ngay)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Chỉ mục tối ưu truy vấn tra cứu lịch sử theo ngày và nhân viên
CREATE INDEX idx_diem_danh_ngay ON diem_danh(ngay);
CREATE INDEX idx_diem_danh_nhan_vien ON diem_danh(nhan_vien_id);

-- View hỗ trợ kiểm tra linh hoạt
CREATE OR REPLACE VIEW users AS 
SELECT id, ma_nv, ho_ten, ho_ten AS full_name, phong_ban, chuc_vu, ngay_vao_lam FROM nhan_vien;

CREATE OR REPLACE VIEW employees AS 
SELECT id, ma_nv, ho_ten, ho_ten AS full_name, phong_ban, chuc_vu, ngay_vao_lam FROM nhan_vien;

-- Dữ liệu mẫu ban đầu: Nhân sự thực tế
INSERT INTO nhan_vien (ma_nv, ho_ten, phong_ban, chuc_vu, ngay_vao_lam) VALUES
('NV001', 'Nguyễn Văn An', 'Kỹ thuật', 'Kỹ sư DevOps', '2023-01-15'),
('NV002', 'Trần Thị Mai', 'Kế toán', 'Kế toán trưởng', '2022-05-20'),
('NV003', 'Lê Hoàng Long', 'Kỹ thuật', 'Lập trình viên Backend', '2023-03-10'),
('NV004', 'Phạm Minh Tuấn', 'Vận hành', 'Trưởng ca Vận hành', '2021-11-01'),
('NV005', 'Hoàng Thu Trang', 'Nhân sự', 'Chuyên viên Tuyển dụng', '2023-08-15'),
('NV006', 'Vũ Đức Thịnh', 'Vận hành', 'Nhân viên Giám sát', '2024-02-01'),
('NV007', 'Đỗ Bích Ngọc', 'Kế toán', 'Thủ quỹ', '2023-06-01'),
('NV008', 'Bùi Quốc Huy', 'Kỹ thuật', 'Quản trị Hệ thống', '2022-09-15')
ON DUPLICATE KEY UPDATE id=id;

-- Dữ liệu mẫu ban đầu: Ca làm việc
INSERT INTO ca_lam (ma_ca, ten_ca, gio_bat_dau, gio_ket_thuc) VALUES
('CA_SANG', 'Ca Sáng', '08:00:00', '12:00:00'),
('CA_CHIEU', 'Ca Chiều', '13:30:00', '17:30:00'),
('CA_TOI', 'Ca Tối', '18:00:00', '22:00:00')
ON DUPLICATE KEY UPDATE id=id;

-- Dữ liệu mẫu điểm danh 3 ngày trước đến hôm nay
-- 3 ngày trước
INSERT INTO diem_danh (nhan_vien_id, ca_lam_id, ngay, check_in, check_out, trang_thai, ghi_chu) VALUES
(1, 1, DATE_SUB(CURDATE(), INTERVAL 3 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 07:55:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 12:05:00'), 'DungGio', 'Đi làm đúng giờ'),
(2, 1, DATE_SUB(CURDATE(), INTERVAL 3 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 08:15:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 12:00:00'), 'DiMuon', 'Đường kẹt xe'),
(3, 1, DATE_SUB(CURDATE(), INTERVAL 3 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 07:50:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 11:40:00'), 'VeSom', 'Có việc gia đình'),
(4, 2, DATE_SUB(CURDATE(), INTERVAL 3 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 13:25:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 17:35:00'), 'DungGio', 'Đúng ca chiều'),
(5, 2, DATE_SUB(CURDATE(), INTERVAL 3 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 13:30:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 17:30:00'), 'DungGio', 'Đi làm đầy đủ'),
(6, 3, DATE_SUB(CURDATE(), INTERVAL 3 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 17:55:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 3 DAY), ' 22:05:00'), 'DungGio', 'Ca trực tối ổn định')
ON DUPLICATE KEY UPDATE id=id;

-- 2 ngày trước
INSERT INTO diem_danh (nhan_vien_id, ca_lam_id, ngay, check_in, check_out, trang_thai, ghi_chu) VALUES
(1, 1, DATE_SUB(CURDATE(), INTERVAL 2 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 07:58:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 12:02:00'), 'DungGio', 'Đúng giờ ca sáng'),
(2, 1, DATE_SUB(CURDATE(), INTERVAL 2 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 07:52:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 12:00:00'), 'DungGio', 'Đi làm đúng giờ'),
(3, 1, DATE_SUB(CURDATE(), INTERVAL 2 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 08:20:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 12:05:00'), 'DiMuon', 'Hỏng xe giữa đường'),
(4, 2, DATE_SUB(CURDATE(), INTERVAL 2 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 13:28:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 17:32:00'), 'DungGio', 'Đúng ca chiều'),
(7, 2, DATE_SUB(CURDATE(), INTERVAL 2 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 13:30:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 17:00:00'), 'VeSom', 'Xin về sớm khám sức khỏe'),
(8, 3, DATE_SUB(CURDATE(), INTERVAL 2 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 18:05:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 2 DAY), ' 22:00:00'), 'DiMuon', 'Muộn ca trực tối 5 phút')
ON DUPLICATE KEY UPDATE id=id;

-- Hôm qua
INSERT INTO diem_danh (nhan_vien_id, ca_lam_id, ngay, check_in, check_out, trang_thai, ghi_chu) VALUES
(1, 1, DATE_SUB(CURDATE(), INTERVAL 1 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 07:50:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 12:00:00'), 'DungGio', 'Trực ca sáng'),
(2, 1, DATE_SUB(CURDATE(), INTERVAL 1 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 07:55:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 12:01:00'), 'DungGio', 'Đúng giờ'),
(5, 1, DATE_SUB(CURDATE(), INTERVAL 1 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 08:00:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 12:00:00'), 'DungGio', 'Đúng giờ'),
(4, 2, DATE_SUB(CURDATE(), INTERVAL 1 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 13:20:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 17:30:00'), 'DungGio', 'Đúng ca chiều'),
(6, 2, DATE_SUB(CURDATE(), INTERVAL 1 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 13:45:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 17:30:00'), 'DiMuon', 'Gặp đối tác đầu giờ'),
(8, 3, DATE_SUB(CURDATE(), INTERVAL 1 DAY), CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 17:58:00'), CONCAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), ' 22:02:00'), 'DungGio', 'Trực hệ thống ca tối')
ON DUPLICATE KEY UPDATE id=id;

-- Hôm nay
INSERT INTO diem_danh (nhan_vien_id, ca_lam_id, ngay, check_in, check_out, trang_thai, ghi_chu) VALUES
(1, 1, CURDATE(), CONCAT(CURDATE(), ' 07:56:00'), CONCAT(CURDATE(), ' 12:02:00'), 'DungGio', 'Đã hoàn thành ca sáng'),
(2, 1, CURDATE(), CONCAT(CURDATE(), ' 07:50:00'), CONCAT(CURDATE(), ' 12:00:00'), 'DungGio', 'Đã hoàn thành ca sáng'),
(3, 1, CURDATE(), CONCAT(CURDATE(), ' 08:12:00'), CONCAT(CURDATE(), ' 12:05:00'), 'DiMuon', 'Muộn 12 phút'),
(5, 1, CURDATE(), CONCAT(CURDATE(), ' 07:58:00'), CONCAT(CURDATE(), ' 11:45:00'), 'VeSom', 'Xin về sớm 15 phút'),
(4, 2, CURDATE(), CONCAT(CURDATE(), ' 13:25:00'), NULL, 'DungGio', 'Đang trong ca chiều'),
(7, 2, CURDATE(), CONCAT(CURDATE(), ' 13:28:00'), NULL, 'DungGio', 'Đang trong ca chiều')
ON DUPLICATE KEY UPDATE id=id;
