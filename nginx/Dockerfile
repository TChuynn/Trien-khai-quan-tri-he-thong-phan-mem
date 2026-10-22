# Sử dụng image Nginx 1.27 trên nền Alpine tối ưu dung lượng và bảo mật
FROM nginx:1.27-alpine

# Xóa trang mặc định của Nginx
RUN rm -rf /usr/share/nginx/html/*

# Sao chép cấu hình Reverse Proxy tùy chỉnh (từ ngữ cảnh thư mục gốc dự án)
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Sao chép mã nguồn giao diện người dùng
COPY frontend /usr/share/nginx/html

EXPOSE 80

# Kiểm tra sức khỏe proxy và khả năng chuyển tiếp tới backend thông qua wget có sẵn trong Alpine
HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -q --spider http://127.0.0.1:80/api/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
