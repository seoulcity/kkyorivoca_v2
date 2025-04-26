<script lang="ts">
	import { user, signOut } from '$lib/auth';
	import { goto } from '$app/navigation';
	
	// 로그인 상태 확인, 로그인되지 않았으면 랜딩 페이지로 리다이렉트
	$effect(() => {
		if (!$user) {
			goto('/');
		}
	});
	
	// 로그아웃 처리
	async function handleSignOut() {
		await signOut();
		goto('/');
	}
</script>

<div class="flex flex-col items-center justify-center min-h-screen bg-gray-100">
	<div class="p-8 bg-white rounded-lg shadow-md w-full max-w-md">
		<h1 class="text-3xl font-bold text-center mb-6">GenPub</h1>
		
		{#if $user}
			<div class="mb-6">
				<p class="text-center text-gray-700">
					안녕하세요, {$user.email || '사용자'}님!
				</p>
			</div>
		{/if}
		
		<button
			on:click={handleSignOut}
			class="w-full py-2 px-4 bg-red-600 text-white rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
		>
			로그아웃
		</button>
	</div>
</div> 