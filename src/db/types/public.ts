// 자동 생성된 public 스키마 타입
// 생성 시간: 2025-05-07T08:44:29.379Z

export interface PolicyVersions {
  id: any;
  policyType: any;
  version: any;
  publishedAt: any;
  isCurrent: any;
}

export interface UserConsents {
  id: any;
  userId: any;
  privacyPolicyAccepted: any;
  privacyPolicyVersion: any;
  privacyPolicyAcceptedAt: any;
  termsOfServiceAccepted: any;
  termsOfServiceVersion: any;
  termsOfServiceAcceptedAt: any;
  createdAt: any;
  updatedAt: any;
}

export interface UserProfiles {
  id: any;
  userId: any;
  email: any;
  phone: any;
  displayName: any;
  providers: any;
  providerType: any;
  createdAt: any;
  updatedAt: any;
}

