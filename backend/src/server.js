const express = require('express');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Endpoint kiểm tra sức khỏe hệ thống phục vụ Docker Healthcheck
app.get('/api/health', async (req, res) => {
  try {
    await db.query('SELECT 1');
    res.status(200).json({
      status: 'ok',
      service: 'diem-danh-backend',
      db: 'connected',
      uptime: Math.floor(process.uptime()),
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(503).json({
      status: 'error',
      service: 'diem-danh-backend',
      db: 'disconnected',
      error: error.message,
    });
  }
});

// Lấy danh sách nhân viên
app.get('/api/nhan-vien', async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT id, ma_nv, ho_ten, ho_ten AS full_name, phong_ban, chuc_vu, 
              DATE_FORMAT(ngay_vao_lam, '%d/%m/%Y') AS ngay_vao_lam 
       FROM nhan_vien 
       ORDER BY ma_nv ASC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// Lấy danh sách ca làm việc
app.get('/api/ca-lam', async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT id, ma_ca, ten_ca, 
              DATE_FORMAT(gio_bat_dau, '%H:%i') AS gio_bat_dau, 
              DATE_FORMAT(gio_ket_thuc, '%H:%i') AS gio_ket_thuc 
       FROM ca_lam 
       ORDER BY gio_bat_dau ASC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// Thống kê bảng điều khiển cho ngày hiện tại
app.get('/api/dashboard', async (req, res, next) => {
  try {
    const nvRes = await db.query('SELECT COUNT(*) AS tong_nv FROM nhan_vien');
    const tongNv = Number(nvRes.rows[0].tong_nv);

    const statsRes = await db.query(
      `SELECT 
         COUNT(*) AS da_diem_danh,
         COUNT(CASE WHEN trang_thai = 'DungGio' THEN 1 END) AS dung_gio,
         COUNT(CASE WHEN trang_thai = 'DiMuon' THEN 1 END) AS di_muon,
         COUNT(CASE WHEN trang_thai = 'VeSom' THEN 1 END) AS ve_som
       FROM diem_danh 
       WHERE ngay = CURDATE()`
    );
    const stats = statsRes.rows[0];
    const daDiemDanh = Number(stats.da_diem_danh);
    const dungGio = Number(stats.dung_gio);
    const diMuon = Number(stats.di_muon);
    const veSom = Number(stats.ve_som);
    const tyLeDungGio = daDiemDanh > 0 ? Math.round((dungGio / daDiemDanh) * 100) : 0;

    res.json({
      success: true,
      data: {
        tong_nhan_vien: tongNv,
        da_diem_danh: daDiemDanh,
        dung_gio: dungGio,
        di_muon: diMuon,
        ve_som: veSom,
        ty_le_dung_gio: tyLeDungGio,
      },
    });
  } catch (err) {
    next(err);
  }
});

// Handler tra cứu danh sách lịch sử điểm danh
const handleGetHistory = async (req, res, next) => {
  try {
    const { ngay, nhan_vien_id } = req.query;
    let queryText = `
      SELECT dd.id, dd.ngay,
             DATE_FORMAT(dd.ngay, '%d/%m/%Y') AS ngay_hien_thi,
             DATE_FORMAT(dd.check_in, '%H:%i:%s') AS check_in,
             DATE_FORMAT(dd.check_out, '%H:%i:%s') AS check_out,
             dd.trang_thai, dd.ghi_chu,
             nv.id AS nhan_vien_id, nv.ma_nv, nv.ho_ten, nv.ho_ten AS full_name, nv.phong_ban,
             cl.id AS ca_lam_id, cl.ten_ca,
             DATE_FORMAT(cl.gio_bat_dau, '%H:%i') AS gio_bat_dau,
             DATE_FORMAT(cl.gio_ket_thuc, '%H:%i') AS gio_ket_thuc
      FROM diem_danh dd
      JOIN nhan_vien nv ON dd.nhan_vien_id = nv.id
      JOIN ca_lam cl ON dd.ca_lam_id = cl.id
      WHERE 1=1
    `;
    const params = [];

    if (ngay) {
      params.push(ngay);
      queryText += ' AND dd.ngay = ?';
    }

    if (nhan_vien_id) {
      params.push(parseInt(nhan_vien_id, 10));
      queryText += ' AND dd.nhan_vien_id = ?';
    }

    queryText += ' ORDER BY dd.ngay DESC, dd.check_in DESC LIMIT 100';

    const result = await db.query(queryText, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
};

// Cung cấp cả endpoint chuẩn /api/diem-danh và alias /api/history
app.get('/api/diem-danh', handleGetHistory);
app.get('/api/history', handleGetHistory);

// Thực hiện điểm danh (Check-in hoặc Check-out)
app.post('/api/diem-danh', async (req, res, next) => {
  try {
    const { nhan_vien_id, ca_lam_id, loai, ghi_chu } = req.body;

    if (!nhan_vien_id || !ca_lam_id || !loai) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin bắt buộc: nhan_vien_id, ca_lam_id, loai',
      });
    }

    // Lấy thông tin ca làm để đối chiếu giờ quy định
    const caRes = await db.query(
      `SELECT id, ten_ca, 
              DATE_FORMAT(gio_bat_dau, '%H:%i') AS gio_bat_dau, 
              DATE_FORMAT(gio_ket_thuc, '%H:%i') AS gio_ket_thuc 
       FROM ca_lam WHERE id = ?`,
      [ca_lam_id]
    );
    if (caRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy ca làm việc' });
    }
    const ca = caRes.rows[0];

    // Kiểm tra bản ghi điểm danh hôm nay
    const checkRes = await db.query(
      'SELECT id, check_in, check_out, trang_thai FROM diem_danh WHERE nhan_vien_id = ? AND ca_lam_id = ? AND ngay = CURDATE()',
      [nhan_vien_id, ca_lam_id]
    );

    const now = new Date();
    const currentTimeStr = now.toTimeString().split(' ')[0]; // HH:MM:SS

    if (loai === 'CHECK_IN') {
      if (checkRes.rows.length > 0 && checkRes.rows[0].check_in) {
        return res.status(400).json({
          success: false,
          message: 'Nhân viên đã thực hiện Check-in ca này hôm nay rồi',
        });
      }

      // Xác định trạng thái đi muộn: cho phép trễ tối đa 10 phút so với giờ bắt đầu ca
      const [startH, startM] = ca.gio_bat_dau.split(':').map(Number);
      const [curH, curM] = currentTimeStr.split(':').map(Number);
      const startMinutes = startH * 60 + startM;
      const curMinutes = curH * 60 + curM;

      const trangThai = curMinutes > startMinutes + 10 ? 'DiMuon' : 'DungGio';

      if (checkRes.rows.length > 0) {
        // Cập nhật nếu đã có bản ghi
        await db.query(
          `UPDATE diem_danh 
           SET check_in = NOW(), trang_thai = ?, ghi_chu = COALESCE(?, ghi_chu)
           WHERE id = ?`,
          [trangThai, ghi_chu || null, checkRes.rows[0].id]
        );
      } else {
        // Tạo mới bản ghi điểm danh
        await db.query(
          `INSERT INTO diem_danh (nhan_vien_id, ca_lam_id, ngay, check_in, trang_thai, ghi_chu)
           VALUES (?, ?, CURDATE(), NOW(), ?, ?)`,
          [nhan_vien_id, ca_lam_id, trangThai, ghi_chu || (trangThai === 'DiMuon' ? 'Đi muộn' : 'Đúng giờ')]
        );
      }

      return res.json({
        success: true,
        message: `Check-in thành công. Trạng thái: ${trangThai === 'DungGio' ? 'Đúng giờ' : 'Đi muộn'}`,
      });
    }

    if (loai === 'CHECK_OUT') {
      if (checkRes.rows.length === 0 || !checkRes.rows[0].check_in) {
        return res.status(400).json({
          success: false,
          message: 'Chưa có bản ghi Check-in. Vui lòng Check-in trước khi Check-out',
        });
      }

      const existingRecord = checkRes.rows[0];
      const [endH, endM] = ca.gio_ket_thuc.split(':').map(Number);
      const [curH, curM] = currentTimeStr.split(':').map(Number);
      const endMinutes = endH * 60 + endM;
      const curMinutes = curH * 60 + curM;

      let trangThai = existingRecord.trang_thai;
      // Nếu về trước giờ kết thúc hơn 10 phút và trước đó đúng giờ thì cập nhật thành Về sớm
      if (curMinutes < endMinutes - 10 && trangThai === 'DungGio') {
        trangThai = 'VeSom';
      }

      await db.query(
        `UPDATE diem_danh 
         SET check_out = NOW(), trang_thai = ?, ghi_chu = COALESCE(?, ghi_chu)
         WHERE id = ?`,
        [trangThai, ghi_chu || null, existingRecord.id]
      );

      return res.json({
        success: true,
        message: `Check-out thành công. Trạng thái: ${trangThai}`,
      });
    }

    return res.status(400).json({ success: false, message: 'Loại điểm danh không hợp lệ' });
  } catch (err) {
    next(err);
  }
});

// Middleware xử lý lỗi tập trung
app.use((err, req, res, next) => {
  console.error('Lỗi xử lý request:', err.message);
  res.status(500).json({
    success: false,
    message: 'Lỗi máy chủ nội bộ: ' + err.message,
  });
});

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend API đang lắng nghe trên cổng ${PORT}`);
});

// Đóng kết nối an toàn khi nhận tín hiệu kết thúc từ Docker (Graceful Shutdown)
process.on('SIGTERM', () => {
  console.log('Nhận tín hiệu SIGTERM, đang tắt máy chủ an toàn...');
  server.close(async () => {
    try {
      await db.pool.end();
      console.log('Đã đóng kết nối CSDL MySQL.');
    } catch (e) {
      console.error('Lỗi khi đóng pool MySQL:', e.message);
    }
    process.exit(0);
  });
});
