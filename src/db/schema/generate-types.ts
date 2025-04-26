// TypeScript 타입 생성기
// 스키마별 JSON 파일을 읽고 해당 스키마에 대한 TypeScript 타입을 생성합니다.

import fs from 'fs';
import path from 'path';

interface Column {
  name: string;
  type: string;
  nullable: string;
  default: string;
  max_length: string;
}

interface Index {
  name: string;
  unique: string;
  columns: string;
}

interface Table {
  name: string;
  columns: Column[];
  indexes: Index[];
}

interface SchemaFile {
  schema: string;
  database: string;
  extracted_at: string;
  tables: Table[];
}

interface SchemaIndex {
  name: string;
  file: string;
}

interface SchemaCollection {
  database: string;
  extracted_at: string;
  schemas: SchemaIndex[];
}

// PostgreSQL 타입을 TypeScript 타입으로 변환
function pgTypeToTsType(pgType: string): string {
  const typeMap: Record<string, string> = {
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
function toCamelCase(str: string): string {
  return str.replace(/([-_][a-z])/g, (group) =>
    group.toUpperCase().replace('-', '').replace('_', '')
  );
}

// 파스칼 케이스 변환
function toPascalCase(str: string): string {
  const camel = toCamelCase(str);
  return camel.charAt(0).toUpperCase() + camel.slice(1);
}

async function generateTypes() {
  try {
    // 스키마 인덱스 파일 읽기
    const schemaIndexPath = path.join(__dirname, 'db-schemas.json');
    const schemaIndexData = fs.readFileSync(schemaIndexPath, 'utf8');
    const schemaCollection: SchemaCollection = JSON.parse(schemaIndexData);

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
      const schemaData: SchemaFile = JSON.parse(schemaFileData);

      const schemaName = schemaData.schema;
      const schemaFile = path.join(typesDir, `${schemaName}.ts`);
      let schemaContent = `// 자동 생성된 ${schemaName} 스키마 타입\n// 생성 시간: ${new Date().toISOString()}\n\n`;

      // 각 테이블에 대해 처리
      for (const table of schemaData.tables) {
        const interfaceName = toPascalCase(table.name);
        
        schemaContent += `export interface ${interfaceName} {\n`;
        
        // 각 컬럼에 대해 처리
        for (const column of table.columns) {
          const columnName = toCamelCase(column.name);
          const tsType = pgTypeToTsType(column.type);
          const isNullable = column.nullable === 'YES' ? true : false;
          
          schemaContent += `  ${columnName}${isNullable ? '?' : ''}: ${tsType};\n`;
        }
        
        schemaContent += `}\n\n`;
      }

      // 스키마 파일 작성
      fs.writeFileSync(schemaFile, schemaContent);
      console.log(`스키마 ${schemaName}의 타입 정의를 생성했습니다: ${schemaFile}`);
      
      // 인덱스 파일에 추가
      indexContent += `export * from './${schemaName}';\n`;
    }

    // 인덱스 파일 작성
    fs.writeFileSync(path.join(typesDir, 'index.ts'), indexContent);
    console.log(`인덱스 파일을 생성했습니다: ${path.join(typesDir, 'index.ts')}`);
    
    console.log('모든 TypeScript 타입 생성이 완료되었습니다.');
  } catch (error) {
    console.error('타입 생성 중 오류 발생:', error);
  }
}

generateTypes().catch(console.error);
