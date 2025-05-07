// 자동 생성된 auth 스키마 타입
// 생성 시간: 2025-05-07T08:44:29.376Z

export interface AuditLogEntries {
  instanceId: any;
  id: any;
  payload: any;
  createdAt: any;
  ipAddress: any;
}

export interface FlowState {
  id: any;
  userId: any;
  authCode: any;
  codeChallengeMethod: any;
  codeChallenge: any;
  providerType: any;
  providerAccessToken: any;
  providerRefreshToken: any;
  createdAt: any;
  updatedAt: any;
  authenticationMethod: any;
  authCodeIssuedAt: any;
}

export interface Identities {
  providerId: any;
  userId: any;
  identityData: any;
  provider: any;
  lastSignInAt: any;
  createdAt: any;
  updatedAt: any;
  email: any;
  id: any;
}

export interface Instances {
  id: any;
  uuid: any;
  rawBaseConfig: any;
  createdAt: any;
  updatedAt: any;
}

export interface MfaAmrClaims {
  sessionId: any;
  createdAt: any;
  updatedAt: any;
  authenticationMethod: any;
  id: any;
}

export interface MfaChallenges {
  id: any;
  factorId: any;
  createdAt: any;
  verifiedAt: any;
  ipAddress: any;
  otpCode: any;
  webAuthnSessionData: any;
}

export interface MfaFactors {
  id: any;
  userId: any;
  friendlyName: any;
  factorType: any;
  status: any;
  createdAt: any;
  updatedAt: any;
  secret: any;
  phone: any;
  lastChallengedAt: any;
  webAuthnCredential: any;
  webAuthnAaguid: any;
}

export interface OneTimeTokens {
  id: any;
  userId: any;
  tokenType: any;
  tokenHash: any;
  relatesTo: any;
  createdAt: any;
  updatedAt: any;
}

export interface RefreshTokens {
  instanceId: any;
  id: any;
  token: any;
  userId: any;
  revoked: any;
  createdAt: any;
  updatedAt: any;
  parent: any;
  sessionId: any;
}

export interface SamlProviders {
  id: any;
  ssoProviderId: any;
  entityId: any;
  metadataXml: any;
  metadataUrl: any;
  attributeMapping: any;
  createdAt: any;
  updatedAt: any;
  nameIdFormat: any;
}

export interface SamlRelayStates {
  id: any;
  ssoProviderId: any;
  requestId: any;
  forEmail: any;
  redirectTo: any;
  createdAt: any;
  updatedAt: any;
  flowStateId: any;
}

export interface SchemaMigrations {
  version: any;
}

export interface Sessions {
  id: any;
  userId: any;
  createdAt: any;
  updatedAt: any;
  factorId: any;
  aal: any;
  notAfter: any;
  refreshedAt: any;
  userAgent: any;
  ip: any;
  tag: any;
}

export interface SsoDomains {
  id: any;
  ssoProviderId: any;
  domain: any;
  createdAt: any;
  updatedAt: any;
}

export interface SsoProviders {
  id: any;
  resourceId: any;
  createdAt: any;
  updatedAt: any;
}

export interface Users {
  instanceId: any;
  id: any;
  aud: any;
  role: any;
  email: any;
  encryptedPassword: any;
  emailConfirmedAt: any;
  invitedAt: any;
  confirmationToken: any;
  confirmationSentAt: any;
  recoveryToken: any;
  recoverySentAt: any;
  emailChangeTokenNew: any;
  emailChange: any;
  emailChangeSentAt: any;
  lastSignInAt: any;
  rawAppMetaData: any;
  rawUserMetaData: any;
  isSuperAdmin: any;
  createdAt: any;
  updatedAt: any;
  phone: any;
  phoneConfirmedAt: any;
  phoneChange: any;
  phoneChangeToken: any;
  phoneChangeSentAt: any;
  confirmedAt: any;
  emailChangeTokenCurrent: any;
  emailChangeConfirmStatus: any;
  bannedUntil: any;
  reauthenticationToken: any;
  reauthenticationSentAt: any;
  isSsoUser: any;
  deletedAt: any;
  isAnonymous: any;
}

