// 자동 생성된 storage 스키마 타입
// 생성 시간: 2025-05-06T13:02:44.794Z

export interface Buckets {
  id: any;
  name: any;
  owner: any;
  createdAt: any;
  updatedAt: any;
  public: any;
  avifAutodetection: any;
  fileSizeLimit: any;
  allowedMimeTypes: any;
  ownerId: any;
}

export interface Migrations {
  id: any;
  name: any;
  hash: any;
  executedAt: any;
}

export interface Objects {
  id: any;
  bucketId: any;
  name: any;
  owner: any;
  createdAt: any;
  updatedAt: any;
  lastAccessedAt: any;
  metadata: any;
  pathTokens: any;
  version: any;
  ownerId: any;
  userMetadata: any;
  level: any;
}

export interface Prefixes {
  bucketId: any;
  name: any;
  level: any;
  createdAt: any;
  updatedAt: any;
}

export interface S3MultipartUploads {
  id: any;
  inProgressSize: any;
  uploadSignature: any;
  bucketId: any;
  key: any;
  version: any;
  ownerId: any;
  createdAt: any;
  userMetadata: any;
}

export interface S3MultipartUploadsParts {
  id: any;
  uploadId: any;
  size: any;
  partNumber: any;
  bucketId: any;
  key: any;
  etag: any;
  ownerId: any;
  version: any;
  createdAt: any;
}

