#!/bin/sh
# Kịch bản sao lưu CSDL MySQL trên môi trường Linux/POSIX
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_DIR/backups"

mkdir -p "$BACKUP_DIR"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
BACKUP_FILE="$BACKUP_DIR/backup_${TIMESTAMP}.sql"

DB_USER="${MYSQL_USER:-diemdanh_user}"
DB_PASS="${MYSQL_PASSWORD:-DiemDanhDevOps2026Secure}"
DB_NAME="${MYSQL_DATABASE:-quan_ly_diem_danh}"

echo "Đang thực hiện sao lưu CSDL MySQL từ container diemdanh_db..."
docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db mysqldump --default-character-set=utf8mb4 --no-tablespaces -u "$DB_USER" -p"$DB_PASS" --result-file=/tmp/backup_temp.sql "$DB_NAME"
docker compose -f "$PROJECT_DIR/docker-compose.yml" cp db:/tmp/backup_temp.sql "$BACKUP_FILE"
docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db rm -f /tmp/backup_temp.sql

if [ -s "$BACKUP_FILE" ]; then
    echo "Sao lưu thành công: $BACKUP_FILE ($(wc -c < "$BACKUP_FILE") bytes)"
else
    echo "Sao lưu thất bại hoặc tệp rỗng!" >&2
    exit 1
fi
