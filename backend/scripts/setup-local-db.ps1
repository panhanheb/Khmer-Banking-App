# One-time setup for a NATIVE Windows PostgreSQL (no Docker).
# Creates/updates the "khmerbank" role + database using DB_PASSWORD from the repo-root .env.
# Safe to re-run: it only (re)sets the role password and creates the DB if missing.
#
#   powershell -ExecutionPolicy Bypass -File backend\scripts\setup-local-db.ps1
#
# You'll be prompted for the "postgres" superuser password (the one chosen when installing PostgreSQL).

$ErrorActionPreference = 'Stop'
$root = Resolve-Path "$PSScriptRoot\..\.."
$envFile = Join-Path $root '.env'
if (-not (Test-Path $envFile)) { throw ".env not found at $envFile - copy .env.example to .env first." }

$dbPassword = (Get-Content $envFile | Where-Object { $_ -match '^\s*DB_PASSWORD\s*=' } | Select-Object -First 1) -replace '^\s*DB_PASSWORD\s*=\s*', ''
if (-not $dbPassword) { throw "DB_PASSWORD is empty in .env" }

$psql = Get-ChildItem 'C:\Program Files\PostgreSQL\*\bin\psql.exe' -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
if (-not $psql) { $psql = (Get-Command psql -ErrorAction Stop).Source }

$secure = Read-Host 'Password for PostgreSQL superuser "postgres"' -AsSecureString
$env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))

try {
    $pw = $dbPassword.Replace("'", "''")
    $sql = @"
DO `$`$ BEGIN
  IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'khmerbank') THEN
    ALTER ROLE khmerbank WITH LOGIN PASSWORD '$pw';
  ELSE
    CREATE ROLE khmerbank WITH LOGIN PASSWORD '$pw';
  END IF;
END `$`$;
"@
    $sql | & $psql -h localhost -U postgres -d postgres -v ON_ERROR_STOP=1 -q
    if ($LASTEXITCODE -ne 0) { throw "Failed to create/update role (wrong postgres password?)" }

    $exists = & $psql -h localhost -U postgres -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = 'khmerbank'"
    if ($exists -ne '1') {
        & $psql -h localhost -U postgres -d postgres -v ON_ERROR_STOP=1 -q -c "CREATE DATABASE khmerbank OWNER khmerbank"
        if ($LASTEXITCODE -ne 0) { throw "Failed to create database" }
    }
    & $psql -h localhost -U postgres -d khmerbank -v ON_ERROR_STOP=1 -q -c "ALTER SCHEMA public OWNER TO khmerbank"

    $env:PGPASSWORD = $dbPassword
    & $psql -h localhost -U khmerbank -d khmerbank -tAc "SELECT 'OK: khmerbank can log in to database ' || current_database()"
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}
