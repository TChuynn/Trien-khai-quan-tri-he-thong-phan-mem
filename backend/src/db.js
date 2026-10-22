const mysql = require('mysql2/promise');

// Khởi tạo connection pool tới MySQL với charset utf8mb4 chuẩn
const pool = mysql.createPool({
  host: process.env.MYSQL_HOST || 'db',
  port: parseInt(process.env.MYSQL_PORT || '3306', 10),
  database: process.env.MYSQL_DATABASE || 'quan_ly_diem_danh',
  user: process.env.MYSQL_USER || 'diemdanh_user',
  password: process.env.MYSQL_PASSWORD,
  charset: 'utf8mb4',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

module.exports = {
  // Thực thi truy vấn với prepared statement và trả về cấu trúc { rows } tương thích
  query: async (sql, params = []) => {
    const [rows] = await pool.query(sql, params);
    return { rows };
  },
  pool,
};
