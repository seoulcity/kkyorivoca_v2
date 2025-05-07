<!-- src/lib/components/Navigation.svelte -->
<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import { isAdmin } from '$lib/roles';

	// Add props for current active tab
	let { activeTab = 'service' } = $props<{ activeTab?: 'service' | 'myInfo' | 'memberInfo' }>();

	// Create a local state variable that syncs with the prop
	let currentTab = $state<'service' | 'myInfo' | 'memberInfo'>(activeTab);

	// Sync the local state with the prop
	$effect(() => {
		console.log('Navigation: activeTab prop changed to:', activeTab);
		currentTab = activeTab;
	});

	// If user is not admin and tries to access memberInfo, redirect to service
	$effect(() => {
		if (currentTab === 'memberInfo' && !$isAdmin) {
			console.log('Navigation: Non-admin tried to access memberInfo, redirecting to service tab');
			currentTab = 'service';
			dispatch('tabChange', 'service');
		}
	});

	const dispatch = createEventDispatcher<{ tabChange: 'service' | 'myInfo' | 'memberInfo' }>();

	function selectTab(tabName: 'service' | 'myInfo' | 'memberInfo') {
		console.log('Navigation: selectTab called with', tabName);
		
		// If trying to access memberInfo tab but not admin, don't change tab
		if (tabName === 'memberInfo' && !$isAdmin) {
			console.log('Navigation: Access to memberInfo denied - not an admin');
			return;
		}
		
		currentTab = tabName; // Update local state immediately
		dispatch('tabChange', tabName);
	}

	// Use an effect to log when the component updates
	$effect(() => {
		console.log('Navigation: currentTab changed to:', currentTab);
	});
</script>

<nav class="mb-6">
	<div class="flex justify-center space-x-4">
		<button
			on:click={() => selectTab('service')}
			class={`px-4 py-2 font-semibold rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500
			${currentTab === 'service' 
				? 'bg-indigo-500 text-white hover:bg-indigo-600' 
				: 'text-gray-700 hover:bg-gray-200'}`}
		>
			서비스
		</button>
		<button
			on:click={() => selectTab('myInfo')}
			class={`px-4 py-2 font-semibold rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500
			${currentTab === 'myInfo' 
				? 'bg-indigo-500 text-white hover:bg-indigo-600' 
				: 'text-gray-700 hover:bg-gray-200'}`}
		>
			내 정보
		</button>
		
		{#if $isAdmin}
			<button
				on:click={() => selectTab('memberInfo')}
				class={`px-4 py-2 font-semibold rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500
				${currentTab === 'memberInfo' 
					? 'bg-indigo-500 text-white hover:bg-indigo-600' 
					: 'text-gray-700 hover:bg-gray-200'}`}
			>
				회원 정보
			</button>
		{/if}
	</div>
</nav> 