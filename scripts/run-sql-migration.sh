#!/bin/bash

# run-sql-migration.sh
# SQL 마이그레이션 파일을 실행하는 스크립트

set -e

# 실행 디렉토리를 스크립트 위치로 변경
cd "$(dirname "$0")/.."
echo "Working directory: $(pwd)"

# 사용법 표시
usage() {
  echo "Usage: $0 --sql-file <path_to_sql_file>"
  echo "Example: $0 --sql-file ./migrations/update-version.sql"
  exit 1
}

# 매개변수 파싱
SQL_FILE=""

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --sql-file)
      SQL_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      usage
      ;;
  esac
done

# 필수 매개변수 확인
if [ -z "$SQL_FILE" ]; then
  echo "Error: SQL file parameter is missing!"
  usage
fi

# SQL 파일 확인
if [ ! -f "$SQL_FILE" ]; then
  echo "Error: SQL file not found at $SQL_FILE"
  exit 1
fi

# .env 파일 로드
if [ -f .env ]; then
  echo "Loading environment variables from .env file..."
  export $(grep -v '^#' .env | xargs)
else
  echo "Error: .env file not found!"
  exit 1
fi

# 환경 변수 확인
if [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] || [ -z "$PG_DATABASE" ] || [ -z "$PG_USER" ] || [ -z "$PG_PASSWORD" ]; then
  echo "Error: Database connection environment variables are missing!"
  exit 1
fi

echo "SQL file: $SQL_FILE"

# SQL 마이그레이션 실행
run_migration() {
  if command -v psql >/dev/null 2>&1; then
    echo "Using PostgreSQL client to run SQL migration..."
    
    # PGPASSWORD 환경변수로 비밀번호 전달
    export PGPASSWORD="$PG_PASSWORD"
    
    # SQL 실행
    psql -h "$PG_HOST" -p "$PG_PORT" -d "$PG_DATABASE" -U "$PG_USER" -f "$SQL_FILE" -v ON_ERROR_STOP=1 --quiet --no-psqlrc -X --set AUTOCOMMIT=off --set ON_ERROR_STOP=on -L /dev/null
    MIGRATION_RESULT=$?
    
    # 결과 확인
    if [ $MIGRATION_RESULT -eq 0 ]; then
      echo "✅ SQL migration executed successfully!"
    else
      echo "❌ SQL migration failed with exit code $MIGRATION_RESULT"
      exit $MIGRATION_RESULT
    fi
  else
    # PostgreSQL 클라이언트가 없는 경우 Node.js 스크립트 사용
    echo "PostgreSQL client not found, using Node.js alternative..."
    
    # Node.js 실행
    node -e "
    const { Pool } = require('pg');
    const fs = require('fs');
    
    // SQL 파일 읽기
    const sqlScript = fs.readFileSync('$SQL_FILE', 'utf8');
    
    // 데이터베이스 연결 풀 생성
    const pool = new Pool({
      host: '$PG_HOST',
      port: parseInt('$PG_PORT', 10),
      database: '$PG_DATABASE',
      user: '$PG_USER',
      password: '$PG_PASSWORD',
      ssl: { rejectUnauthorized: false }
    });
    
    async function runMigration() {
      const client = await pool.connect();
      try {
        console.log('Starting SQL migration...');
        await client.query('BEGIN');
        await client.query(sqlScript);
        await client.query('COMMIT');
        console.log('✅ SQL migration executed successfully!');
        process.exit(0);
      } catch (error) {
        await client.query('ROLLBACK');
        console.error('❌ SQL migration failed:', error);
        process.exit(1);
      } finally {
        client.release();
        await pool.end();
      }
    }
    
    runMigration();
    "
    MIGRATION_RESULT=$?
    
    # Node.js 스크립트 결과 확인
    if [ $MIGRATION_RESULT -ne 0 ]; then
      echo "SQL migration failed with exit code $MIGRATION_RESULT"
      exit $MIGRATION_RESULT
    fi
  fi
}

# 마이그레이션 실행
run_migration

echo -e "\n✅ SQL migration complete!"
echo "Executed SQL file: $SQL_FILE"
echo "Timestamp: $(date)" 