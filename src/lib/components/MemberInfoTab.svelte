<!-- src/lib/components/MemberInfoTab.svelte -->
<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { user } from '$lib/auth';
	import { isAdmin, formatRole as formatRoleUtil, type UserRole } from '$lib/roles';
	
	// User type for displayed data
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
		role?: UserRole; // Optional role from join
	}
	
	// State for users list and loading status
	let userProfiles = $state<UserProfile[]>([]);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let userRoles = $state<{[key: string]: UserRole}>({});
	let adminModeEnabled = $state(false);
	
	// Fetch users on component mount
	onMount(async () => {
		await fetchUserProfiles();
	});
	
	async function fetchUserProfiles() {
		try {
			loading = true;
			error = null;
			
			console.log('MemberInfoTab: Fetching user profiles...');
			
			// Get all user profiles
			const { data: profilesData, error: profilesError } = await supabase
				.from('user_profiles')
				.select('*')
				.order('created_at', { ascending: false });
			
			if (profilesError) {
				console.error('MemberInfoTab: Error fetching user profiles:', profilesError);
				error = '회원 정보를 불러올 수 없습니다. 관리자에게 문의하세요.';
				userProfiles = [];
				return;
			}
			
			// Get all user roles
			const { data: rolesData, error: rolesError } = await supabase
				.from('user_roles')
				.select('user_id, role')
				.order('role');
			
			if (rolesError) {
				console.warn('MemberInfoTab: Error fetching user roles:', rolesError);
			} else {
				const roleMapping: {[key: string]: UserRole} = {};
				rolesData?.forEach(roleItem => {
					roleMapping[roleItem.user_id] = roleItem.role as UserRole;
				});
				userRoles = roleMapping;
			}
			
			// Combine profiles with roles
			userProfiles = profilesData?.map(profile => ({
				...profile,
				role: userRoles[profile.user_id] || 'member'
			})) || [];
			
			console.log('MemberInfoTab: User profiles fetched successfully:', userProfiles.length);
			
		} catch (err) {
			console.error('MemberInfoTab: Exception while fetching user profiles:', err);
			error = err instanceof Error ? err.message : '알 수 없는 오류가 발생했습니다.';
			userProfiles = [];
		} finally {
			loading = false;
		}
	}
	
	// Update user role
	async function updateUserRole(userId: string, newRole: UserRole) {
		try {
			const { error: updateError } = await supabase
				.from('user_roles')
				.upsert({
					user_id: userId,
					role: newRole,
					updated_by: $user?.id
				}, {
					onConflict: 'user_id'
				});
			
			if (updateError) {
				console.error('MemberInfoTab: Error updating user role:', updateError);
				alert('회원 등급 변경 중 오류가 발생했습니다.');
				return;
			}
			
			// Update local state
			userRoles = {
				...userRoles,
				[userId]: newRole
			};
			
			// Update userProfiles array
			userProfiles = userProfiles.map(profile => 
				profile.user_id === userId 
					? { ...profile, role: newRole } 
					: profile
			);
			
			alert('회원 등급이 변경되었습니다.');
		} catch (err) {
			console.error('MemberInfoTab: Exception updating user role:', err);
			alert('회원 등급 변경 중 오류가 발생했습니다.');
		}
	}
	
	// Format date strings to human-readable format
	function formatDate(dateString: string | null | undefined): string {
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
	<div class="flex justify-between items-center mb-4">
		<h2 class="text-xl font-semibold">회원 정보</h2>
		
		{#if $isAdmin}
			<div class="flex items-center">
				<label class="inline-flex items-center mr-4">
					<input 
						type="checkbox" 
						bind:checked={adminModeEnabled}
						class="form-checkbox h-5 w-5 text-indigo-600"
					>
					<span class="ml-2 text-gray-700">관리 모드</span>
				</label>
			</div>
		{/if}
	</div>
	
	{#if loading}
		<div class="text-center py-4">
			<p class="text-gray-600">회원 정보를 불러오는 중...</p>
		</div>
	{:else if error}
		<div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
			<p>{error}</p>
			<button 
				on:click={fetchUserProfiles}
				class="mt-2 px-3 py-1 bg-red-200 hover:bg-red-300 rounded-md text-sm"
			>
				다시 시도
			</button>
		</div>
	{:else if userProfiles.length === 0}
		<div class="text-center py-4">
			<p class="text-gray-600">회원 정보가 없습니다.</p>
		</div>
	{:else}
		<div class="overflow-x-auto">
			<table class="min-w-full bg-white">
				<thead>
					<tr class="bg-gray-200 text-gray-700">
						<th class="py-2 px-4 text-left">이메일</th>
						<th class="py-2 px-4 text-left">이름</th>
						<th class="py-2 px-4 text-left">가입 방식</th>
						<th class="py-2 px-4 text-left">가입일</th>
						<th class="py-2 px-4 text-left">회원 등급</th>
						{#if adminModeEnabled && $isAdmin}
							<th class="py-2 px-4 text-left">관리</th>
						{/if}
					</tr>
				</thead>
				<tbody>
					{#each userProfiles as profile (profile.id)}
						<tr class="border-t hover:bg-gray-100">
							<td class="py-2 px-4">{profile.email}</td>
							<td class="py-2 px-4">{profile.display_name || '이름 정보 없음'}</td>
							<td class="py-2 px-4">{profile.provider_type || '알 수 없음'}</td>
							<td class="py-2 px-4">{formatDate(profile.created_at)}</td>
							<td class="py-2 px-4">
								{#if adminModeEnabled && $isAdmin}
									<span class="font-medium px-2 py-1 rounded-full text-xs
										{profile.role === 'admin' ? 'bg-purple-100 text-purple-800' : 
										profile.role === 'manager' ? 'bg-blue-100 text-blue-800' : 
										'bg-gray-100 text-gray-800'}">
										{formatRoleUtil(profile.role as UserRole)}
									</span>
								{:else}
									{formatRoleUtil(profile.role as UserRole)}
								{/if}
							</td>
							{#if adminModeEnabled && $isAdmin}
								<td class="py-2 px-4">
									<select 
										class="border rounded px-2 py-1 text-sm"
										value={profile.role || 'member'}
										on:change={(e) => updateUserRole(profile.user_id, e.currentTarget.value as UserRole)}
									>
										<option value="member">일반회원</option>
										<option value="manager">매니저</option>
										<option value="admin">관리자</option>
									</select>
								</td>
							{/if}
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
		
		<div class="mt-4 text-right">
			<span class="text-sm text-gray-600">총 {userProfiles.length}명의 회원</span>
		</div>
	{/if}
</div> 