#!/bin/bash

# 데이터베이스 스키마 및 테이블 정보 인덱싱 스크립트
# PostgreSQL 데이터베이스의 스키마 구조와 테이블 정보를 추출하여 JSON 파일로 저장합니다.

# .env 파일에서 환경 변수 로드
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
  echo "환경 변수를 .env 파일에서 로드했습니다."
else
  echo "경고: .env 파일을 찾을 수 없습니다."
  exit 1
fi

# 필요한 환경 변수 확인
required_vars=("PG_HOST" "PG_PORT" "PG_DATABASE" "PG_USER" "PG_PASSWORD")
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "오류: 환경 변수 $var가 설정되지 않았습니다."
    exit 1
  fi
done

# 결과를 저장할 디렉토리 생성
output_dir="src/db/schema"
mkdir -p "$output_dir"

echo "PostgreSQL 데이터베이스 스키마 인덱싱을 시작합니다..."

# 모든 스키마 목록 조회
PGPASSWORD=$PG_PASSWORD psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DATABASE -t -c "
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name NOT IN ('pg_catalog', 'information_schema') 
ORDER BY schema_name;" > "$output_dir/schemas.txt"

echo "스키마 목록을 저장했습니다: $output_dir/schemas.txt"

# 메타데이터 인덱스 JSON 파일 시작
cat > "$output_dir/db-schemas.json" << EOF
{
  "database": "$PG_DATABASE",
  "extracted_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "schemas": [
EOF

first_schema=true

# 각 스키마에 대해 처리
while read schema; do
  schema=$(echo "$schema" | xargs)  # 공백 제거
  
  if [ -z "$schema" ]; then
    continue
  fi
  
  if [ "$first_schema" = true ]; then
    first_schema=false
  else
    echo "  }," >> "$output_dir/db-schemas.json"
  fi
  
  echo "스키마 '$schema' 처리 중..."
  
  # 스키마 인덱스 정보 추가
  cat >> "$output_dir/db-schemas.json" << EOF
  {
    "name": "$schema",
    "file": "${schema}.json"
EOF

  # 개별 스키마 JSON 파일 시작
  cat > "$output_dir/${schema}.json" << EOF
{
  "schema": "$schema",
  "database": "$PG_DATABASE",
  "extracted_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "tables": [
EOF
  
  # 스키마의 모든 테이블 목록 조회
  PGPASSWORD=$PG_PASSWORD psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DATABASE -t -c "
  SELECT table_name 
  FROM information_schema.tables 
  WHERE table_schema = '$schema' 
  AND table_type = 'BASE TABLE' 
  ORDER BY table_name;" > "$output_dir/${schema}_tables.txt"
  
  first_table=true
  
  # 각 테이블에 대해 처리
  while read table; do
    table=$(echo "$table" | xargs)  # 공백 제거
    
    if [ -z "$table" ]; then
      continue
    fi
    
    if [ "$first_table" = true ]; then
      first_table=false
    else
      echo "    }," >> "$output_dir/${schema}.json"
    fi
    
    echo "  - 테이블 '$table' 처리 중..."
    
    # 테이블 정보 추가
    cat >> "$output_dir/${schema}.json" << EOF
    {
      "name": "$table",
      "columns": [
EOF

    # 테이블의 모든 컬럼 정보 조회
    PGPASSWORD=$PG_PASSWORD psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DATABASE -t -c "
    SELECT 
      column_name, 
      data_type, 
      is_nullable, 
      column_default,
      character_maximum_length
    FROM information_schema.columns 
    WHERE table_schema = '$schema' 
    AND table_name = '$table' 
    ORDER BY ordinal_position;" > "$output_dir/${schema}_${table}_columns.txt"
    
    first_column=true
    
    # 각 컬럼에 대해 처리
    while read column_info; do
      if [ -z "$column_info" ]; then
        continue
      fi
      
      # 컬럼 정보 파싱
      column_name=$(echo "$column_info" | awk '{print $1}')
      data_type=$(echo "$column_info" | awk '{print $2}')
      is_nullable=$(echo "$column_info" | awk '{print $3}')
      column_default=$(echo "$column_info" | awk '{print $4}')
      max_length=$(echo "$column_info" | awk '{print $5}')
      
      if [ "$first_column" = true ]; then
        first_column=false
      else
        echo "        }," >> "$output_dir/${schema}.json"
      fi
      
      # 컬럼 정보 추가
      cat >> "$output_dir/${schema}.json" << EOF
        {
          "name": "$column_name",
          "type": "$data_type",
          "nullable": "$is_nullable",
          "default": "$column_default",
          "max_length": "$max_length"
EOF
      
    done < "$output_dir/${schema}_${table}_columns.txt"
    
    # 컬럼 정보 닫기
    if [ "$first_column" = false ]; then
      echo "        }" >> "$output_dir/${schema}.json"
    fi
    echo "      ]," >> "$output_dir/${schema}.json"
    
    # 테이블 인덱스 정보 추가
    cat >> "$output_dir/${schema}.json" << EOF
      "indexes": [
EOF
    
    # 테이블의 모든 인덱스 정보 조회
    PGPASSWORD=$PG_PASSWORD psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DATABASE -t -c "
    SELECT
      i.relname AS index_name,
      ix.indisunique AS is_unique,
      array_to_string(ARRAY(
        SELECT pg_get_indexdef(ix.indexrelid, k + 1, true)
        FROM generate_subscripts(ix.indkey, 0) AS k
        ORDER BY k
      ), ', ') AS index_keys
    FROM
      pg_index AS ix
      JOIN pg_class AS i ON i.oid = ix.indexrelid
      JOIN pg_class AS t ON t.oid = ix.indrelid
      JOIN pg_namespace AS n ON n.oid = t.relnamespace
    WHERE
      t.relname = '$table'
      AND n.nspname = '$schema'
    ORDER BY
      i.relname;" > "$output_dir/${schema}_${table}_indexes.txt"
    
    first_index=true
    
    # 각 인덱스에 대해 처리
    while read index_info; do
      if [ -z "$index_info" ]; then
        continue
      fi
      
      # 인덱스 정보 파싱
      index_name=$(echo "$index_info" | awk '{print $1}')
      is_unique=$(echo "$index_info" | awk '{print $2}')
      index_keys=$(echo "$index_info" | cut -d ' ' -f 3-)
      
      if [ "$first_index" = true ]; then
        first_index=false
      else
        echo "        }," >> "$output_dir/${schema}.json"
      fi
      
      # 인덱스 정보 추가
      cat >> "$output_dir/${schema}.json" << EOF
        {
          "name": "$index_name",
          "unique": "$is_unique",
          "columns": "$index_keys"
EOF
      
    done < "$output_dir/${schema}_${table}_indexes.txt"
    
    # 인덱스 정보 닫기
    if [ "$first_index" = false ]; then
      echo "        }" >> "$output_dir/${schema}.json"
    fi
    echo "      ]" >> "$output_dir/${schema}.json"
    
  done < "$output_dir/${schema}_tables.txt"
  
  # 테이블 배열 닫기
  if [ "$first_table" = false ]; then
    echo "    }" >> "$output_dir/${schema}.json"
  fi
  echo "  ]" >> "$output_dir/${schema}.json"
  echo "}" >> "$output_dir/${schema}.json"
  
done < "$output_dir/schemas.txt"

# 인덱스 JSON 파일 닫기
if [ "$first_schema" = false ]; then
  echo "  }" >> "$output_dir/db-schemas.json"
fi
echo "]" >> "$output_dir/db-schemas.json"
echo "}" >> "$output_dir/db-schemas.json"

# 임시 파일 정리
find "$output_dir" -name "*.txt" -type f -delete

echo "데이터베이스 스키마 인덱싱이 완료되었습니다."
echo "결과가 $output_dir 디렉토리에 저장되었습니다."
echo "스키마 인덱스: $output_dir/db-schemas.json"

# JavaScript 타입 생성기 파일 생성
cat > "$output_dir/generate-types.js" << EOF
// JavaScript 타입 생성기
// 스키마별 JSON 파일을 읽고 해당 스키마에 대한 TypeScript 타입을 생성합니다.

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// ESM에서 __dirname 사용하기 위한 설정
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// PostgreSQL 타입을 TypeScript 타입으로 변환
function pgTypeToTsType(pgType) {
  const typeMap = {
    'integer': 'number',
    'bigint': 'number',
    'smallint': 'number',
    'decimal': 'number',
    'numeric': 'number',
    'real': 'number',
    'double precision': 'number',
    'character varying': 'string',
    'varchar': 'string',
    'character': 'string',
    'char': 'string',
    'text': 'string',
    'boolean': 'boolean',
    'timestamp': 'Date',
    'timestamp with time zone': 'Date',
    'timestamp without time zone': 'Date',
    'date': 'Date',
    'time': 'string',
    'json': 'Record<string, any>',
    'jsonb': 'Record<string, any>',
    'uuid': 'string',
    'bytea': 'Uint8Array',
    'array': 'any[]'
  };

  return typeMap[pgType] || 'any';
}

// 스네이크 케이스를 카멜 케이스로 변환
function toCamelCase(str) {
  return str.replace(/([-_][a-z])/g, (group) =>
    group.toUpperCase().replace('-', '').replace('_', '')
  );
}

// 파스칼 케이스 변환
function toPascalCase(str) {
  const camel = toCamelCase(str);
  return camel.charAt(0).toUpperCase() + camel.slice(1);
}

async function generateTypes() {
  try {
    // 스키마 인덱스 파일 읽기
    const schemaIndexPath = path.join(__dirname, 'db-schemas.json');
    const schemaIndexData = fs.readFileSync(schemaIndexPath, 'utf8');
    const schemaCollection = JSON.parse(schemaIndexData);

    // 출력 디렉토리
    const typesDir = path.join(__dirname, '../types');
    if (!fs.existsSync(typesDir)) {
      fs.mkdirSync(typesDir, { recursive: true });
    }

    // 인덱스 파일
    let indexContent = '// 자동 생성된 데이터베이스 타입\n// 생성 시간: ' + new Date().toISOString() + '\n\n';

    // 각 스키마에 대해 처리
    for (const schemaIndex of schemaCollection.schemas) {
      // 스키마 파일 읽기
      const schemaFilePath = path.join(__dirname, schemaIndex.file);
      const schemaFileData = fs.readFileSync(schemaFilePath, 'utf8');
      const schemaData = JSON.parse(schemaFileData);

      const schemaName = schemaData.schema;
      const schemaFile = path.join(typesDir, \`\${schemaName}.ts\`);
      let schemaContent = \`// 자동 생성된 \${schemaName} 스키마 타입\n// 생성 시간: \${new Date().toISOString()}\n\n\`;

      // 각 테이블에 대해 처리
      for (const table of schemaData.tables) {
        const interfaceName = toPascalCase(table.name);
        
        schemaContent += \`export interface \${interfaceName} {\n\`;
        
        // 각 컬럼에 대해 처리
        for (const column of table.columns) {
          const columnName = toCamelCase(column.name);
          const tsType = pgTypeToTsType(column.type);
          const isNullable = column.nullable === 'YES' ? true : false;
          
          schemaContent += \`  \${columnName}\${isNullable ? '?' : ''}: \${tsType};\n\`;
        }
        
        schemaContent += \`}\n\n\`;
      }

      // 스키마 파일 작성
      fs.writeFileSync(schemaFile, schemaContent);
      console.log(\`스키마 \${schemaName}의 타입 정의를 생성했습니다: \${schemaFile}\`);
      
      // 인덱스 파일에 추가
      indexContent += \`export * from './\${schemaName}';\n\`;
    }

    // 인덱스 파일 작성
    fs.writeFileSync(path.join(typesDir, 'index.ts'), indexContent);
    console.log(\`인덱스 파일을 생성했습니다: \${path.join(typesDir, 'index.ts')}\`);
    
    console.log('모든 TypeScript 타입 생성이 완료되었습니다.');
  } catch (error) {
    console.error('타입 생성 중 오류 발생:', error);
  }
}

generateTypes().catch(console.error);
EOF

echo "JavaScript 타입 생성기가 $output_dir/generate-types.js 파일에 생성되었습니다."
echo "타입을 생성하려면 다음 명령을 실행하세요: node $output_dir/generate-types.js"

# 실행 권한 부여
chmod +x "$0" 