<!-- src/lib/components/MyInfoTab.svelte -->
<script lang="ts">
	import { onMount } from 'svelte';
	import { user } from '$lib/auth';
	import { supabase } from '$lib/supabase';
	
	interface UserProfile {
		id: string;
		user_id: string;
		email: string;
		phone: string | null;
		display_name: string | null;
		providers: string[];
		provider_type: string | null;
		created_at: string;
		updated_at: string;
	}
	
	let profile = $state<UserProfile | null>(null);
	let loading = $state(true);
	let error = $state<string | null>(null);
	
	// Fetch user profile on component mount
	onMount(async () => {
		if ($user) {
			await fetchUserProfile($user.id);
		}
	});
	
	// Watch for user changes
	$effect(() => {
		if ($user) {
			fetchUserProfile($user.id);
		}
	});
	
	async function fetchUserProfile(userId: string) {
		try {
			loading = true;
			error = null;
			
			const { data, error: fetchError } = await supabase
				.from('user_profiles')
				.select('*')
				.eq('user_id', userId)
				.single();
			
			if (fetchError) {
				console.error('Error fetching user profile:', fetchError);
				error = '사용자 정보를 불러올 수 없습니다.';
				profile = null;
			} else {
				profile = data;
			}
		} catch (err) {
			console.error('Exception while fetching user profile:', err);
			error = err instanceof Error ? err.message : '알 수 없는 오류가 발생했습니다.';
			profile = null;
		} finally {
			loading = false;
		}
	}
	
	// Format date for display
	function formatDate(dateString: string | null): string {
		if (!dateString) return '없음';
		
		try {
			const date = new Date(dateString);
			return date.toLocaleString('ko-KR', {
				year: 'numeric',
				month: '2-digit',
				day: '2-digit',
				hour: '2-digit',
				minute: '2-digit'
			});
		} catch (err) {
			return dateString;
		}
	}
</script>

<div class="p-4 border rounded-md bg-gray-50">
	<h2 class="text-xl font-semibold mb-4">내 정보</h2>
	
	{#if loading}
		<div class="text-center py-4">
			<p class="text-gray-600">정보를 불러오는 중...</p>
		</div>
	{:else if error}
		<div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
			<p>{error}</p>
			<button 
				on:click={() => $user && fetchUserProfile($user.id)}
				class="mt-2 px-3 py-1 bg-red-200 hover:bg-red-300 rounded-md text-sm"
			>
				다시 시도
			</button>
		</div>
	{:else if profile}
		<div class="space-y-4">
			<div class="bg-white p-4 rounded-md shadow-sm">
				<div class="grid grid-cols-3 gap-3">
					<div class="text-gray-500">이메일</div>
					<div class="col-span-2 font-medium">{profile.email || '없음'}</div>
					
					<div class="text-gray-500">이름</div>
					<div class="col-span-2 font-medium">{profile.display_name || '이름 정보 없음'}</div>
					
					<div class="text-gray-500">전화번호</div>
					<div class="col-span-2 font-medium">{profile.phone || '없음'}</div>
					
					<div class="text-gray-500">가입 방식</div>
					<div class="col-span-2 font-medium">{profile.provider_type || '알 수 없음'}</div>
					
					<div class="text-gray-500">가입일</div>
					<div class="col-span-2 font-medium">{formatDate(profile.created_at)}</div>
				</div>
			</div>
		</div>
	{:else}
		<div class="text-center py-4">
			<p class="text-gray-600">사용자 정보가 없습니다.</p>
		</div>
	{/if}
</div> 