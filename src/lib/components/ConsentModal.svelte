<script lang="ts">
	import { createEventDispatcher, onMount } from 'svelte';
	import { fade } from 'svelte/transition';
	import ConsentForm from './ConsentForm.svelte';
	import { user } from '$lib/auth';
	import { hasAcceptedPolicies, needsPolicyReview } from '$lib/api/consents';
	import { goto } from '$app/navigation';

	// Props 정의
	let { show = false } = $props();
	
	// 내부적으로 모달 표시 상태를 관리
	let modalVisible = $state(false);
	
	// props의 show 값 변경을 감지하여 내부 상태 업데이트
	$effect(() => {
		modalVisible = show;
	});
	
	// Track which policies the user needs to review
	let policyReviewState = $state({
		needsPrivacyPolicyReview: true,
		needsTermsOfServiceReview: true
	});
	
	let loading = $state(true);
	
	const dispatch = createEventDispatcher<{
		close: { success: boolean };
	}>();
	
	// 모달 표시 상태가 변경될 때마다 로깅
	$effect(() => {
		console.log('ConsentModal Component: Modal visibility changed to:', modalVisible);
		if (modalVisible && $user) {
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
	
	// 약관 또는 개인정보 처리방침 페이지로 이동할 때 모달을 임시로 닫는 함수
	function handleTemporaryClose(event: CustomEvent<{ redirectTo: string }>) {
		console.log('ConsentModal: Temporarily closing modal for navigation to', event.detail.redirectTo);
		// 모달 닫기 (내부 상태 변경)
		modalVisible = false;
		// 부모 컴포넌트에 닫았음을 알림
		dispatch('close', { success: false });
		// 페이지 이동
		goto(event.detail.redirectTo);
	}
</script>

{#if modalVisible}
	<!-- 디버그 로그 및 모달 표시 -->
	<script>
		console.log('%cCONSENT MODAL IS VISIBLE!', 'color: green; font-size: 24px; font-weight: bold;');
	</script>
	
	<div class="fixed inset-0 bg-black bg-opacity-50 z-[9999] flex items-center justify-center" style="position: fixed !important; top: 0; left: 0; right: 0; bottom: 0; z-index: 9999;">
		<div 
			class="relative bg-white rounded-lg shadow-xl w-full max-w-md mx-4 overflow-hidden" 
			role="dialog" 
			aria-modal="true"
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
						on:temporaryClose={handleTemporaryClose}
					/>
				</div>
			{/if}
		</div>
	</div>
{/if} 