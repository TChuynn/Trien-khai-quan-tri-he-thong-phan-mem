#!/bin/sh
# Kịch bản phục hồi CSDL MySQL từ tệp sao lưu trên Linux/POSIX
set -e

if [ -z "$1" ]; then
    echo "Sử dụng: $0 <đường_dẫn_tệp_backup.sql>" >&2
    exit 1
fi

BACKUP_FILE="$1"
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Lỗi: Không tìm thấy tệp '$BACKUP_FILE'" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

DB_USER="${MYSQL_ROOT_USER:-root}"
DB_PASS="${MYSQL_ROOT_PASSWORD:-RootDevOps2026Secure}"
DB_NAME="${MYSQL_DATABASE:-quan_ly_diem_danh}"

echo "Đang phục hồi CSDL MySQL từ tệp: $BACKUP_FILE..."
docker compose -f "$PROJECT_DIR/docker-compose.yml" cp "$BACKUP_FILE" db:/tmp/restore.sql
docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db mysql --default-character-set=utf8mb4 -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "source /tmp/restore.sql"
docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db rm -f /tmp/restore.sql
echo "Phục hồi CSDL MySQL thành công!"
