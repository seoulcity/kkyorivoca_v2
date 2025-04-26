<script lang="ts">
	import { createEventDispatcher, onMount } from 'svelte';
	import { fade } from 'svelte/transition';
	import ConsentForm from './ConsentForm.svelte';
	import { user } from '$lib/auth';
	import { hasAcceptedPolicies, needsPolicyReview } from '$lib/api/consents';

	export let show = false;
	
	// Track which policies the user needs to review
	let policyReviewState = {
		needsPrivacyPolicyReview: true,
		needsTermsOfServiceReview: true
	};
	
	let loading = true;
	
	const dispatch = createEventDispatcher<{
		close: { success: boolean };
	}>();
	
	// Check if user needs to review policies when the user is loaded
	$: if ($user && show) {
		checkPolicyConsent();
	}
	
	async function checkPolicyConsent() {
		if (!$user) return;
		
		loading = true;
		try {
			policyReviewState = await needsPolicyReview($user.id);
			
			// If no policies need review, close the modal
			if (!policyReviewState.needsPrivacyPolicyReview && !policyReviewState.needsTermsOfServiceReview) {
				dispatch('close', { success: true });
			}
		} catch (error) {
			console.error('Error checking policy consent:', error);
		} finally {
			loading = false;
		}
	}
	
	function handleConsentComplete(event: CustomEvent<{ success: boolean; error?: string }>) {
		if (event.detail.success) {
			dispatch('close', { success: true });
		}
	}
</script>

{#if show}
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