<!-- src/lib/components/Footer.svelte -->
<script>
	// Import the SERVICE_TITLE variable
	import { SERVICE_TITLE } from '$lib/config';
	
	// 동적 연도 표시를 위한 변수
	const currentYear = new Date().getFullYear();
</script>

<footer class="mt-8 py-4 text-center text-xs text-gray-500">
	<div class="flex justify-center space-x-4">
		<a href="/terms-of-service" target="_blank" rel="noopener noreferrer" class="hover:underline">이용약관</a>
		<span>|</span>
		<a href="/privacy-policy" target="_blank" rel="noopener noreferrer" class="hover:underline">개인정보 처리방침</a>
	</div>
	<div class="mt-2">
		© {currentYear} {SERVICE_TITLE}. All rights reserved.
	</div>
</footer> 