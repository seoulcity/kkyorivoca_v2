// 자동 생성된 public 스키마 타입
// 생성 시간: 2025-04-26T11:41:32.556Z

export interface UserConsents {
  id: string;
  userId: string;
  privacyPolicyAccepted: boolean;
  privacyPolicyVersion: string | null;
  privacyPolicyAcceptedAt: Date | string | null;
  termsOfServiceAccepted: boolean;
  termsOfServiceVersion: string | null;
  termsOfServiceAcceptedAt: Date | string | null;
  createdAt: Date | string;
  updatedAt: Date | string;
}

export interface PolicyVersions {
  id: string;
  policyType: string;
  version: string;
  publishedAt: Date | string;
  isCurrent: boolean;
}

