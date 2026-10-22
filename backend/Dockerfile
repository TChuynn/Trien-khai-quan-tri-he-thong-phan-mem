# Sử dụng Node.js 20 trên nền Alpine Linux để kích thước image nhẹ và bảo mật tối đa
FROM node:20-alpine

WORKDIR /app

# Sao chép file định nghĩa phụ thuộc trước để tận dụng Docker layer cache
COPY package.json ./

# Cài đặt các gói phụ thuộc chỉ dùng cho production
RUN npm install --omit=dev && npm cache clean --force

# Sao chép mã nguồn ứng dụng
COPY src ./src

# Đổi quyền sở hữu cho người dùng không đặc quyền 'node' có sẵn trong image để tăng cường an toàn
USER node

EXPOSE 3000

# Kiểm tra sức khỏe container bằng lệnh Node.js nội bộ, không cần cài thêm curl
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"

CMD ["node", "src/server.js"]
