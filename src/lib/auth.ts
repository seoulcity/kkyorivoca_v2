// src/lib/auth.ts
import { writable } from 'svelte/store';
import { supabase } from './supabase';
import type { User } from '@supabase/supabase-js';

export const user = writable<User | null>(null);

// 현재 세션 체크
export async function checkSession() {
  const { data } = await supabase.auth.getSession();
  user.set(data.session?.user || null);
}

// 구글 로그인
export async function signInWithGoogle() {
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: 'https://genpub.vercel.app'
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
  return { success: true };
} 