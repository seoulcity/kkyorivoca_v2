<!-- src/lib/components/ConsentForm.svelte -->
<script lang="ts">
	import { user } from '$lib/auth';
	import { recordPolicyConsent } from '$lib/api/consents';
	import { fade } from 'svelte/transition';
	import { createEventDispatcher } from 'svelte';

	// Props를 $props()를 사용하여 정의
	const { showPrivacyPolicy = true, showTermsOfService = true } = $props();

	let privacyPolicyAccepted = $state(false);
	let termsOfServiceAccepted = $state(false);
	let isSubmitting = $state(false);
	let submitError: string | null = $state(null);
	
	const dispatch = createEventDispatcher<{
		complete: { success: boolean; error?: string };
		temporaryClose: { redirectTo: string };
	}>();

	async function handleSubmit() {
		if (!$user) {
			submitError = '로그인이 필요합니다.';
			return;
		}

		if (showPrivacyPolicy && !privacyPolicyAccepted) {
			submitError = '개인정보 처리방침에 동의해주세요.';
			return;
		}

		if (showTermsOfService && !termsOfServiceAccepted) {
			submitError = '서비스 이용약관에 동의해주세요.';
			return;
		}

		isSubmitting = true;
		submitError = null;
		let success = true;

		try {
			// Record privacy policy consent if needed
			if (showPrivacyPolicy) {
				const privacyResult = await recordPolicyConsent(
					$user.id,
					'privacy_policy',
					privacyPolicyAccepted
				);
				
				if (!privacyResult) {
					throw new Error('개인정보 처리방침 동의 저장에 실패했습니다.');
				}
			}

			// Record terms of service consent if needed
			if (showTermsOfService) {
				const termsResult = await recordPolicyConsent(
					$user.id,
					'terms_of_service',
					termsOfServiceAccepted
				);
				
				if (!termsResult) {
					throw new Error('서비스 이용약관 동의 저장에 실패했습니다.');
				}
			}
		} catch (error) {
			console.error('Consent submission error:', error);
			success = false;
			submitError = error instanceof Error ? error.message : '동의 저장 중 오류가 발생했습니다.';
		} finally {
			isSubmitting = false;
			dispatch('complete', { success, error: submitError || undefined });
		}
	}

	// 이용약관이나 개인정보 처리방침 페이지로 이동할 때 모달을 일시적으로 닫는 함수
	function navigateToPage(path: string) {
		console.log('ConsentForm: Opening policy page in new window:', path);
		// 새 창에서 열기
		window.open(path, '_blank');
	}
</script>

<div class="bg-white p-6 rounded-lg shadow-md" transition:fade>
	<h2 class="text-xl font-bold mb-4">서비스 이용을 위한 동의</h2>
	
	{#if submitError}
		<div class="bg-red-50 border border-red-200 text-red-700 p-3 rounded mb-4" role="alert">
			{submitError}
		</div>
	{/if}
	
	<form on:submit|preventDefault={handleSubmit} class="space-y-4">
		{#if showPrivacyPolicy}
			<div class="border border-gray-200 rounded p-4">
				<div class="flex items-start mb-2">
					<div class="flex items-center h-5">
						<input
							id="privacy-policy"
							type="checkbox"
							bind:checked={privacyPolicyAccepted}
							required
							class="w-4 h-4 rounded text-blue-600 border-gray-300 focus:ring-blue-500 focus:ring-offset-0 transition duration-150 ease-in-out cursor-pointer"
						/>
					</div>
					<label for="privacy-policy" class="ml-3 text-sm font-medium text-gray-700 cursor-pointer">
						<span class="font-semibold">개인정보 처리방침</span>에 동의합니다.
					</label>
				</div>
				<div class="text-sm text-gray-500 ml-7">
					<button
						on:click={() => navigateToPage('/privacy-policy')}
						class="text-blue-600 hover:underline"
						type="button"
					>
						개인정보 처리방침 전문 보기
					</button>
				</div>
			</div>
		{/if}
		
		{#if showTermsOfService}
			<div class="border border-gray-200 rounded p-4">
				<div class="flex items-start mb-2">
					<div class="flex items-center h-5">
						<input
							id="terms-of-service"
							type="checkbox"
							bind:checked={termsOfServiceAccepted}
							required
							class="w-4 h-4 rounded text-blue-600 border-gray-300 focus:ring-blue-500 focus:ring-offset-0 transition duration-150 ease-in-out cursor-pointer"
						/>
					</div>
					<label for="terms-of-service" class="ml-3 text-sm font-medium text-gray-700 cursor-pointer">
						<span class="font-semibold">서비스 이용약관</span>에 동의합니다.
					</label>
				</div>
				<div class="text-sm text-gray-500 ml-7">
					<button
						on:click={() => navigateToPage('/terms-of-service')}
						class="text-blue-600 hover:underline"
						type="button"
					>
						서비스 이용약관 전문 보기
					</button>
				</div>
			</div>
		{/if}
		
		<div class="flex justify-end pt-2">
			<button
				type="submit"
				class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 transition duration-150 ease-in-out"
				disabled={isSubmitting || (showPrivacyPolicy && !privacyPolicyAccepted) || (showTermsOfService && !termsOfServiceAccepted)}
			>
				{isSubmitting ? '처리 중...' : '동의 및 계속하기'}
			</button>
		</div>
	</form>
</div> 