# Kịch bản phục hồi CSDL MySQL từ tệp sao lưu trên Windows PowerShell (KHÔNG DÙNG PIPE)
param (
    [Parameter(Mandatory=$true)]
    [string]$BackupFilePath
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $BackupFilePath)) {
    Write-Host "Loi: Khong tim thay tep sao luu tai '$BackupFilePath'" -ForegroundColor Red
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$ComposeFile = Join-Path $ProjectDir "docker-compose.yml"

# Đọc cấu hình từ .env nếu có
$EnvFile = Join-Path $ProjectDir ".env"
$DbUser = "root"
$DbName = "quan_ly_diem_danh"
$DbPass = "RootDevOps2026Secure"

if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match "^\s*MYSQL_DATABASE\s*=\s*(.*)$") { $DbName = $matches[1].Trim() }
        if ($_ -match "^\s*MYSQL_ROOT_PASSWORD\s*=\s*(.*)$") { 
            $DbPass = $matches[1].Trim()
            $DbUser = "root"
        }
    }
}

Write-Host "Dang sao chep tep sao luu vao container de phuc hoi (tranh loi ma hoa boi PowerShell pipe)..." -ForegroundColor Cyan

# Sao chép tệp trực tiếp dạng nhị phân vào container bằng docker compose cp, tuyệt đối không dùng pipe (|)
docker compose -f $ComposeFile cp $BackupFilePath db:/tmp/restore.sql

Write-Host "Dang thuc thi phuc hoi trong container voi charset utf8mb4..." -ForegroundColor Cyan
docker compose -f $ComposeFile exec -T db mysql --default-character-set=utf8mb4 -u $DbUser -p"$DbPass" $DbName -e "source /tmp/restore.sql"

# Dọn dẹp tệp tạm trong container
docker compose -f $ComposeFile exec -T db rm -f /tmp/restore.sql

if ($LASTEXITCODE -eq 0) {
    Write-Host "Phuc hoi co so du lieu MySQL thanh cong!" -ForegroundColor Green
} else {
    Write-Host "Phuc hoi that bai!" -ForegroundColor Red
    exit 1
}
