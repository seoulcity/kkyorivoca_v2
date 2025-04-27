import { supabase } from '$lib/supabase';
import type { UserConsents, PolicyVersions } from '../../db/types/public';

/**
 * Get the current user's consent status
 */
export async function getUserConsents(userId: string): Promise<UserConsents | null> {
  console.log('API: Getting user consents for user:', userId);
  const { data, error } = await supabase
    .from('user_consents')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (error) {
    console.error('Error fetching user consents:', error);
    return null;
  }

  console.log('API: User consents data:', data);
  return data as unknown as UserConsents;
}

/**
 * Get the current version of a policy
 */
export async function getCurrentPolicyVersion(policyType: 'privacy_policy' | 'terms_of_service'): Promise<PolicyVersions | null> {
  console.log('API: Getting current policy version for:', policyType);
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

  console.log(`API: Current ${policyType} version:`, data);
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
  console.log(`API: Recording ${policyType} consent for user ${userId}, accepted: ${accepted}`);
  
  // Get current policy version
  const currentPolicyVersion = await getCurrentPolicyVersion(policyType);
  if (!currentPolicyVersion) {
    console.error(`Could not find current ${policyType} version`);
    return false;
  }

  // Check if user already has a consent record
  const existingConsent = await getUserConsents(userId);
  console.log('API: Existing consent record:', existingConsent);

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

  console.log('API: Update data prepared:', updateData);

  if (existingConsent) {
    // Update existing record
    console.log('API: Updating existing consent record');
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
    console.log('API: Creating new consent record');
    const newConsent = {
      user_id: userId,
      privacy_policy_accepted: policyType === 'privacy_policy' ? accepted : false,
      privacy_policy_version: policyType === 'privacy_policy' ? currentPolicyVersion.version : null,
      privacy_policy_accepted_at: policyType === 'privacy_policy' && accepted ? new Date().toISOString() : null,
      terms_of_service_accepted: policyType === 'terms_of_service' ? accepted : false,
      terms_of_service_version: policyType === 'terms_of_service' ? currentPolicyVersion.version : null,
      terms_of_service_accepted_at: policyType === 'terms_of_service' && accepted ? new Date().toISOString() : null
    };

    console.log('API: New consent data:', newConsent);
    const { error } = await supabase
      .from('user_consents')
      .insert(newConsent);

    if (error) {
      console.error(`Error creating ${policyType} consent:`, error);
      return false;
    }
  }

  console.log(`API: ${policyType} consent recorded successfully`);
  return true;
}

/**
 * Check if user has accepted both privacy policy and terms of service
 */
export async function hasAcceptedPolicies(userId: string): Promise<boolean> {
  console.log('API: Checking if user has accepted all policies:', userId);
  const consents = await getUserConsents(userId);
  
  if (!consents) {
    console.log('API: No consent records found for user');
    return false;
  }
  
  const result = consents.privacyPolicyAccepted && consents.termsOfServiceAccepted;
  console.log('API: Policy acceptance status:', result);
  return result;
}

/**
 * Check if user needs to review and accept updated policies
 * (when policy versions have changed since last acceptance)
 */
export async function needsPolicyReview(userId: string): Promise<{
  needsPrivacyPolicyReview: boolean;
  needsTermsOfServiceReview: boolean;
}> {
  console.log('API: Checking if user needs policy review:', userId);
  const consents = await getUserConsents(userId);
  
  if (!consents) {
    console.log('API: No consents found, user needs to review all policies');
    return {
      needsPrivacyPolicyReview: true,
      needsTermsOfServiceReview: true
    };
  }
  
  const currentPrivacyPolicy = await getCurrentPolicyVersion('privacy_policy');
  const currentTermsOfService = await getCurrentPolicyVersion('terms_of_service');
  
  const result = {
    needsPrivacyPolicyReview: 
      !consents.privacyPolicyAccepted || 
      !currentPrivacyPolicy || 
      consents.privacyPolicyVersion !== currentPrivacyPolicy.version,
    
    needsTermsOfServiceReview: 
      !consents.termsOfServiceAccepted || 
      !currentTermsOfService || 
      consents.termsOfServiceVersion !== currentTermsOfService.version
  };
  
  console.log('API: Policy review needs:', result);
  return result;
} 