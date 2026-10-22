// Quản lý logic tương tác giao diện và gọi API

document.addEventListener('DOMContentLoaded', () => {
  const clockEl = document.getElementById('clock');
  const connStatusEl = document.getElementById('conn-status');
  const selectNv = document.getElementById('select-nhan-vien');
  const selectCa = document.getElementById('select-ca-lam');
  const inputGhiChu = document.getElementById('input-ghi-chu');
  const formMessage = document.getElementById('form-message');
  const filterDateInput = document.getElementById('filter-date');
  const tableBody = document.getElementById('table-body');

  const statTongNv = document.getElementById('stat-tong-nv');
  const statDaDiemDanh = document.getElementById('stat-da-diem-danh');
  const statDungGio = document.getElementById('stat-dung-gio');
  const statDiMuon = document.getElementById('stat-di-muon');
  const statTyLe = document.getElementById('stat-ty-le');

  // Khởi tạo ngày mặc định là hôm nay theo giờ địa phương YYYY-MM-DD
  const today = new Date();
  const todayStr = today.toISOString().split('T')[0];
  filterDateInput.value = todayStr;

  // Cập nhật đồng hồ thời gian thực
  function updateClock() {
    const now = new Date();
    clockEl.textContent = now.toLocaleTimeString('vi-VN', { hour12: false });
  }
  updateClock();
  setInterval(updateClock, 1000);

  // Hiển thị thông báo trên giao diện
  function showMessage(msg, isSuccess = true) {
    formMessage.textContent = msg;
    formMessage.className = isSuccess ? 'alert alert-success' : 'alert alert-error';
    setTimeout(() => {
      formMessage.className = 'alert d-none';
    }, 5000);
  }

  // Kiểm tra tình trạng kết nối tới API
  async function checkHealth() {
    try {
      const res = await fetch('/api/health');
      if (res.ok) {
        connStatusEl.textContent = 'Trực tuyến';
        connStatusEl.className = 'status-badge status-online';
      } else {
        throw new Error('API báo lỗi');
      }
    } catch {
      connStatusEl.textContent = 'Ngoại tuyến';
      connStatusEl.className = 'status-badge status-offline';
    }
  }

  // Tải danh sách nhân viên vào dropdown
  async function loadNhanVien() {
    try {
      const res = await fetch('/api/nhan-vien');
      const json = await res.json();
      if (json.success) {
        selectNv.innerHTML = '<option value="">-- Chọn nhân viên --</option>';
        json.data.forEach(nv => {
          const opt = document.createElement('option');
          opt.value = nv.id;
          opt.textContent = `${nv.ma_nv} - ${nv.ho_ten} (${nv.phong_ban})`;
          selectNv.appendChild(opt);
        });
      }
    } catch (err) {
      console.error('Không thể tải danh sách nhân viên:', err);
    }
  }

  // Tải danh sách ca làm việc vào dropdown
  async function loadCaLam() {
    try {
      const res = await fetch('/api/ca-lam');
      const json = await res.json();
      if (json.success) {
        selectCa.innerHTML = '<option value="">-- Chọn ca làm việc --</option>';
        json.data.forEach(ca => {
          const opt = document.createElement('option');
          opt.value = ca.id;
          opt.textContent = `${ca.ten_ca} (${ca.gio_bat_dau} - ${ca.gio_ket_thuc})`;
          selectCa.appendChild(opt);
        });
      }
    } catch (err) {
      console.error('Không thể tải danh sách ca làm:', err);
    }
  }

  // Tải số liệu thống kê bảng điều khiển
  async function loadDashboard() {
    try {
      const res = await fetch('/api/dashboard');
      const json = await res.json();
      if (json.success) {
        const d = json.data;
        statTongNv.textContent = d.tong_nhan_vien;
        statDaDiemDanh.textContent = d.da_diem_danh;
        statDungGio.textContent = d.dung_gio;
        statDiMuon.textContent = d.di_muon;
        statTyLe.textContent = `${d.ty_le_dung_gio}%`;
      }
    } catch (err) {
      console.error('Không thể tải số liệu thống kê:', err);
    }
  }

  // Định dạng nhãn trạng thái
  function renderBadge(trangThai) {
    if (trangThai === 'DungGio') {
      return '<span class="badge-status badge-dung-gio">Đúng giờ</span>';
    }
    if (trangThai === 'DiMuon') {
      return '<span class="badge-status badge-di-muon">Đi muộn</span>';
    }
    if (trangThai === 'VeSom') {
      return '<span class="badge-status badge-ve-som">Về sớm</span>';
    }
    return `<span class="badge-status">${trangThai}</span>`;
  }

  // Tải danh sách lịch sử điểm danh
  async function loadDiemDanh(dateFilter = '') {
    tableBody.innerHTML = '<tr><td colspan="9" class="text-center">Đang nạp dữ liệu...</td></tr>';
    try {
      let url = '/api/diem-danh';
      if (dateFilter) {
        url += `?ngay=${dateFilter}`;
      }
      const res = await fetch(url);
      const json = await res.json();

      if (!json.success || json.data.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="9" class="text-center">Chưa có bản ghi điểm danh nào phù hợp.</td></tr>';
        return;
      }

      tableBody.innerHTML = '';
      json.data.forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `
          <td><strong>${item.ma_nv}</strong></td>
          <td>${item.ho_ten}</td>
          <td>${item.phong_ban}</td>
          <td>${item.ten_ca}</td>
          <td>${item.ngay_hien_thi}</td>
          <td>${item.check_in || '-'}</td>
          <td>${item.check_out || '-'}</td>
          <td>${renderBadge(item.trang_thai)}</td>
          <td>${item.ghi_chu || ''}</td>
        `;
        tableBody.appendChild(row);
      });
    } catch (err) {
      tableBody.innerHTML = '<tr><td colspan="9" class="text-center text-danger">Lỗi khi tải lịch sử điểm danh.</td></tr>';
    }
  }

  // Thực hiện gửi yêu cầu điểm danh
  async function handleAttendance(loai) {
    const nvId = selectNv.value;
    const caId = selectCa.value;
    const ghiChu = inputGhiChu.value.trim();

    if (!nvId) {
      showMessage('Vui lòng chọn nhân viên!', false);
      return;
    }
    if (!caId) {
      showMessage('Vui lòng chọn ca làm việc!', false);
      return;
    }

    try {
      const res = await fetch('/api/diem-danh', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          nhan_vien_id: parseInt(nvId, 10),
          ca_lam_id: parseInt(caId, 10),
          loai,
          ghi_chu,
        }),
      });
      const data = await res.json();

      if (res.ok && data.success) {
        showMessage(data.message, true);
        inputGhiChu.value = '';
        // Làm mới dữ liệu bảng và thống kê ngay lập tức
        loadDashboard();
        loadDiemDanh(filterDateInput.value);
      } else {
        showMessage(data.message || 'Thao tác không thành công', false);
      }
    } catch (err) {
      showMessage('Lỗi kết nối máy chủ: ' + err.message, false);
    }
  }

  // Đăng ký sự kiện nút bấm
  document.getElementById('btn-checkin').addEventListener('click', () => handleAttendance('CHECK_IN'));
  document.getElementById('btn-checkout').addEventListener('click', () => handleAttendance('CHECK_OUT'));

  document.getElementById('btn-filter').addEventListener('click', () => {
    loadDiemDanh(filterDateInput.value);
  });

  document.getElementById('btn-filter-all').addEventListener('click', () => {
    filterDateInput.value = '';
    loadDiemDanh('');
  });

  // Tải dữ liệu ban đầu
  checkHealth();
  loadNhanVien();
  loadCaLam();
  loadDashboard();
  loadDiemDanh(todayStr);

  // Chu kỳ làm mới trạng thái kết nối mỗi 30 giây
  setInterval(checkHealth, 30000);
});
