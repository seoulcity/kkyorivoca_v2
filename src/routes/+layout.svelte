<!-- src/routes/+layout.svelte -->
<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { user } from '$lib/auth';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import ConsentModal from '$lib/components/ConsentModal.svelte';
	import { hasAcceptedPolicies } from '$lib/api/consents';

	// Show consent modal for new users
	let showConsentModal = false;
	
	// We need to track consent check to prevent redirect loops
	let consentCheckComplete = false;

	let { children } = $props();

	onMount(() => {
		// Set up auth state listener
		const { data: { subscription } } = supabase.auth.onAuthStateChange((_, session) => {
			user.set(session?.user ?? null);
			
			// Check for policy acceptance when user logs in
			if (session?.user) {
				checkConsent(session.user.id);
			} else {
				consentCheckComplete = true;
			}
		});

		// Get initial auth state
		supabase.auth.getSession().then(({ data: { session } }) => {
			user.set(session?.user ?? null);
			
			// Check for policy acceptance for initial session
			if (session?.user) {
				checkConsent(session.user.id);
			} else {
				consentCheckComplete = true;
			}
		});

		return () => subscription.unsubscribe();
	});
	
	// Check consent and show modal if needed
	async function checkConsent(userId: string) {
		try {
			const accepted = await hasAcceptedPolicies(userId);
			showConsentModal = !accepted;
			consentCheckComplete = true;
		} catch (error) {
			console.error('Error checking policy consent:', error);
			consentCheckComplete = true;
		}
	}
	
	// Handle consent modal close
	function handleConsentClose(event: CustomEvent<{ success: boolean }>) {
		showConsentModal = false;
		
		// If user accepted policies, continue
		// If not, force logout
		if (!event.detail.success && $user) {
			supabase.auth.signOut().then(() => {
				goto('/');
			});
		}
	}
	
	// Redirect to login if user is not authenticated and attempts to access protected pages
	$effect(() => {
		if (consentCheckComplete && !$user && !$page.url.pathname.startsWith('/privacy-policy') && !$page.url.pathname.startsWith('/terms-of-service') && $page.url.pathname !== '/') {
			goto('/');
		}
	});
</script>

<ConsentModal show={showConsentModal} on:close={handleConsentClose} />

{@render children()}
