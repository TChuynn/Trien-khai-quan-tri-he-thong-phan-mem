# Kịch bản sao lưu CSDL MySQL trên môi trường Windows PowerShell
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$BackupDir = Join-Path $ProjectDir "backups"
$ComposeFile = Join-Path $ProjectDir "docker-compose.yml"

if (!(Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFile = Join-Path $BackupDir "backup_$Timestamp.sql"

# Đọc cấu hình từ .env nếu có
$EnvFile = Join-Path $ProjectDir ".env"
$DbUser = "diemdanh_user"
$DbName = "quan_ly_diem_danh"
$DbPass = "DiemDanhDevOps2026Secure"

if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match "^\s*MYSQL_USER\s*=\s*(.*)$") { $DbUser = $matches[1].Trim() }
        if ($_ -match "^\s*MYSQL_DATABASE\s*=\s*(.*)$") { $DbName = $matches[1].Trim() }
        if ($_ -match "^\s*MYSQL_PASSWORD\s*=\s*(.*)$") { $DbPass = $matches[1].Trim() }
    }
}

Write-Host "Dang thuc hien sao luu CSDL MySQL voi utf8mb4 tu container 'diemdanh_db'..." -ForegroundColor Cyan

# Dùng mysqldump xuất file trực tiếp trong container để bảo toàn UTF-8 nhị phân, sau đó cp về host (không dùng pipe redirect >)
docker compose -f $ComposeFile exec -T db mysqldump --default-character-set=utf8mb4 --no-tablespaces -u $DbUser -p"$DbPass" --result-file=/tmp/backup_temp.sql $DbName
docker compose -f $ComposeFile cp db:/tmp/backup_temp.sql $BackupFile
docker compose -f $ComposeFile exec -T db rm -f /tmp/backup_temp.sql

if ($LASTEXITCODE -eq 0 -and (Test-Path $BackupFile)) {
    $FileSize = (Get-Item $BackupFile).Length
    Write-Host "Sao luu thanh cong! Tep luu tai: $BackupFile ($FileSize bytes)" -ForegroundColor Green
} else {
    Write-Host "Sao luu that bai! Vui long kiem tra container db dang chay." -ForegroundColor Red
    exit 1
}
