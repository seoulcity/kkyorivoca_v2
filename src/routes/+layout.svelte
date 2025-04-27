<!-- src/routes/+layout.svelte -->
<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { user, userConsentStatus } from '$lib/auth';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import ConsentModal from '$lib/components/ConsentModal.svelte';
	import { hasAcceptedPolicies } from '$lib/api/consents';

	// Show consent modal for new users
	let showConsentModal = false;
	
	// We need to track consent check to prevent redirect loops
	let consentCheckComplete = false;
	let consentCheckInProgress = false; // 중복 체크 방지용

	let { children } = $props();

	onMount(() => {
		console.log('Layout: Component mounted');
		// Set up auth state listener
		const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
			console.log('Layout: Auth state changed:', event, 'User:', session?.user?.id);
			user.set(session?.user ?? null);
			
			// Check for policy acceptance when user logs in
			if (session?.user) {
				console.log('Layout: User is logged in, checking consent');
				// 콘센트 상태를 초기화하고 체크 시작
				userConsentStatus.set(null);
				consentCheckComplete = false;
				checkConsent(session.user.id);
			} else {
				console.log('Layout: No user session');
				userConsentStatus.set(null);
				consentCheckComplete = true;
			}
		});

		// Get initial auth state
		supabase.auth.getSession().then(({ data: { session } }) => {
			console.log('Layout: Initial auth session', 'User:', session?.user?.id);
			user.set(session?.user ?? null);
			
			// Check for policy acceptance for initial session
			if (session?.user) {
				console.log('Layout: Initial user is logged in, checking consent');
				// 콘센트 상태를 초기화하고 체크 시작
				userConsentStatus.set(null);
				consentCheckComplete = false;
				checkConsent(session.user.id);
			} else {
				console.log('Layout: No user session');
				userConsentStatus.set(null);
				consentCheckComplete = true;
			}
		});

		return () => subscription.unsubscribe();
	});
	
	// Check consent and show modal if needed
	async function checkConsent(userId: string) {
		// 이미 체크 중이면 중복 실행 방지
		if (consentCheckInProgress) {
			console.log('Layout: Consent check already in progress, skipping');
			return;
		}

		console.log('Layout: Checking consent for user:', userId);
		consentCheckInProgress = true;
		consentCheckComplete = false;
		
		try {
			const accepted = await hasAcceptedPolicies(userId);
			console.log('Layout: User has accepted policies:', accepted, 'user ID:', userId);
			
			// 콘센트 상태를 스토어에 저장
			userConsentStatus.set(accepted);
			showConsentModal = !accepted;
			
			if (!accepted) {
				console.log('Layout: User needs to accept policies, showing modal');
			} else {
				console.log('Layout: User has already accepted policies');
			}
			
			consentCheckComplete = true;
		} catch (error) {
			console.error('Error checking policy consent:', error);
			// 오류 발생 시 보수적으로 접근하여 콘센트가 필요하다고 설정
			userConsentStatus.set(false);
			showConsentModal = true;
			consentCheckComplete = true;
		} finally {
			consentCheckInProgress = false;
		}
	}
	
	// Handle consent modal close
	function handleConsentClose(event: CustomEvent<{ success: boolean }>) {
		console.log('Layout: Consent modal closed with success:', event.detail.success);
		showConsentModal = false;
		
		// 동의 결과를 상태에 반영
		userConsentStatus.set(event.detail.success);
		
		// If user accepted policies, continue
		// If not, force logout
		if (!event.detail.success && $user) {
			console.log('Layout: User did not accept policies, logging out');
			supabase.auth.signOut().then(() => {
				goto('/');
			});
		}
	}
	
	// 로그인 상태 및 동의 상태, 페이지 경로에 따라 적절한 리다이렉션 처리
	$effect(() => {
		// 체크가 완료되었을 때만 실행
		if (consentCheckComplete) {
			console.log('Layout: Consent check complete, user:', $user ? 'logged in' : 'not logged in', 
				'consent status:', $userConsentStatus === null ? 'unknown' : ($userConsentStatus ? 'accepted' : 'not accepted'), 
				'path:', $page.url.pathname);
			
			// 로그인 안 됨 + 보호된 페이지 접근 시도 -> 홈 페이지로
			if (!$user && !$page.url.pathname.startsWith('/privacy-policy') && !$page.url.pathname.startsWith('/terms-of-service') && $page.url.pathname !== '/') {
				console.log('Layout: Redirecting unauthenticated user to home page');
				goto('/');
			}
			
			// 로그인 + 동의 안 됨 + 메인 페이지 접근 -> 동의 모달 표시(자동으로 표시됨)
			if ($user && $userConsentStatus === false && $page.url.pathname === '/main') {
				console.log('Layout: Logged in user without consent is trying to access main page, showing consent modal');
				showConsentModal = true;
			}
		}
	});
</script>

<ConsentModal show={showConsentModal} on:close={handleConsentClose} />

{@render children()}
