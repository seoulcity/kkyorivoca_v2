<script lang="ts">
	import { createEventDispatcher, onMount } from 'svelte';
	import { fade } from 'svelte/transition';
	import ConsentForm from './ConsentForm.svelte';
	import { user } from '$lib/auth';
	import { hasAcceptedPolicies, needsPolicyReview } from '$lib/api/consents';

	// Props 정의
	let { show = false } = $props();
	
	// Track which policies the user needs to review
	let policyReviewState = {
		needsPrivacyPolicyReview: true,
		needsTermsOfServiceReview: true
	};
	
	let loading = true;
	
	const dispatch = createEventDispatcher<{
		close: { success: boolean };
	}>();
	
	// 모달 표시 상태가 변경될 때마다 로깅
	$effect(() => {
		console.log('ConsentModal Component: Modal visibility changed to:', show);
		if (show && $user) {
			// 모달이 표시될 때 정책 동의 상태 확인
			checkPolicyConsent();
		}
	});
	
	async function checkPolicyConsent() {
		if (!$user) {
			console.log('ConsentModal: No user, skipping consent check');
			return;
		}
		
		console.log('ConsentModal: Checking policy consent for user:', $user.id);
		loading = true;
		try {
			policyReviewState = await needsPolicyReview($user.id);
			console.log('ConsentModal: Policy review state:', policyReviewState);
			
			// If no policies need review, close the modal
			if (!policyReviewState.needsPrivacyPolicyReview && !policyReviewState.needsTermsOfServiceReview) {
				console.log('ConsentModal: No policies need review, closing modal');
				dispatch('close', { success: true });
			} else {
				console.log('ConsentModal: Policies need review, keeping modal open');
			}
		} catch (error) {
			console.error('Error checking policy consent:', error);
		} finally {
			loading = false;
		}
	}
	
	function handleConsentComplete(event: CustomEvent<{ success: boolean; error?: string }>) {
		console.log('ConsentModal: Consent completion event received:', event.detail);
		if (event.detail.success) {
			console.log('ConsentModal: User accepted policies, closing modal with success');
			dispatch('close', { success: true });
		} else {
			console.log('ConsentModal: Consent not successful, error:', event.detail.error);
		}
	}
</script>

{#if show}
	<!-- 모달이 표시되는지 확인하기 위한 로그 -->
	<div class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center" transition:fade>
		<div 
			class="relative bg-white rounded-lg shadow-xl w-full max-w-md mx-4 overflow-hidden" 
			transition:fade={{ delay: 150 }}
		>
			{#if loading}
				<div class="p-8 text-center">
					<div class="inline-block animate-spin rounded-full h-8 w-8 border-4 border-blue-500 border-t-transparent"></div>
					<p class="mt-4 text-gray-700">정보를 로드 중입니다...</p>
				</div>
			{:else}
				<div class="p-4 md:p-5 text-center">
					<h3 class="mb-5 text-lg font-semibold text-gray-900">서비스 이용 동의</h3>
					<p class="mb-5 text-sm text-gray-500">
						GenPub 서비스를 이용하기 위해서는 다음 약관에 동의해야 합니다.
					</p>
					
					<ConsentForm 
						showPrivacyPolicy={policyReviewState.needsPrivacyPolicyReview} 
						showTermsOfService={policyReviewState.needsTermsOfServiceReview}
						on:complete={handleConsentComplete}
					/>
				</div>
			{/if}
		</div>
	</div>
{/if} 