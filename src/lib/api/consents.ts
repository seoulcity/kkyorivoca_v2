import { supabase } from '$lib/supabase';
import type { UserConsents, PolicyVersions } from '../../db/types/public';

/**
 * Get the current user's consent status
 */
export async function getUserConsents(userId: string): Promise<UserConsents | null> {
  const { data, error } = await supabase
    .from('user_consents')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (error) {
    console.error('Error fetching user consents:', error);
    return null;
  }

  return data as unknown as UserConsents;
}

/**
 * Get the current version of a policy
 */
export async function getCurrentPolicyVersion(policyType: 'privacy_policy' | 'terms_of_service'): Promise<PolicyVersions | null> {
  const { data, error } = await supabase
    .from('policy_versions')
    .select('*')
    .eq('policy_type', policyType)
    .eq('is_current', true)
    .single();

  if (error) {
    console.error(`Error fetching current ${policyType} version:`, error);
    return null;
  }

  return data as unknown as PolicyVersions;
}

/**
 * Record user's consent to a policy
 */
export async function recordPolicyConsent(
  userId: string,
  policyType: 'privacy_policy' | 'terms_of_service',
  accepted: boolean
): Promise<boolean> {
  // Get current policy version
  const currentPolicyVersion = await getCurrentPolicyVersion(policyType);
  if (!currentPolicyVersion) {
    console.error(`Could not find current ${policyType} version`);
    return false;
  }

  // Check if user already has a consent record
  const existingConsent = await getUserConsents(userId);

  // Prepare update data
  const updateData: Partial<UserConsents> = {};
  
  if (policyType === 'privacy_policy') {
    updateData.privacyPolicyAccepted = accepted;
    updateData.privacyPolicyVersion = currentPolicyVersion.version;
    updateData.privacyPolicyAcceptedAt = accepted ? new Date().toISOString() : null;
  } else {
    updateData.termsOfServiceAccepted = accepted;
    updateData.termsOfServiceVersion = currentPolicyVersion.version;
    updateData.termsOfServiceAcceptedAt = accepted ? new Date().toISOString() : null;
  }

  if (existingConsent) {
    // Update existing record
    const { error } = await supabase
      .from('user_consents')
      .update(updateData)
      .eq('user_id', userId);

    if (error) {
      console.error(`Error updating ${policyType} consent:`, error);
      return false;
    }
  } else {
    // Create new record
    const newConsent = {
      user_id: userId,
      privacy_policy_accepted: policyType === 'privacy_policy' ? accepted : false,
      privacy_policy_version: policyType === 'privacy_policy' ? currentPolicyVersion.version : null,
      privacy_policy_accepted_at: policyType === 'privacy_policy' && accepted ? new Date().toISOString() : null,
      terms_of_service_accepted: policyType === 'terms_of_service' ? accepted : false,
      terms_of_service_version: policyType === 'terms_of_service' ? currentPolicyVersion.version : null,
      terms_of_service_accepted_at: policyType === 'terms_of_service' && accepted ? new Date().toISOString() : null
    };

    const { error } = await supabase
      .from('user_consents')
      .insert(newConsent);

    if (error) {
      console.error(`Error creating ${policyType} consent:`, error);
      return false;
    }
  }

  return true;
}

/**
 * Check if user has accepted both privacy policy and terms of service
 */
export async function hasAcceptedPolicies(userId: string): Promise<boolean> {
  const consents = await getUserConsents(userId);
  
  if (!consents) {
    return false;
  }
  
  return consents.privacyPolicyAccepted && consents.termsOfServiceAccepted;
}

/**
 * Check if user needs to review and accept updated policies
 * (when policy versions have changed since last acceptance)
 */
export async function needsPolicyReview(userId: string): Promise<{
  needsPrivacyPolicyReview: boolean;
  needsTermsOfServiceReview: boolean;
}> {
  const consents = await getUserConsents(userId);
  
  if (!consents) {
    return {
      needsPrivacyPolicyReview: true,
      needsTermsOfServiceReview: true
    };
  }
  
  const currentPrivacyPolicy = await getCurrentPolicyVersion('privacy_policy');
  const currentTermsOfService = await getCurrentPolicyVersion('terms_of_service');
  
  return {
    needsPrivacyPolicyReview: 
      !consents.privacyPolicyAccepted || 
      !currentPrivacyPolicy || 
      consents.privacyPolicyVersion !== currentPrivacyPolicy.version,
    
    needsTermsOfServiceReview: 
      !consents.termsOfServiceAccepted || 
      !currentTermsOfService || 
      consents.termsOfServiceVersion !== currentTermsOfService.version
  };
} 