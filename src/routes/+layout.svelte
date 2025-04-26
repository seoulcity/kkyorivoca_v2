<!-- src/routes/+layout.svelte -->
<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { checkSession } from '$lib/auth';

	let { children } = $props();

	onMount(() => {
		// 페이지 로드 시 세션 체크
		checkSession();
	});
</script>

{@render children()}
