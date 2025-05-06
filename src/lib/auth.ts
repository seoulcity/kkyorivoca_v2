// src/lib/auth.ts
import { writable } from 'svelte/store';
import { supabase } from './supabase';
import type { User } from '@supabase/supabase-js';
import { SITE_URL } from './config';

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
      redirectTo: SITE_URL,
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
  try {
    // 명시적으로 scope: 'global' 옵션을 추가하여 모든 장치에서 로그아웃
    const { error } = await supabase.auth.signOut({ scope: 'global' });
    
    if (error) {
      // AuthSessionMissingError의 경우, 로그아웃은 실패했지만 로컬 상태는 초기화
      if (error.message && error.message.includes('Auth session missing')) {
        console.log('No active session found on server, but clearing local state anyway');
      } else {
        console.error('Error signing out:', error);
        return { error };
      }
    }
  } catch (e) {
    // 예외 발생 시에도 로컬 상태 초기화 계속 진행
    console.error('Exception during sign out:', e);
  }
  
  // 에러가 발생하더라도 항상 로컬 상태를 초기화
  console.log('Clearing all local auth state');
  
  // 명시적으로 모든 상태 초기화
  user.set(null);
  userConsentStatus.set(null);
  
  // 로컬 스토리지 정리를 위한 추가 조치
  try {
    localStorage.removeItem('supabase.auth.token');
    localStorage.removeItem('sb-ratynnxfnxvaejekupga-auth-token');
    sessionStorage.removeItem('supabase.auth.token');
    sessionStorage.removeItem('sb-ratynnxfnxvaejekupga-auth-token');
    
    // 모든 supabase 관련 항목 삭제
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && (key.startsWith('supabase.') || key.startsWith('sb-'))) {
        localStorage.removeItem(key);
      }
    }
    
    for (let i = 0; i < sessionStorage.length; i++) {
      const key = sessionStorage.key(i);
      if (key && (key.startsWith('supabase.') || key.startsWith('sb-'))) {
        sessionStorage.removeItem(key);
      }
    }
  } catch (storageError) {
    console.error('Error clearing storage:', storageError);
  }
  
  console.log('Signed out successfully');
  return { success: true };
} 