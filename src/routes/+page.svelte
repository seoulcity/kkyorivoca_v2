<!-- src/routes/+page.svelte -->
<script lang="ts">
	import { signInWithGoogle, user, userConsentStatus } from '$lib/auth';
	import { goto } from '$app/navigation';
	import Footer from '$lib/components/Footer.svelte';
	
	// 로그인 상태 및 동의 상태에 따라 메인 페이지로 리다이렉트
	$effect(() => {
		// 로그인했고 콘센트 체크가 완료된 상태일 때만 메인 페이지로 이동
		if ($user && $userConsentStatus !== null) {
			console.log('Home: User is logged in, consent status:', $userConsentStatus ? 'accepted' : 'not accepted');
			if ($userConsentStatus === true) {
				console.log('Home: User has accepted policies, redirecting to main page');
				goto('/main');
			} else {
				// 동의 페이지에서 동의 완료하면 userConsentStatus가 true로 변경되고
				// 위의 조건에 따라 메인 페이지로 자동 이동함
				console.log('Home: User has not accepted policies, waiting for consent');
			}
		}
	});
</script>

<div class="flex flex-col items-center justify-center min-h-screen bg-gray-100">
	<div class="p-8 bg-white rounded-lg shadow-md w-full max-w-md">
		<h1 class="text-3xl font-bold text-center mb-6">GenPub</h1>
		<p class="text-center mb-8 text-gray-600">로그인하여 시작하세요</p>
		
		<button
			onclick={signInWithGoogle}
			class="flex items-center justify-center w-full py-2 px-4 bg-white border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-800 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
		>
			<svg class="h-5 w-5 mr-2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
				<path
					fill="#4285F4"
					d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
				/>
				<path
					fill="#34A853"
					d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
				/>
				<path
					fill="#FBBC05"
					d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
				/>
				<path
					fill="#EA4335"
					d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
				/>
			</svg>
			Google 계정으로 로그인
		</button>
		
		<div class="mt-6 text-center text-sm text-gray-500">
			로그인하면 
			<a href="/terms-of-service" class="text-blue-600 hover:underline">서비스 이용약관</a> 및 
			<a href="/privacy-policy" class="text-blue-600 hover:underline">개인정보 처리방침</a>에 
			동의하는 것으로 간주됩니다.
		</div>
	</div>
	
	<Footer />
</div>
