// src/lib/auth.ts
import { writable } from 'svelte/store';
import { supabase } from './supabase';
import type { User } from '@supabase/supabase-js';

export const user = writable<User | null>(null);
// 사용자의 이용약관 및 개인정보처리방침 동의 상태를 저장하는 스토어
export const userConsentStatus = writable<boolean | null>(null);

// Load the user from session on page load
export async function checkSession() {
  const { data } = await supabase.auth.getSession();
  user.set(data.session?.user ?? null);
}

// 구글 로그인
export async function signInWithGoogle() {
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: 'https://genpub.vercel.app',
      queryParams: {
        access_type: 'offline',
        prompt: 'consent',
      }
    }
  });
  
  if (error) {
    console.error('Error logging in with Google:', error);
    return { error };
  }
  
  return { success: true };
}

// 로그아웃
export async function signOut() {
  const { error } = await supabase.auth.signOut();
  
  if (error) {
    console.error('Error signing out:', error);
    return { error };
  }
  
  user.set(null);
  userConsentStatus.set(null);
  return { success: true };
} 